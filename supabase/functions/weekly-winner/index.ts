// Posts each group's weekly winner to Slack. Runs hourly from pg_cron (see
// migrations/*_schedule_weekly_winner.sql) and posts for every group whose
// configured local weekday and hour have passed and whose last week has not
// been announced yet.
import { createClient, type SupabaseClient } from "npm:@supabase/supabase-js@2";
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
    try {
      results[g.group_id] = await postIfDue(supabase, g, now);
    } catch (e) {
      // One group's bad data must not stop the others.
      results[g.group_id] = `error: ${e instanceof Error ? e.message : String(e)}`;
    }
  }

  return Response.json({ checked: groups?.length ?? 0, results });
});

type SlackRow = {
  group_id: string;
  webhook_url: string;
  post_weekday: number;
  post_hour: number;
  last_posted_week: string | null;
  groups: unknown;
};

async function postIfDue(supabase: SupabaseClient, g: SlackRow, now: Date): Promise<string> {
  const group = g.groups as { name: string; time_zone: string };
  const week = dueWeek(g, now, group.time_zone);
  if (!week) return "not due";

  const { data: rows, error: lbError } = await supabase.rpc("group_leaderboard", { gid: g.group_id, week });
  if (lbError) return `leaderboard error: ${lbError.message}`;

  const payload = winnerMessage({
    appName: APP_NAME,
    groupName: group.name,
    weekStart: week,
    rows: (rows ?? []) as LeaderboardRow[],
    groupUrl: WEB_URL ? `${WEB_URL}/groups/${g.group_id}` : undefined,
  });
  // A stalled webhook must not hold up the remaining groups.
  const res = await fetch(g.webhook_url, {
    method: "POST",
    redirect: "error",
    signal: AbortSignal.timeout(10_000),
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(payload),
  });
  if (!res.ok) return `slack error ${res.status}`;

  const { error: updateError } = await supabase
    .from("group_slack_settings")
    .update({ last_posted_week: week })
    .eq("group_id", g.group_id);
  // If this fails, the next hourly run will post the same week again.
  return updateError ? `posted ${week}, but saving it failed: ${updateError.message}` : `posted ${week}`;
}
