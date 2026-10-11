import type { Metadata } from "next"
import Link from "next/link"
import { notFound } from "next/navigation"
import { addDays, weekStart } from "@onlysteps/functions/weekly"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@onlysteps/ui/components/card"
import { Leaderboard } from "@onlysteps/ui/components/leaderboard"
import { Tabs, TabsList, TabsTrigger } from "@onlysteps/ui/components/tabs"
import { SITE_URL } from "@/lib/brand"
import { getUser } from "@/lib/supabase/server"
import { InviteLink } from "./invite-link"
import { SlackSettingsForm } from "./slack-settings-form"

export const metadata: Metadata = { title: "Leaderboard" }

export default async function GroupPage({
  params,
  searchParams,
}: {
  params: Promise<{ id: string }>
  searchParams: Promise<{ week?: string }>
}) {
  const [{ id }, { week }] = await Promise.all([params, searchParams])
  const { supabase, user } = await getUser()

  const { data: group } = await supabase.from("groups").select("id, name, invite_code, time_zone").eq("id", id).maybeSingle()
  if (!group) notFound()

  const thisWeek = weekStart(new Date(), group.time_zone)
  const showing = week === "last" ? addDays(thisWeek, -7) : thisWeek

  const [{ data: rows }, { data: me }, { data: slack }] = await Promise.all([
    supabase.rpc("group_leaderboard", { gid: id, week: showing }),
    supabase.from("group_members").select("role").eq("group_id", id).eq("user_id", user!.id).single(),
    supabase.from("group_slack_settings").select("webhook_url, enabled, post_weekday, post_hour").eq("group_id", id).maybeSingle(),
  ])
  const isOwner = me?.role === "owner"
  const entries = (rows ?? []).map((r) => ({
    userId: r.user_id,
    name: r.display_name,
    avatarUrl: r.avatar_url,
    steps: Number(r.total_steps),
    rank: Number(r.rank),
  }))
  const hasSteps = entries.some((e) => e.userId === user!.id && e.steps > 0)

  return (
    <div className="flex flex-col gap-6">
      <div className="flex flex-col gap-1">
        <Link href="/groups" className="text-muted-foreground text-sm hover:underline">
          ← Groups
        </Link>
        <h1 className="text-3xl font-semibold">{group.name}</h1>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>Leaderboard</CardTitle>
          <CardDescription>Monday to Sunday, {group.time_zone}</CardDescription>
        </CardHeader>
        <CardContent className="flex flex-col gap-4">
          <Tabs value={week === "last" ? "last" : "this"}>
            <TabsList>
              <TabsTrigger value="this" nativeButton={false} render={<Link href={`/groups/${id}`} />}>
                This week
              </TabsTrigger>
              <TabsTrigger value="last" nativeButton={false} render={<Link href={`/groups/${id}?week=last`} />}>
                Last week
              </TabsTrigger>
            </TabsList>
          </Tabs>
          <Leaderboard entries={entries} currentUserId={user!.id} />
          {!hasSteps && week !== "last" ? (
            <p className="text-muted-foreground text-sm">
              Your steps come from the iPhone app. Sign in there with the same account and they’ll appear here.
            </p>
          ) : null}
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>Invite friends</CardTitle>
          <CardDescription>Anyone with this link can join the group.</CardDescription>
        </CardHeader>
        <CardContent>
          <InviteLink url={`${SITE_URL}/join/${group.invite_code}`} />
        </CardContent>
      </Card>

      {isOwner ? (
        <Card>
          <CardHeader>
            <CardTitle>Slack</CardTitle>
            <CardDescription>Post last week’s winner to a Slack channel.</CardDescription>
          </CardHeader>
          <CardContent>
            <SlackSettingsForm groupId={id} settings={slack} />
          </CardContent>
        </Card>
      ) : null}
    </div>
  )
}
