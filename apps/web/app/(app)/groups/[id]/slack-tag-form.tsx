"use client"

import { useActionState, useState } from "react"
import { Button } from "@onlysteps/ui/components/button"
import { Field, FieldLabel } from "@onlysteps/ui/components/field"
import { Input } from "@onlysteps/ui/components/input"
import { saveSlackMemberId } from "../../../actions"

/** Lets someone save their own Slack member ID so posts can tag them. */
export function SlackTagForm({ groupId, memberId }: { groupId: string; memberId: string | null }) {
  const [state, action, saving] = useActionState(saveSlackMemberId, undefined)
  const [value, setValue] = useState(memberId ?? "")

  return (
    <form action={action} className="flex flex-col gap-3">
      <input type="hidden" name="groupId" value={groupId} />
      <div className="grid grid-cols-1 items-end gap-3 sm:grid-cols-[1fr_auto]">
        <Field>
          <FieldLabel htmlFor="slackMemberId">Your Slack member ID</FieldLabel>
          <Input
            id="slackMemberId"
            name="slackMemberId"
            placeholder="U0123ABCD"
            autoComplete="off"
            spellCheck={false}
            value={value}
            onChange={(e) => setValue(e.target.value)}
          />
        </Field>
        <Button type="submit" disabled={saving}>
          {saving ? "Saving…" : "Save"}
        </Button>
      </div>
      <p aria-live="polite" className={`min-h-5 text-sm ${state?.error ? "text-destructive" : "text-muted-foreground"}`}>
        {state?.error ?? state?.ok}
      </p>
    </form>
  )
}
