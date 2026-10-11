"use server"

import { revalidatePath } from "next/cache"
import { redirect } from "next/navigation"
import { winnerMessage, weekStart, type LeaderboardRow } from "@onlysteps/functions/weekly"
import { APP_NAME, SITE_URL } from "@/lib/brand"
import { createClient } from "@/lib/supabase/server"

export type ActionState = { error?: string; ok?: string } | undefined

export async function createGroup(_: ActionState, form: FormData): Promise<ActionState> {
  const supabase = await createClient()
  const name = String(form.get("name") ?? "").trim()
  const timeZone = String(form.get("timeZone") ?? "UTC")
  if (!name) return { error: "Give your group a name." }
  const { data, error } = await supabase.from("groups").insert({ name, time_zone: timeZone }).select("id").single()
  if (error) return { error: error.message }
  redirect(`/groups/${data.id}`)
}

export async function joinGroup(code: string) {
  const supabase = await createClient()
  const { data, error } = await supabase.rpc("join_group", { code })
  if (error) redirect(`/join/${code}?error=1`)
  redirect(`/groups/${data}`)
}

export async function saveSlackSettings(_: ActionState, form: FormData): Promise<ActionState> {
  const supabase = await createClient()
  const groupId = String(form.get("groupId"))
  const webhookUrl = String(form.get("webhookUrl") ?? "").trim()
  if (!webhookUrl.startsWith("https://hooks.slack.com/")) {
    return { error: "That doesn’t look like a Slack incoming webhook URL." }
  }
  const { error } = await supabase.from("group_slack_settings").upsert({
    group_id: groupId,
    webhook_url: webhookUrl,
    enabled: form.get("enabled") === "on",
    post_weekday: Number(form.get("weekday") ?? 1),
    post_hour: Number(form.get("hour") ?? 9),
    updated_at: new Date().toISOString(),
  })
  if (error) return { error: error.message }
  revalidatePath(`/groups/${groupId}`)
  return { ok: "Saved." }
}

export async function sendTestPost(groupId: string): Promise<ActionState> {
  const supabase = await createClient()
  const [{ data: group }, { data: settings }] = await Promise.all([
    supabase.from("groups").select("name, time_zone").eq("id", groupId).single(),
    supabase.from("group_slack_settings").select("webhook_url").eq("group_id", groupId).maybeSingle(),
  ])
  if (!group || !settings) return { error: "Save a webhook URL first." }

  const { data: rows } = await supabase.rpc("group_leaderboard", { gid: groupId })
  const payload = winnerMessage({
    appName: APP_NAME,
    groupName: group.name,
    weekStart: weekStart(new Date(), group.time_zone),
    rows: (rows ?? []) as LeaderboardRow[],
    groupUrl: `${SITE_URL}/groups/${groupId}`,
    test: true,
  })
  const res = await fetch(settings.webhook_url, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(payload),
  })
  return res.ok ? { ok: "Test post sent to Slack." } : { error: `Slack returned ${res.status}.` }
}

export async function signOut() {
  const supabase = await createClient()
  await supabase.auth.signOut()
  redirect("/")
}
