-- Signup names that fit the profile check, owners can't orphan a group, and
-- removed members can't rejoin with an old invite code.

-- ---------------------------------------------------------------------------
-- Signup display name: trimmed to the 40-character limit, never empty
-- ---------------------------------------------------------------------------
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, display_name)
  values (
    new.id,
    left(coalesce(
      nullif(btrim(new.raw_user_meta_data ->> 'full_name'), ''),
      nullif(btrim(new.raw_user_meta_data ->> 'name'), ''),
      nullif(split_part(coalesce(new.email, ''), '@', 1), ''),
      'Walker'
    ), 40)
  );
  return new;
end;
$$;

-- ---------------------------------------------------------------------------
-- Owners remove others but can't leave; they delete the group instead.
-- Deleting a group still clears its members (cascades skip RLS).
-- ---------------------------------------------------------------------------
drop policy "Members leave, owners remove" on public.group_members;
create policy "Members leave, owners remove"
  on public.group_members for delete
  using (
    (user_id = auth.uid() and role <> 'owner')
    or (user_id <> auth.uid() and public.is_group_owner(group_id))
  );

-- ---------------------------------------------------------------------------
-- Removed members: recorded when an owner removes someone, checked on join.
-- An owner deletes the row to let them back in.
-- ---------------------------------------------------------------------------
create table public.group_removals (
  group_id uuid not null references public.groups (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  removed_at timestamptz not null default now(),
  primary key (group_id, user_id)
);

alter table public.group_removals enable row level security;

create policy "Owners see removals"
  on public.group_removals for select
  using (public.is_group_owner(group_id));
create policy "Owners lift removals"
  on public.group_removals for delete
  using (public.is_group_owner(group_id));

create function public.handle_member_removed()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  -- Someone else deleted the row (an owner), and not as part of deleting the
  -- whole group. Leaving on your own isn't a removal.
  if auth.uid() is not null
     and auth.uid() <> old.user_id
     and exists (select 1 from public.groups where id = old.group_id) then
    insert into public.group_removals (group_id, user_id)
    values (old.group_id, old.user_id)
    on conflict do nothing;
  end if;
  return old;
end;
$$;

create trigger on_group_member_removed
  after delete on public.group_members
  for each row execute function public.handle_member_removed();

create or replace function public.join_group(code text)
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
  if exists (select 1 from public.group_removals where group_id = gid and user_id = auth.uid()) then
    raise exception 'You were removed from this group. Ask the owner to add you back.';
  end if;
  insert into public.group_members (group_id, user_id)
  values (gid, auth.uid())
  on conflict do nothing;
  return gid;
end;
$$;
