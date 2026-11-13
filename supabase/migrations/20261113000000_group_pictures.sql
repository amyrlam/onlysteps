-- Group pictures live in a public Storage bucket at <group id>.png, so
-- groups need no extra column. Nothing may upload yet except the service
-- role; add Storage policies when owners can change the picture themselves.
insert into storage.buckets (id, name, public)
values ('group-pictures', 'group-pictures', true)
on conflict (id) do nothing;
