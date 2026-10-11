"use server"

import { revalidatePath } from "next/cache"
import { redirect } from "next/navigation"
import { winnerMessage, weekStart, type LeaderboardRow } from "@onlysteps/functions/weekly"
import { APP_NAME, SITE_URL } from "@/lib/brand"
import { createClient } from "@/lib/supabase/server"

function isValidTimeZone(timeZone: string) {
  try {
    new Intl.DateTimeFormat("en-US", { timeZone })
    return true
  } catch {
    return false
  }
}

function isSlackWebhookUrl(value: string) {
  try {
    const url = new URL(value)
    return (
      url.protocol === "https:" &&
      url.hostname === "hooks.slack.com" &&
      url.port === "" &&
      url.username === "" &&
      url.password === "" &&
      url.pathname.startsWith("/services/")
    )
  } catch {
    return false
  }
}

function intInRange(value: FormDataEntryValue | null, fallback: number, min: number, max: number) {
  const n = value == null ? fallback : Number(value)
  return Number.isInteger(n) && n >= min && n <= max ? n : null
}

export type ActionState = { error?: string; ok?: string } | undefined

export async function createGroup(_: ActionState, form: FormData): Promise<ActionState> {
  const supabase = await createClient()
  const name = String(form.get("name") ?? "").trim()
  const timeZone = String(form.get("timeZone") ?? "UTC")
  if (!name) return { error: "Give your group a name." }
  if (!isValidTimeZone(timeZone)) return { error: "Unknown time zone." }
  const { data, error } = await supabase.from("groups").insert({ name, time_zone: timeZone }).select("id").single()
  if (error) return { error: error.message }
  redirect(`/groups/${data.id}`)
}

export async function joinGroup(code: string) {
  const supabase = await createClient()
  const { data, error } = await supabase.rpc("join_group", { code })
  // Removed members land back on the invite page, which offers a request to rejoin.
  if (error) redirect(error.message.includes("removed from this group") ? `/join/${code}` : `/join/${code}?error=1`)
  redirect(`/groups/${data}`)
}

/** Asks the owner to let a removed member back in, then pings the group's Slack. */
export async function requestRejoin(code: string) {
  const supabase = await createClient()
  const { data: groupId, error } = await supabase.rpc("request_rejoin", { code })
  if (error) redirect(`/join/${code}?error=1`)
  // Best effort: the request is saved and shows on the group page either way.
  await supabase.functions.invoke("notify-rejoin-request", { body: { group_id: groupId } }).catch(() => {})
  redirect(`/join/${code}`)
}

async function ownerAction(groupId: string, run: () => PromiseLike<{ error: { message: string } | null }>) {
  const { error } = await run()
  if (error) return { error: error.message }
  revalidatePath(`/groups/${groupId}`)
  return undefined
}

export async function approveRejoin(groupId: string, userId: string): Promise<ActionState> {
  const supabase = await createClient()
  return ownerAction(groupId, () => supabase.rpc("approve_rejoin", { gid: groupId, uid: userId }))
}

export async function dismissRejoin(groupId: string, userId: string): Promise<ActionState> {
  const supabase = await createClient()
  return ownerAction(groupId, () => supabase.rpc("dismiss_rejoin", { gid: groupId, uid: userId }))
}

/** Lifts a removal so the person can join again with the invite link. */
export async function liftRemoval(groupId: string, userId: string): Promise<ActionState> {
  const supabase = await createClient()
  return ownerAction(groupId, () => supabase.from("group_removals").delete().eq("group_id", groupId).eq("user_id", userId))
}

export async function saveSlackSettings(_: ActionState, form: FormData): Promise<ActionState> {
  const supabase = await createClient()
  const groupId = String(form.get("groupId"))
  const webhookUrl = String(form.get("webhookUrl") ?? "").trim()
  if (!isSlackWebhookUrl(webhookUrl)) {
    return { error: "That doesn’t look like a Slack incoming webhook URL." }
  }
  const weekday = intInRange(form.get("weekday"), 1, 1, 7)
  const hour = intInRange(form.get("hour"), 9, 0, 23)
  if (weekday === null || hour === null) return { error: "Pick a day and time." }
  const { error } = await supabase.from("group_slack_settings").upsert({
    group_id: groupId,
    webhook_url: webhookUrl,
    enabled: form.get("enabled") === "on",
    post_weekday: weekday,
    post_hour: hour,
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
  try {
    const res = await fetch(settings.webhook_url, {
      method: "POST",
      redirect: "error",
      signal: AbortSignal.timeout(10_000),
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
    })
    return res.ok ? { ok: "Test post sent to Slack." } : { error: `Slack returned ${res.status}.` }
  } catch {
    return { error: "Couldn’t reach Slack. Try again." }
  }
}

export async function signOut() {
  const supabase = await createClient()
  await supabase.auth.signOut()
  redirect("/")
}
