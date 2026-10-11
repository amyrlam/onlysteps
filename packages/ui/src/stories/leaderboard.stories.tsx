import type { Meta, StoryObj } from "@storybook/react-vite"
import { Leaderboard } from "../components/leaderboard"

const entries = [
  { userId: "1", name: "Priya Shah", steps: 84210, rank: 1 },
  { userId: "2", name: "Amy Lam", steps: 71388, rank: 2 },
  { userId: "3", name: "Jordan Lee", steps: 65002, rank: 3 },
  { userId: "4", name: "Sam Ortiz", steps: 40119, rank: 4 },
  { userId: "5", name: "Alex Kim", steps: 0, rank: 5 },
]

const meta = {
  title: "OnlySteps/Leaderboard",
  component: Leaderboard,
  args: { entries, currentUserId: "2" },
  decorators: [(Story) => <div className="w-96"><Story /></div>],
} satisfies Meta<typeof Leaderboard>

export default meta
type Story = StoryObj<typeof meta>

export const Default: Story = {}
export const Tie: Story = {
  args: {
    entries: [
      { userId: "1", name: "Priya Shah", steps: 50000, rank: 1 },
      { userId: "2", name: "Amy Lam", steps: 50000, rank: 1 },
      { userId: "3", name: "Jordan Lee", steps: 12000, rank: 3 },
    ],
  },
}
export const Empty: Story = { args: { entries: [] } }
