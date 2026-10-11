import type { Metadata } from "next"
import Link from "next/link"
import { Button, buttonVariants } from "@onlysteps/ui/components/button"
import { APP_NAME } from "@/lib/brand"
import { getUser } from "@/lib/supabase/server"
import { joinGroup } from "../../actions"

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
            {error ? (
              <p className="text-destructive text-sm">
                {error === "removed" ? "You were removed from this group. Ask the owner to add you back." : "Couldn’t join. Try again."}
              </p>
            ) : null}
            {user ? (
              <form action={joinGroup.bind(null, code)}>
                <Button size="lg" className="w-full" type="submit">
                  Join group
                </Button>
              </form>
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
