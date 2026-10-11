"use client"

import { useActionState, useEffect, useState } from "react"
import { PlusIcon } from "lucide-react"
import { Button } from "@onlysteps/ui/components/button"
import {
  Dialog,
  DialogClose,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@onlysteps/ui/components/dialog"
import { Field, FieldDescription, FieldLabel } from "@onlysteps/ui/components/field"
import { Input } from "@onlysteps/ui/components/input"
import { createGroup } from "../../actions"

export function CreateGroupDialog() {
  const [state, action, pending] = useActionState(createGroup, undefined)
  const [timeZone, setTimeZone] = useState("UTC")
  useEffect(() => setTimeZone(Intl.DateTimeFormat().resolvedOptions().timeZone), [])

  return (
    <Dialog>
      <DialogTrigger render={<Button />}>
        <PlusIcon data-icon="inline-start" /> New group
      </DialogTrigger>
      <DialogContent>
        <form action={action} className="flex flex-col gap-4">
          <DialogHeader>
            <DialogTitle>Create a group</DialogTitle>
            <DialogDescription>You can invite friends once it’s created.</DialogDescription>
          </DialogHeader>
          <Field>
            <FieldLabel htmlFor="name">Name</FieldLabel>
            <Input id="name" name="name" placeholder="Office walkers" required maxLength={60} />
            <FieldDescription>Weeks run Monday to Sunday in {timeZone}.</FieldDescription>
          </Field>
          <input type="hidden" name="timeZone" value={timeZone} />
          {state?.error ? <p className="text-destructive text-sm">{state.error}</p> : null}
          <DialogFooter>
            <DialogClose render={<Button variant="outline" type="button" />}>Cancel</DialogClose>
            <Button type="submit" disabled={pending}>
              {pending ? "Creating…" : "Create"}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  )
}
