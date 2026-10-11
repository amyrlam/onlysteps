import type { Meta, StoryObj } from "@storybook/react-vite"
import { Button } from "../components/button"
import { Field, FieldDescription, FieldLabel } from "../components/field"
import { Input } from "../components/input"
import { Switch } from "../components/switch"

const meta = {
  title: "Components/Form",
} satisfies Meta

export default meta
type Story = StoryObj<typeof meta>

export const SlackSettings: Story = {
  render: () => (
    <form className="flex w-96 flex-col gap-5" onSubmit={(e) => e.preventDefault()}>
      <Field>
        <FieldLabel htmlFor="webhook">Slack webhook URL</FieldLabel>
        <Input id="webhook" placeholder="https://hooks.slack.com/services/…" />
        <FieldDescription>Create an incoming webhook in Slack and paste it here.</FieldDescription>
      </Field>
      <Field orientation="horizontal">
        <Switch id="enabled" defaultChecked />
        <FieldLabel htmlFor="enabled">Post the weekly winner every Monday at 9am</FieldLabel>
      </Field>
      <Button type="submit">Save</Button>
    </form>
  ),
}
