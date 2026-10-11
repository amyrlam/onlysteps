import type { Meta, StoryObj } from "@storybook/react-vite"
import { Button } from "../components/button"
import {
  Dialog,
  DialogClose,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "../components/dialog"
import { Input } from "../components/input"

const meta = {
  title: "Components/Dialog",
} satisfies Meta

export default meta
type Story = StoryObj<typeof meta>

export const CreateGroup: Story = {
  render: () => (
    <Dialog>
      <DialogTrigger render={<Button />}>New group</DialogTrigger>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Create a group</DialogTitle>
          <DialogDescription>Give it a name. You can invite friends next.</DialogDescription>
        </DialogHeader>
        <Input aria-label="Group name" placeholder="Office walkers" />
        <DialogFooter>
          <DialogClose render={<Button variant="outline" />}>Cancel</DialogClose>
          <Button>Create</Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  ),
}
