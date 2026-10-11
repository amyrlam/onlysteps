"use client"

import { useState } from "react"
import { CheckIcon, CopyIcon } from "lucide-react"
import { Button } from "@onlysteps/ui/components/button"
import { Input } from "@onlysteps/ui/components/input"

export function InviteLink({ url }: { url: string }) {
  const [copied, setCopied] = useState(false)
  return (
    <div className="flex gap-2">
      <Input readOnly value={url} aria-label="Invite link" onFocus={(e) => e.currentTarget.select()} />
      <Button
        variant="outline"
        onClick={async () => {
          await navigator.clipboard.writeText(url)
          setCopied(true)
          setTimeout(() => setCopied(false), 2000)
        }}
      >
        {copied ? <CheckIcon data-icon="inline-start" /> : <CopyIcon data-icon="inline-start" />}
        {copied ? "Copied" : "Copy"}
      </Button>
    </div>
  )
}
