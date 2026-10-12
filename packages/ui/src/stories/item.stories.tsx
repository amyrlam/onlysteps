import type { Meta, StoryObj } from "@storybook/react-vite"
import { Avatar, AvatarFallback } from "../components/avatar"
import { Badge } from "../components/badge"
import { Button } from "../components/button"
import { Item, ItemActions, ItemContent, ItemDescription, ItemGroup, ItemMedia, ItemTitle } from "../components/item"

const meta = {
  title: "Components/Item",
  component: Item,
} satisfies Meta<typeof Item>

export default meta
type Story = StoryObj<typeof meta>

export const RemovedMembers: Story = {
  render: () => (
    <ItemGroup className="w-[28rem] gap-2">
      <Item variant="outline" size="sm">
        <ItemMedia>
          <Avatar>
            <AvatarFallback>SK</AvatarFallback>
          </Avatar>
        </ItemMedia>
        <ItemContent>
          <ItemTitle>
            Sam Kim <Badge variant="secondary">Wants to rejoin</Badge>
          </ItemTitle>
          <ItemDescription>Asked Oct 11</ItemDescription>
        </ItemContent>
        <ItemActions>
          <Button size="sm" variant="outline">
            Dismiss
          </Button>
          <Button size="sm">Approve</Button>
        </ItemActions>
      </Item>
      <Item variant="outline" size="sm">
        <ItemMedia>
          <Avatar>
            <AvatarFallback>JR</AvatarFallback>
          </Avatar>
        </ItemMedia>
        <ItemContent>
          <ItemTitle>Jo Rivera</ItemTitle>
          <ItemDescription>Removed Oct 4</ItemDescription>
        </ItemContent>
        <ItemActions>
          <Button size="sm" variant="outline">
            Allow back
          </Button>
        </ItemActions>
      </Item>
    </ItemGroup>
  ),
}
