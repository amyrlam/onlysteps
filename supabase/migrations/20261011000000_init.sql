-- OnlySteps initial schema: profiles, groups, invites, daily step totals,
-- and per-group Slack settings for the weekly winner post.

create extension if not exists pgcrypto;

-- ---------------------------------------------------------------------------
-- Profiles (one per auth user)
-- ---------------------------------------------------------------------------
create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  display_name text not null default 'Walker' check (char_length(display_name) between 1 and 40),
  avatar_url text,
  time_zone text not null default 'UTC',
  created_at timestamptz not null default now()
);

create function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, display_name)
  values (
    new.id,
    coalesce(
      nullif(new.raw_user_meta_data ->> 'full_name', ''),
      nullif(new.raw_user_meta_data ->> 'name', ''),
      split_part(coalesce(new.email, ''), '@', 1),
      'Walker'
    )
  );
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ---------------------------------------------------------------------------
-- Groups and membership
-- ---------------------------------------------------------------------------
create table public.groups (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(name) between 1 and 60),
  -- Short code used in invite links: /join/<invite_code>
  invite_code text not null unique default lower(substr(replace(gen_random_uuid()::text, '-', ''), 1, 10)),
  -- Weeks run Monday to Sunday in this time zone.
  time_zone text not null default 'America/New_York',
  created_by uuid not null default auth.uid() references auth.users (id) on delete cascade,
  created_at timestamptz not null default now()
);

create type public.group_role as enum ('owner', 'member');

