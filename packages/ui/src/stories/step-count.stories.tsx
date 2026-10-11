import type { Meta, StoryObj } from "@storybook/react-vite"
import { StepCount } from "../components/step-count"

const meta = {
  title: "OnlySteps/StepCount",
  component: StepCount,
  args: { steps: 12408, label: "Today" },
  argTypes: { size: { control: "inline-radio", options: ["sm", "default", "lg"] } },
} satisfies Meta<typeof StepCount>

export default meta
type Story = StoryObj<typeof meta>

export const Default: Story = {}
export const Large: Story = { args: { size: "lg", steps: 71388, label: "This week" } }
export const Small: Story = { args: { size: "sm" } }
