import type { Meta, StoryObj } from "@storybook/react-vite"
import { Button } from "../components/button"
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from "../components/card"
import { StepCount } from "../components/step-count"

const meta = {
  title: "Components/Card",
  component: Card,
} satisfies Meta<typeof Card>

export default meta
type Story = StoryObj<typeof meta>

export const TodayStats: Story = {
  render: () => (
    <Card className="w-80">
      <CardHeader>
        <CardTitle>Today</CardTitle>
        <CardDescription>Synced from your iPhone 4 minutes ago</CardDescription>
      </CardHeader>
      <CardContent className="flex gap-8">
        <StepCount steps={8432} label="Today" size="lg" />
        <StepCount steps={41207} label="This week" />
      </CardContent>
      <CardFooter>
        <Button variant="outline" className="w-full">
          View groups
        </Button>
      </CardFooter>
    </Card>
  ),
}
