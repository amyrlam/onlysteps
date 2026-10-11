// Posts each group's weekly winner to Slack. Runs hourly from pg_cron (see
// migrations/*_schedule_weekly_winner.sql) and posts for every group whose
// configured local weekday and hour have passed and whose last week has not
// been announced yet.
import { createClient } from "npm:@supabase/supabase-js@2";
import { dueWeek, winnerMessage, type LeaderboardRow } from "../_shared/weekly.ts";

const APP_NAME = Deno.env.get("APP_NAME") ?? "OnlySteps";
const WEB_URL = Deno.env.get("WEB_URL") ?? "";
const CRON_SECRET = Deno.env.get("CRON_SECRET");

Deno.serve(async (req) => {
  if (!CRON_SECRET || req.headers.get("x-cron-secret") !== CRON_SECRET) {
    return new Response("Unauthorized", { status: 401 });
  }

  const supabase = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!, {
    auth: { persistSession: false },
  });

  const { data: groups, error } = await supabase
    .from("group_slack_settings")
    .select("group_id, webhook_url, post_weekday, post_hour, last_posted_week, groups(name, time_zone)")
    .eq("enabled", true);
  if (error) return Response.json({ error: error.message }, { status: 500 });

  const now = new Date();
  const results: Record<string, string> = {};

  for (const g of groups ?? []) {
    const group = g.groups as unknown as { name: string; time_zone: string };
    const week = dueWeek(g, now, group.time_zone);
    if (!week) continue;

    const { data: rows, error: lbError } = await supabase.rpc("group_leaderboard", { gid: g.group_id, week });
    if (lbError) {
      results[g.group_id] = `leaderboard error: ${lbError.message}`;
      continue;
    }

    const payload = winnerMessage({
      appName: APP_NAME,
      groupName: group.name,
      weekStart: week,
      rows: (rows ?? []) as LeaderboardRow[],
      groupUrl: WEB_URL ? `${WEB_URL}/groups/${g.group_id}` : undefined,
    });
    const res = await fetch(g.webhook_url, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
    });
    if (!res.ok) {
      results[g.group_id] = `slack error ${res.status}`;
      continue;
    }
    await supabase.from("group_slack_settings").update({ last_posted_week: week }).eq("group_id", g.group_id);
    results[g.group_id] = `posted ${week}`;
  }

  return Response.json({ checked: groups?.length ?? 0, results });
});
