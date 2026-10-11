"use client"

import { useState } from "react"
import { Button } from "@onlysteps/ui/components/button"
import { Field, FieldLabel } from "@onlysteps/ui/components/field"
import { Input } from "@onlysteps/ui/components/input"
import { Separator } from "@onlysteps/ui/components/separator"
import { createClient } from "@/lib/supabase/client"

export function LoginForm({ next }: { next: string }) {
  const [email, setEmail] = useState("")
  const [status, setStatus] = useState<"idle" | "sending" | "sent" | "error">("idle")
  const redirectTo = () => `${window.location.origin}/auth/callback?next=${encodeURIComponent(next)}`

  async function sendLink(e: React.FormEvent) {
    e.preventDefault()
    setStatus("sending")
    const { error } = await createClient().auth.signInWithOtp({ email, options: { emailRedirectTo: redirectTo() } })
    setStatus(error ? "error" : "sent")
  }

  async function signInWithApple() {
    await createClient().auth.signInWithOAuth({ provider: "apple", options: { redirectTo: redirectTo() } })
  }

  if (status === "sent") {
    return <p className="bg-accent text-accent-foreground rounded-lg p-4 text-center text-sm">Check {email} for a sign-in link.</p>
  }

  return (
    <div className="flex flex-col gap-4">
      <Button size="lg" variant="outline" onClick={signInWithApple}>
        Continue with Apple
      </Button>
      <div className="text-muted-foreground flex items-center gap-3 text-xs">
        <Separator className="flex-1" /> or <Separator className="flex-1" />
      </div>
      <form onSubmit={sendLink} className="flex flex-col gap-3">
        <Field>
          <FieldLabel htmlFor="email">Email</FieldLabel>
          <Input id="email" type="email" required autoComplete="email" value={email} onChange={(e) => setEmail(e.target.value)} />
        </Field>
        <Button size="lg" type="submit" disabled={status === "sending"}>
          {status === "sending" ? "Sending…" : "Email me a sign-in link"}
        </Button>
        {status === "error" ? <p className="text-destructive text-sm">Couldn’t send the link. Try again.</p> : null}
      </form>
    </div>
  )
}
