import * as React from "react"
import { Avatar, AvatarFallback, AvatarImage } from "./avatar"
import { cn, initials } from "../lib/utils"

export type LeaderboardEntry = {
  userId: string
  name: string
  avatarUrl?: string | null
  steps: number
  rank: number
}

const formatter = new Intl.NumberFormat("en-US")

const medalClass: Record<number, string> = {
  1: "bg-podium-gold text-primary-foreground",
  2: "bg-podium-silver text-primary-foreground",
  3: "bg-podium-bronze text-primary-foreground",
}

function Leaderboard({
  entries,
  currentUserId,
  className,
  ...props
}: React.ComponentProps<"ol"> & { entries: LeaderboardEntry[]; currentUserId?: string }) {
  const top = Math.max(1, ...entries.map((e) => e.steps))
  if (entries.length === 0) {
    return <p className="text-muted-foreground text-sm">No one here yet. Share the invite link to get started.</p>
  }
  return (
    <ol data-slot="leaderboard" className={cn("flex flex-col gap-1", className)} {...props}>
      {entries.map((e) => {
        const isYou = e.userId === currentUserId
        return (
          <li
            key={e.userId}
            data-you={isYou || undefined}
            className="data-you:bg-accent data-you:text-accent-foreground relative flex items-center gap-3 rounded-lg px-3 py-2"
          >
            <span
              className={cn(
                "flex size-7 shrink-0 items-center justify-center rounded-full text-xs font-semibold tabular-nums",
                medalClass[e.rank] ?? "bg-muted text-muted-foreground"
              )}
              aria-label={`Rank ${e.rank}`}
            >
              {e.rank}
            </span>
            <Avatar size="sm">
              {e.avatarUrl ? <AvatarImage src={e.avatarUrl} alt="" /> : null}
              <AvatarFallback>{initials(e.name)}</AvatarFallback>
            </Avatar>
            <div className="min-w-0 flex-1">
              <div className="flex items-baseline justify-between gap-2">
                <span className="truncate text-sm font-medium">
                  {e.name}
                  {isYou ? <span className="text-muted-foreground font-normal"> (you)</span> : null}
                </span>
                <span className="text-sm font-semibold tabular-nums">{formatter.format(e.steps)}</span>
              </div>
              <div className="bg-muted mt-1.5 h-1.5 overflow-hidden rounded-full" aria-hidden>
                <div
                  className="bg-primary h-full rounded-full transition-[width] duration-500"
                  style={{ width: `${(e.steps / top) * 100}%` }}
                />
              </div>
            </div>
          </li>
        )
      })}
    </ol>
  )
}

export { Leaderboard }