create table public.group_members (
  group_id uuid not null references public.groups (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  role public.group_role not null default 'member',
  joined_at timestamptz not null default now(),
  primary key (group_id, user_id)
);

create index group_members_user_idx on public.group_members (user_id);

-- Helpers used by RLS policies. security definer avoids recursive policy checks.
create function public.is_group_member(gid uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.group_members
    where group_id = gid and user_id = auth.uid()
  );
$$;

create function public.is_group_owner(gid uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.group_members
    where group_id = gid and user_id = auth.uid() and role = 'owner'
  );
$$;

create function public.shares_group_with(other uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.group_members a
    join public.group_members b on a.group_id = b.group_id
    where a.user_id = auth.uid() and b.user_id = other
  );
$$;

-- The creator becomes the owner automatically.
create function public.handle_new_group()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.group_members (group_id, user_id, role)
  values (new.id, new.created_by, 'owner');
  return new;
end;
$$;

create trigger on_group_created
  after insert on public.groups
  for each row execute function public.handle_new_group();

-- Join a group by invite code. Returns the group id.
create function public.join_group(code text)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  gid uuid;
begin
  if auth.uid() is null then
    raise exception 'Not signed in';
  end if;
  select id into gid from public.groups where invite_code = lower(trim(code));
  if gid is null then
    raise exception 'Invite code not found';
  end if;
  insert into public.group_members (group_id, user_id)
  values (gid, auth.uid())
  on conflict do nothing;
  return gid;
end;
$$;

-- Preview a group from an invite link before joining.
create function public.group_for_invite(code text)
returns table (id uuid, name text, member_count bigint)
language sql
stable
security definer
set search_path = ''
as $$
  select g.id, g.name, (select count(*) from public.group_members m where m.group_id = g.id)
  from public.groups g
  where g.invite_code = lower(trim(code));
$$;

-- ---------------------------------------------------------------------------
-- Daily step totals, written by the iOS app from Apple Health
-- ---------------------------------------------------------------------------
create table public.daily_steps (
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  -- Calendar day in the user's own time zone, as reported by the phone.
  day date not null,
  steps integer not null check (steps between 0 and 200000),
  source text not null default 'healthkit',
  updated_at timestamptz not null default now(),
  primary key (user_id, day)
);

-- ---------------------------------------------------------------------------
-- Slack settings (owners only; the webhook URL is a secret)
-- ---------------------------------------------------------------------------
create table public.group_slack_settings (
  group_id uuid primary key references public.groups (id) on delete cascade,
  webhook_url text not null check (webhook_url like 'https://hooks.slack.com/%'),
  enabled boolean not null default true,
  -- ISO weekday, 1 = Monday ... 7 = Sunday, in the group's time zone.
  post_weekday smallint not null default 1 check (post_weekday between 1 and 7),
  post_hour smallint not null default 9 check (post_hour between 0 and 23),
  -- Monday of the most recent week already announced, to avoid double posts.
  last_posted_week date,
  updated_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- Leaderboard
-- ---------------------------------------------------------------------------
-- Monday of the week containing `at`, in time zone `tz`.
create function public.week_start(tz text, at timestamptz default now())
returns date
language sql
stable
as $$
  select (date_trunc('week', at at time zone tz))::date;
$$;

-- Step totals for every member of a group for the week starting `week`
-- (a Monday). Defaults to the current week in the group's time zone.
create function public.group_leaderboard(gid uuid, week date default null)
returns table (
  user_id uuid,
  display_name text,
  avatar_url text,
  total_steps bigint,
  rank bigint
)
language sql
stable
security invoker
set search_path = ''
as $$
  with g as (
    select coalesce(week, public.week_start(time_zone)) as ws
    from public.groups where id = gid
  ),
  totals as (
    select m.user_id, coalesce(sum(s.steps), 0)::bigint as total_steps
    from public.group_members m
    cross join g
    left join public.daily_steps s
      on s.user_id = m.user_id and s.day >= g.ws and s.day < g.ws + 7
    where m.group_id = gid
    group by m.user_id
  )
  select t.user_id, p.display_name, p.avatar_url, t.total_steps,
         rank() over (order by t.total_steps desc)
  from totals t
  join public.profiles p on p.id = t.user_id
  order by t.total_steps desc, p.display_name;
$$;

-- ---------------------------------------------------------------------------
-- Row level security
-- ---------------------------------------------------------------------------
alter table public.profiles enable row level security;
alter table public.groups enable row level security;
alter table public.group_members enable row level security;
alter table public.daily_steps enable row level security;
alter table public.group_slack_settings enable row level security;

create policy "Profiles are visible to self and group mates"
  on public.profiles for select
  using (id = auth.uid() or public.shares_group_with(id));
create policy "Users update their own profile"
  on public.profiles for update
  using (id = auth.uid()) with check (id = auth.uid());

-- created_by lets the creator read the row back from the insert, before the
-- owner membership trigger has run.
create policy "Members see their groups"
  on public.groups for select
  using (public.is_group_member(id) or created_by = auth.uid());
create policy "Signed-in users create groups"
  on public.groups for insert
  with check (auth.uid() is not null and created_by = auth.uid());
create policy "Owners update groups"
  on public.groups for update
  using (public.is_group_owner(id));
create policy "Owners delete groups"
  on public.groups for delete
  using (public.is_group_owner(id));

create policy "Members see fellow members"
  on public.group_members for select
  using (public.is_group_member(group_id));
create policy "Members leave, owners remove"
  on public.group_members for delete
  using (user_id = auth.uid() or public.is_group_owner(group_id));

create policy "Steps are visible to self and group mates"
  on public.daily_steps for select
  using (user_id = auth.uid() or public.shares_group_with(user_id));
create policy "Users write their own steps"
  on public.daily_steps for insert
  with check (user_id = auth.uid());
create policy "Users update their own steps"
  on public.daily_steps for update
  using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy "Owners manage Slack settings"
  on public.group_slack_settings for all
  using (public.is_group_owner(group_id))
  with check (public.is_group_owner(group_id));

grant execute on function public.join_group(text) to authenticated;
grant execute on function public.group_for_invite(text) to anon, authenticated;
grant execute on function public.group_leaderboard(uuid, date) to authenticated;
