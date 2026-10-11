-- Requests to rejoin: someone an owner removed can ask to be let back in from
-- the invite link. Owners approve (adds them back) or dismiss (final until an
-- owner lifts the removal). A request lives on the group_removals row.

alter table public.group_removals
  add column requested_at timestamptz,
  add column dismissed_at timestamptz,
  -- Set by the notify-rejoin-request Edge Function once Slack has been told,
  -- so each request posts at most once.
  add column notified_at timestamptz;

create index group_removals_pending_idx on public.group_removals (group_id)
  where requested_at is not null and dismissed_at is null;

-- Removed users see their own row (to know whether a request is pending);
-- owners already see their group's rows. Writes go through the functions below.
create policy "Removed users see their own removal"
  on public.group_removals for select
  using (user_id = auth.uid());

-- ---------------------------------------------------------------------------
-- Requester: ask to rejoin by invite code. Returns the group id. Asking again
-- while a request is pending is a no-op.
-- ---------------------------------------------------------------------------
create function public.request_rejoin(code text)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  gid uuid;
  removal public.group_removals;
begin
  if auth.uid() is null then
    raise exception 'Not signed in';
  end if;
  select id into gid from public.groups where invite_code = lower(trim(code));
  if gid is null then
    raise exception 'Invite code not found';
  end if;
  select * into removal from public.group_removals
  where group_id = gid and user_id = auth.uid()
  for update;
  if not found then
    raise exception 'You weren''t removed from this group, so you can join it directly.';
  end if;
  if removal.dismissed_at is not null then
    raise exception 'The owner dismissed your request to rejoin.';
  end if;
  if removal.requested_at is null then
    update public.group_removals set requested_at = now()
    where group_id = gid and user_id = auth.uid();
  end if;
  return gid;
end;
$$;

-- ---------------------------------------------------------------------------
-- Owner: removed members of a group, pending requests first. Profiles of
-- removed people are no longer visible through "shares a group", so this
-- returns their name and avatar for the owner.
-- ---------------------------------------------------------------------------
create function public.group_removed_members(gid uuid)
returns table (
  user_id uuid,
  display_name text,
  avatar_url text,
  removed_at timestamptz,
  requested_at timestamptz,
  dismissed_at timestamptz
)
language sql
stable
security definer
set search_path = ''
as $$
  select r.user_id, p.display_name, p.avatar_url, r.removed_at, r.requested_at, r.dismissed_at
  from public.group_removals r
  join public.profiles p on p.id = r.user_id
  where r.group_id = gid and public.is_group_owner(gid)
  order by (r.requested_at is not null and r.dismissed_at is null) desc,
           coalesce(r.requested_at, r.removed_at) desc;
$$;

-- Owner: approve a pending request. Lifts the removal and adds them back.
create function public.approve_rejoin(gid uuid, uid uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not public.is_group_owner(gid) then
    raise exception 'Only the group owner can approve requests';
  end if;
  delete from public.group_removals
  where group_id = gid and user_id = uid
    and requested_at is not null and dismissed_at is null;
  if not found then
    raise exception 'No pending request to approve';
  end if;
  insert into public.group_members (group_id, user_id)
  values (gid, uid)
  on conflict do nothing;
end;
$$;

-- Owner: dismiss a pending request. They stay removed and can't ask again;
-- the owner can still lift the removal later (delete the row).
create function public.dismiss_rejoin(gid uuid, uid uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not public.is_group_owner(gid) then
    raise exception 'Only the group owner can dismiss requests';
  end if;
  update public.group_removals set dismissed_at = now()
  where group_id = gid and user_id = uid
    and requested_at is not null and dismissed_at is null;
  if not found then
    raise exception 'No pending request to dismiss';
  end if;
end;
$$;

revoke execute on function public.request_rejoin(text) from public, anon;
revoke execute on function public.group_removed_members(uuid) from public, anon;
revoke execute on function public.approve_rejoin(uuid, uuid) from public, anon;
revoke execute on function public.dismiss_rejoin(uuid, uuid) from public, anon;
grant execute on function public.request_rejoin(text) to authenticated;
grant execute on function public.group_removed_members(uuid) to authenticated;
grant execute on function public.approve_rejoin(uuid, uuid) to authenticated;
grant execute on function public.dismiss_rejoin(uuid, uuid) to authenticated;
