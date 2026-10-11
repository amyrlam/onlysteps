import type { Metadata } from "next"
import Link from "next/link"
import { ChevronRightIcon, UsersIcon } from "lucide-react"
import { Card } from "@onlysteps/ui/components/card"
import { Empty, EmptyDescription, EmptyHeader, EmptyMedia, EmptyTitle } from "@onlysteps/ui/components/empty"
import { getUser } from "@/lib/supabase/server"
import { CreateGroupDialog } from "./create-group-dialog"

export const metadata: Metadata = { title: "Groups" }

export default async function GroupsPage() {
  const { supabase, user } = await getUser()
  const { data: memberships } = await supabase
    .from("group_members")
    .select("role, groups(id, name)")
    .eq("user_id", user!.id)
    .order("joined_at")

  const groups = (memberships ?? []).flatMap((m) => (m.groups ? [{ ...m.groups, role: m.role }] : []))

  return (
    <div className="flex flex-col gap-6">
      <div className="flex items-center justify-between">
        <h1 className="text-3xl font-semibold">Your groups</h1>
        <CreateGroupDialog />
      </div>
      {groups.length === 0 ? (
        <Empty className="border">
          <EmptyHeader>
            <EmptyMedia variant="icon">
              <UsersIcon />
            </EmptyMedia>
            <EmptyTitle>No groups yet</EmptyTitle>
            <EmptyDescription>Create a group, or open an invite link from a friend to join theirs.</EmptyDescription>
          </EmptyHeader>
        </Empty>
      ) : (
        <ul className="flex flex-col gap-2">
          {groups.map((g) => (
            <li key={g.id}>
              <Link href={`/groups/${g.id}`}>
                <Card className="hover:bg-muted/50 flex-row items-center justify-between px-4 transition-colors">
                  <span className="font-medium">{g.name}</span>
                  <ChevronRightIcon className="text-muted-foreground size-4" />
                </Card>
              </Link>
            </li>
          ))}
        </ul>
      )}
    </div>
  )
}
