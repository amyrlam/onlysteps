-- Calls the weekly-winner Edge Function at five past every hour. The function
-- decides per group whether its local post time has arrived.
--
-- Before this works on a hosted project, store two Vault secrets
-- (Dashboard > Project Settings > Vault, or SQL):
--   select vault.create_secret('https://<project-ref>.supabase.co', 'project_url');
--   select vault.create_secret('<random string>', 'cron_secret');
-- and set the same CRON_SECRET for the function:
--   supabase secrets set CRON_SECRET=<random string>

create extension if not exists pg_cron with schema pg_catalog;
create extension if not exists pg_net with schema extensions;

select cron.schedule(
  'weekly-winner-hourly',
  '5 * * * *',
  $$
  select net.http_post(
    url := (select decrypted_secret from vault.decrypted_secrets where name = 'project_url') || '/functions/v1/weekly-winner',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'x-cron-secret', (select decrypted_secret from vault.decrypted_secrets where name = 'cron_secret')
    ),
    body := '{}'::jsonb
  );
  $$
);
