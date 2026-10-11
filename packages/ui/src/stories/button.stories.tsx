import type { Meta, StoryObj } from "@storybook/react-vite"
import { PlusIcon } from "lucide-react"
import { Button } from "../components/button"

const meta = {
  title: "Components/Button",
  component: Button,
  args: { children: "Create group" },
  argTypes: {
    variant: { control: "select", options: ["default", "secondary", "outline", "ghost", "destructive", "link"] },
    size: { control: "select", options: ["xs", "sm", "default", "lg"] },
  },
} satisfies Meta<typeof Button>

export default meta
type Story = StoryObj<typeof meta>

export const Default: Story = {}
export const Secondary: Story = { args: { variant: "secondary" } }
export const Outline: Story = { args: { variant: "outline" } }
export const Ghost: Story = { args: { variant: "ghost" } }
export const Destructive: Story = { args: { variant: "destructive", children: "Leave group" } }
export const WithIcon: Story = {
  args: {
    children: (
      <>
        <PlusIcon data-icon="inline-start" /> New group
      </>
    ),
  },
}
export const Disabled: Story = { args: { disabled: true } }
