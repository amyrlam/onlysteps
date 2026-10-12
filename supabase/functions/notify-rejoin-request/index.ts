// Tells a group's Slack channel that someone the owner removed asked to
// rejoin. Called by the web and iOS apps, with the requester's JWT, right after
// request_rejoin succeeds. Posts at most once per request: notified_at is
// claimed before posting, and only for the caller's own pending request.
import { createClient } from "npm:@supabase/supabase-js@2";
import { rejoinRequestMessage } from "../_shared/rejoin.ts";

const APP_NAME = Deno.env.get("APP_NAME") ?? "OnlySteps";
const WEB_URL = Deno.env.get("WEB_URL") ?? "";
const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

Deno.serve(async (req) => {
  if (req.method !== "POST") return new Response("Method not allowed", { status: 405 });

  const supabase = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!, {
    auth: { persistSession: false },
  });

  const jwt = req.headers.get("Authorization")?.replace(/^Bearer /, "") ?? "";
  const { data: auth } = await supabase.auth.getUser(jwt);
  if (!auth.user) return new Response("Unauthorized", { status: 401 });

  const body = await req.json().catch(() => ({}));
  const groupId = typeof body?.group_id === "string" && UUID.test(body.group_id) ? body.group_id : null;
  if (!groupId) return Response.json({ error: "group_id is required" }, { status: 400 });

  // Claim the notification. No row: no pending request, or already notified.
  const { data: claimed, error } = await supabase
    .from("group_removals")
    .update({ notified_at: new Date().toISOString() })
    .eq("group_id", groupId)
    .eq("user_id", auth.user.id)
    .not("requested_at", "is", null)
    .is("dismissed_at", null)
    .is("notified_at", null)
    .select("group_id, groups(name)");
  if (error) return Response.json({ error: error.message }, { status: 500 });
  if (!claimed?.length) return Response.json({ posted: false, reason: "nothing to notify" });

  const { data: settings } = await supabase
    .from("group_slack_settings")
    .select("webhook_url")
    .eq("group_id", groupId)
    .maybeSingle();
  if (!settings) return Response.json({ posted: false, reason: "no Slack webhook" });

  const group = claimed[0].groups as unknown as { name: string };
  const payload = rejoinRequestMessage({
    appName: APP_NAME,
    groupName: group.name,
    groupUrl: WEB_URL ? `${WEB_URL}/groups/${groupId}` : undefined,
  });
  try {
    const res = await fetch(settings.webhook_url, {
      method: "POST",
      redirect: "error",
      signal: AbortSignal.timeout(10_000),
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
    });
    return Response.json({ posted: res.ok, status: res.status });
  } catch {
    // The request itself is saved and shows on the group page either way.
    return Response.json({ posted: false, reason: "Slack unreachable" });
  }
});
