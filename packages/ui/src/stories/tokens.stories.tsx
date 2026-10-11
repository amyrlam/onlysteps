import type { Meta, StoryObj } from "@storybook/react-vite"
import tokens from "@onlysteps/tokens/tokens.json"

const semantic = Object.keys(tokens.light).filter((k) => k.startsWith("semantic."))
const scales = ["neutral", "green", "amber", "red", "violet", "sky"]

function Swatch({ name, cssVar }: { name: string; cssVar: string }) {
  return (
    <div className="flex items-center gap-3">
      <div className="size-10 rounded-md border" style={{ background: `var(${cssVar})` }} />
      <div className="text-sm">
        <div className="font-medium">{name}</div>
        <code className="text-muted-foreground text-xs">{cssVar}</code>
      </div>
    </div>
  )
}

const meta = {
  title: "Foundations/Tokens",
  parameters: { layout: "padded" },
} satisfies Meta

export default meta
type Story = StoryObj<typeof meta>

/** Semantic colors switch with the theme toolbar (light/dark). Source: packages/tokens/tokens/*.tokens.json (DTCG). */
export const SemanticColors: Story = {
  render: () => (
    <div className="grid grid-cols-2 gap-4 md:grid-cols-3">
      {semantic.map((k) => {
        const name = k.replace("semantic.", "")
        return <Swatch key={k} name={name} cssVar={`--${name}`} />
      })}
    </div>
  ),
}

export const Palette: Story = {
  render: () => (
    <div className="flex flex-col gap-4">
      {scales.map((scale) => {
        const steps = Object.entries(tokens.light).filter(([k]) => k.startsWith(`color.${scale}.`))
        return (
          <div key={scale}>
            <div className="mb-1 text-sm font-medium capitalize">{scale}</div>
            <div className="flex">
              {steps.map(([k, v]) => (
                <div key={k} title={`${k}: ${v}`} className="h-10 w-12 first:rounded-l-md last:rounded-r-md" style={{ background: v }} />
              ))}
            </div>
          </div>
        )
      })}
    </div>
  ),
}

export const Typography: Story = {
  render: () => (
    <div className="flex flex-col gap-3">
      <h1 className="text-4xl font-semibold">Display heading</h1>
      <p className="text-base">Body text in the sans family. 12,408 steps today.</p>
      <p className="text-muted-foreground text-sm">Muted helper text.</p>
      <code className="font-mono text-sm">mono: 0123456789</code>
    </div>
  ),
}
