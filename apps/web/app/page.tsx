import Link from "next/link"
import { redirect } from "next/navigation"
import { buttonVariants } from "@onlysteps/ui/components/button"
import { Leaderboard } from "@onlysteps/ui/components/leaderboard"
import { APP_NAME } from "@/lib/brand"
import { getUser } from "@/lib/supabase/server"

const demo = [
  { userId: "1", name: "Priya", steps: 84210, rank: 1 },
  { userId: "2", name: "You", steps: 71388, rank: 2 },
  { userId: "3", name: "Jordan", steps: 65002, rank: 3 },
]

export default async function Home() {
  const { user } = await getUser()
  if (user) redirect("/groups")

  return (
    <main className="mx-auto flex min-h-dvh max-w-5xl flex-col items-center justify-center gap-12 px-6 py-16 md:flex-row">
      <div className="flex max-w-md flex-col gap-6">
        <h1 className="text-5xl font-semibold">Walk more. Win the week.</h1>
        <p className="text-muted-foreground text-lg">
          {APP_NAME} turns your iPhone step count into a friendly weekly competition. Make a group, invite friends, and get the
          winner posted to Slack every Monday.
        </p>
        <div className="flex gap-3">
          <Link href="/login" className={buttonVariants({ size: "lg" })}>
            Get started
          </Link>
          <a href="https://github.com/amyrlam/onlysteps" className={buttonVariants({ size: "lg", variant: "outline" })}>
            Open source
          </a>
        </div>
      </div>
      <div className="bg-card w-full max-w-sm rounded-2xl border p-4 shadow-sm">
        <p className="text-muted-foreground mb-2 px-3 text-xs font-medium tracking-wide uppercase">This week</p>
        <Leaderboard entries={demo} currentUserId="2" />
      </div>
    </main>
  )
}
