import type { Metadata } from "next"
import Link from "next/link"
import { Button, buttonVariants } from "@onlysteps/ui/components/button"
import { APP_NAME } from "@/lib/brand"
import { getUser } from "@/lib/supabase/server"
import { joinGroup, requestRejoin } from "../../actions"

export const metadata: Metadata = { title: "Join group" }

export default async function JoinPage({
  params,
  searchParams,
}: {
  params: Promise<{ code: string }>
  searchParams: Promise<{ error?: string }>
}) {
  const [{ code }, { error }] = await Promise.all([params, searchParams])
  const { supabase, user } = await getUser()
  const { data } = await supabase.rpc("group_for_invite", { code })
  const group = data?.[0]

  // Signed-in visitors: already a member, or removed by the owner (with or
  // without a pending request to rejoin)?
  const [{ data: membership }, { data: removal }] =
    group && user
      ? await Promise.all([
          supabase.from("group_members").select("group_id").eq("group_id", group.id).eq("user_id", user.id).maybeSingle(),
          supabase
            .from("group_removals")
            .select("requested_at, dismissed_at")
            .eq("group_id", group.id)
            .eq("user_id", user.id)
            .maybeSingle(),
        ])
      : [{ data: null }, { data: null }]

  return (
    <main className="flex min-h-dvh items-center justify-center px-6">
      <div className="bg-card flex w-full max-w-sm flex-col gap-5 rounded-2xl border p-6 text-center">
        {group ? (
          <>
            <div className="flex flex-col gap-1">
              <p className="text-muted-foreground text-sm">You’re invited to join</p>
              <h1 className="text-3xl font-semibold">{group.name}</h1>
              <p className="text-muted-foreground text-sm">
                {group.member_count} {Number(group.member_count) === 1 ? "member" : "members"} on {APP_NAME}
              </p>
            </div>
            {membership ? (
              <Link href={`/groups/${group.id}`} className={buttonVariants({ size: "lg" })}>
                Open group
              </Link>
            ) : removal?.dismissed_at ? (
              <p className="text-muted-foreground text-sm">
                The owner removed you from this group and dismissed your request to rejoin.
              </p>
            ) : removal?.requested_at ? (
              <p className="text-muted-foreground text-sm">
                Request sent. You’ll be back in the group once the owner approves it.
              </p>
            ) : removal ? (
              <>
                <p className="text-muted-foreground text-sm">
                  The owner removed you from this group. You can ask them to let you back in.
                </p>
                {error ? <p className="text-destructive text-sm">Couldn’t send your request. Try again.</p> : null}
                <form action={requestRejoin.bind(null, code)}>
                  <Button size="lg" className="w-full" type="submit">
                    Request to rejoin
                  </Button>
                </form>
              </>
            ) : user ? (
              <>
                {error ? <p className="text-destructive text-sm">Couldn’t join. Try again.</p> : null}
                <form action={joinGroup.bind(null, code)}>
                  <Button size="lg" className="w-full" type="submit">
                    Join group
                  </Button>
                </form>
              </>
            ) : (
              <Link href={`/login?next=/join/${code}`} className={buttonVariants({ size: "lg" })}>
                Sign in to join
              </Link>
            )}
          </>
        ) : (
          <>
            <h1 className="text-2xl font-semibold">Invite not found</h1>
            <p className="text-muted-foreground text-sm">The link may be mistyped, or the group was deleted.</p>
            <Link href="/" className={buttonVariants({ variant: "outline" })}>
              Go home
            </Link>
          </>
        )}
      </div>
    </main>
  )
}
