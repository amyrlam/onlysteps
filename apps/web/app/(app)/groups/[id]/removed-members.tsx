"use client"

import { useState, useTransition } from "react"
import { Avatar, AvatarFallback, AvatarImage } from "@onlysteps/ui/components/avatar"
import { Badge } from "@onlysteps/ui/components/badge"
import { Button } from "@onlysteps/ui/components/button"
import { Item, ItemActions, ItemContent, ItemDescription, ItemGroup, ItemMedia, ItemTitle } from "@onlysteps/ui/components/item"
import { initials } from "@onlysteps/ui/lib/utils"
import { approveRejoin, dismissRejoin, liftRemoval, type ActionState } from "../../../actions"

export type RemovedMember = {
  user_id: string
  display_name: string
  avatar_url: string | null
  removed_at: string
  requested_at: string | null
  dismissed_at: string | null
}

const day = (iso: string) => new Date(iso).toLocaleDateString("en-US", { month: "short", day: "numeric" })

export function RemovedMembers({ groupId, members }: { groupId: string; members: RemovedMember[] }) {
  return (
    <ItemGroup className="gap-2">
      {members.map((m) => (
        <RemovedMemberItem key={m.user_id} groupId={groupId} member={m} />
      ))}
    </ItemGroup>
  )
}

function RemovedMemberItem({ groupId, member: m }: { groupId: string; member: RemovedMember }) {
  const [pending, startTransition] = useTransition()
  const [state, setState] = useState<ActionState>()
  const run = (action: typeof approveRejoin) => startTransition(async () => setState(await action(groupId, m.user_id)))
  const isRequest = m.requested_at !== null && m.dismissed_at === null

  return (
    <Item variant="outline" size="sm">
      <ItemMedia>
        <Avatar>
          {m.avatar_url ? <AvatarImage src={m.avatar_url} alt="" /> : null}
          <AvatarFallback>{initials(m.display_name)}</AvatarFallback>
        </Avatar>
      </ItemMedia>
      <ItemContent>
        <ItemTitle>
          {m.display_name}
          {isRequest ? <Badge variant="secondary">Wants to rejoin</Badge> : null}
        </ItemTitle>
        <ItemDescription>
          {isRequest
            ? `Asked ${day(m.requested_at!)}`
            : m.dismissed_at
              ? `Request dismissed ${day(m.dismissed_at)}`
              : `Removed ${day(m.removed_at)}`}
        </ItemDescription>
        {state?.error ? <p className="text-destructive text-sm">{state.error}</p> : null}
      </ItemContent>
      <ItemActions>
        {isRequest ? (
          <>
            <Button size="sm" variant="outline" disabled={pending} onClick={() => run(dismissRejoin)}>
              Dismiss
            </Button>
            <Button size="sm" disabled={pending} onClick={() => run(approveRejoin)}>
              Approve
            </Button>
          </>
        ) : (
          <Button size="sm" variant="outline" disabled={pending} onClick={() => run(liftRemoval)}>
            Allow back
          </Button>
        )}
      </ItemActions>
    </Item>
  )
}
