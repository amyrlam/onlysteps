"use client"

import { useActionState, useState } from "react"
import { Button } from "@onlysteps/ui/components/button"
import { Field, FieldLabel } from "@onlysteps/ui/components/field"
import { Input } from "@onlysteps/ui/components/input"
import { NativeSelect, NativeSelectOption } from "@onlysteps/ui/components/native-select"
import { logSteps } from "../../../actions"

// Days are yyyy-mm-dd strings, so format in UTC to keep them on the same date.
const dayFormat = new Intl.DateTimeFormat("en-US", { weekday: "short", month: "short", day: "numeric", timeZone: "UTC" })

function dayLabel(day: string, index: number) {
  if (index === 0) return "Today"
  if (index === 1) return "Yesterday"
  return dayFormat.format(new Date(`${day}T00:00:00Z`))
}

/** `days` runs from today backwards; `logged` holds the steps already saved per day. */
export function LogStepsForm({
  groupId,
  days,
  logged,
}: {
  groupId: string
  days: string[]
  logged: Record<string, number>
}) {
  const [state, action, saving] = useActionState(logSteps, undefined)
  const [day, setDay] = useState(days[0])
  const [steps, setSteps] = useState(logged[days[0]]?.toString() ?? "")

  function chooseDay(next: string) {
    setDay(next)
    setSteps(logged[next]?.toString() ?? "")
  }

  return (
    <form action={action} className="flex flex-col gap-3">
      <input type="hidden" name="groupId" value={groupId} />
      <div className="grid grid-cols-1 items-end gap-3 sm:grid-cols-[1fr_1fr_auto]">
        <Field>
          <FieldLabel htmlFor="day">Day</FieldLabel>
          <NativeSelect id="day" name="day" className="w-full" value={day} onChange={(e) => chooseDay(e.target.value)}>
            {days.map((d, i) => (
              <NativeSelectOption key={d} value={d}>
                {dayLabel(d, i)}
              </NativeSelectOption>
            ))}
          </NativeSelect>
        </Field>
        <Field>
          <FieldLabel htmlFor="steps">Steps</FieldLabel>
          <Input
            id="steps"
            name="steps"
            type="number"
            inputMode="numeric"
            required
            min={0}
            max={200000}
            step={1}
            value={steps}
            onChange={(e) => setSteps(e.target.value)}
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
