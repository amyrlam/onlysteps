# @onlysteps/ui

Web design system for OnlySteps. Components in `src/components` are [shadcn/ui](https://ui.shadcn.com) (MIT) components built on [Base UI](https://base-ui.com) in the Nova style, plus OnlySteps components (`leaderboard`, `step-count`). Colors, radii and fonts come from `@onlysteps/tokens`.

- `pnpm storybook` runs Storybook on port 6006; toggle light/dark from the toolbar.
- To add a shadcn component, use the Base UI variant from the shadcn registry and import `cn` from `../lib/utils`.
