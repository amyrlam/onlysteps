"use client"

import { useActionState, useState, useTransition } from "react"
import { Button } from "@onlysteps/ui/components/button"
import { Field, FieldDescription, FieldLabel } from "@onlysteps/ui/components/field"
import { Input } from "@onlysteps/ui/components/input"
import { NativeSelect, NativeSelectOption } from "@onlysteps/ui/components/native-select"
import { Switch } from "@onlysteps/ui/components/switch"
import { saveSlackSettings, sendTestPost, type ActionState } from "../../../actions"

const WEEKDAYS = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
const hourLabel = (h: number) => new Date(2000, 0, 1, h).toLocaleTimeString("en-US", { hour: "numeric" })

type Settings = { webhook_url: string; enabled: boolean; post_weekday: number; post_hour: number } | null

export function SlackSettingsForm({ groupId, settings }: { groupId: string; settings: Settings }) {
  const [state, action, saving] = useActionState(saveSlackSettings, undefined)
  const [testState, setTestState] = useState<ActionState>()
  const [testing, startTest] = useTransition()
  const message = testState ?? state

  return (
    <form action={action} className="flex flex-col gap-5">
      <input type="hidden" name="groupId" value={groupId} />
      <Field>
        <FieldLabel htmlFor="webhookUrl">Incoming webhook URL</FieldLabel>
        <Input
          id="webhookUrl"
          name="webhookUrl"
          type="url"
          required
          placeholder="https://hooks.slack.com/services/…"
          defaultValue={settings?.webhook_url}
        />
        <FieldDescription>
          In Slack, create an app with an incoming webhook for your channel, then paste its URL here.
        </FieldDescription>
      </Field>
      <div className="grid grid-cols-2 gap-3">
        <Field>
          <FieldLabel htmlFor="weekday">Day</FieldLabel>
          <NativeSelect id="weekday" name="weekday" defaultValue={String(settings?.post_weekday ?? 1)}>
            {WEEKDAYS.map((d, i) => (
              <NativeSelectOption key={d} value={i + 1}>
                {d}
              </NativeSelectOption>
            ))}
          </NativeSelect>
        </Field>
        <Field>
          <FieldLabel htmlFor="hour">Time</FieldLabel>
          <NativeSelect id="hour" name="hour" defaultValue={String(settings?.post_hour ?? 9)}>
            {Array.from({ length: 24 }, (_, h) => (
              <NativeSelectOption key={h} value={h}>
                {hourLabel(h)}
              </NativeSelectOption>
            ))}
          </NativeSelect>
        </Field>
      </div>
      <Field orientation="horizontal">
        <Switch id="enabled" name="enabled" defaultChecked={settings?.enabled ?? true} />
        <FieldLabel htmlFor="enabled">Post the weekly winner automatically</FieldLabel>
      </Field>
      {message?.error ? <p className="text-destructive text-sm">{message.error}</p> : null}
      {message?.ok ? <p className="text-success text-sm">{message.ok}</p> : null}
      <div className="flex gap-2">
        <Button type="submit" disabled={saving} onClick={() => setTestState(undefined)}>
          {saving ? "Saving…" : "Save"}
        </Button>
        <Button
          type="button"
          variant="outline"
          disabled={!settings || testing}
          onClick={() => startTest(async () => setTestState(await sendTestPost(groupId)))}
        >
          {testing ? "Sending…" : "Send test post"}
        </Button>
      </div>
    </form>
  )
}
