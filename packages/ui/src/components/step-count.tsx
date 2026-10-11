import * as React from "react"
import { cn } from "../lib/utils"

const formatter = new Intl.NumberFormat("en-US")

function StepCount({
  steps,
  label,
  size = "default",
  className,
  ...props
}: React.ComponentProps<"div"> & {
  steps: number
  label?: string
  size?: "sm" | "default" | "lg"
}) {
  return (
    <div data-slot="step-count" data-size={size} className={cn("group/steps flex flex-col", className)} {...props}>
      <span className="font-display font-semibold tabular-nums tracking-tight text-2xl group-data-[size=sm]/steps:text-base group-data-[size=lg]/steps:text-5xl">
        {formatter.format(steps)}
      </span>
      {label ? <span className="text-muted-foreground text-xs font-medium uppercase tracking-wide">{label}</span> : null}
    </div>
  )
}

export { StepCount }
