-- A person's Slack member ID (for example U0123ABCD), so the weekly winner
-- post can tag them. Optional, and visible to group mates like the rest of a
-- profile.
alter table public.profiles
  add column slack_user_id text
  check (slack_user_id is null or slack_user_id ~ '^[UW][A-Z0-9]{6,20}$');

-- The leaderboard returns it, so the scheduled post and the test post can
-- both tag people. Adding a result column means replacing the function.
drop function public.group_leaderboard(uuid, date);

create function public.group_leaderboard(gid uuid, week date default null)
returns table (
  user_id uuid,
  display_name text,
  avatar_url text,
  total_steps bigint,
  rank bigint,
  slack_user_id text
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
         rank() over (order by t.total_steps desc),
         p.slack_user_id
  from totals t
  join public.profiles p on p.id = t.user_id
  order by t.total_steps desc, p.display_name;
$$;

grant execute on function public.group_leaderboard(uuid, date) to authenticated;
