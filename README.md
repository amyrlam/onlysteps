# OnlySteps

Step competitions with your friends: an open-source, ad-free alternative to StepUp. Your iPhone counts the steps, groups compete on a weekly leaderboard, and the winner gets posted to Slack every Monday morning.

> The name isn't final. It lives in one setting per app (`NEXT_PUBLIC_APP_NAME`, `APP_DISPLAY_NAME`, `APP_NAME`) so renaming is cheap.

## How it fits together

```
iPhone app (SwiftUI)  ── reads steps from Apple Health ──┐
                                                          ▼
Web app (Next.js)  ◀── groups, leaderboards ──▶  Supabase (Postgres + Auth)
                                                          │
                                   pg_cron, hourly ──▶ weekly-winner Edge Function ──▶ Slack webhook
```

A browser can't read Apple Health, so steps always come from the iPhone app. The web app is for signing in, managing groups, invites, and Slack settings, and viewing leaderboards.

| Path | What it is |
| --- | --- |
| `packages/tokens` | Design tokens in the [Design Tokens Community Group format](https://www.designtokens.org/tr/2025.10/format/) (2025.10). Built with Style Dictionary into CSS variables for web and `Tokens.swift` for iOS. |
| `packages/ui` | Web design system: shadcn/ui components on [Base UI](https://base-ui.com), themed by the tokens, documented in Storybook. |
| `apps/web` | Next.js app (App Router, Tailwind v4, Supabase auth). |
| `apps/ios` | SwiftUI app with HealthKit step sync. See [apps/ios/README.md](apps/ios/README.md). |
| `supabase` | Database migrations (schema, row level security, leaderboard function) and the `weekly-winner` Edge Function. |

## Getting started (web)

Prerequisites: Node 22, pnpm 10 (`corepack enable`), Docker (for local Supabase).

```sh
pnpm install
pnpm tokens                 # build design tokens
pnpm dlx supabase start     # local Postgres, Auth, and Studio; prints the anon key
cp apps/web/.env.example apps/web/.env.local   # paste the anon key
pnpm dev                    # http://localhost:3000
pnpm storybook              # http://localhost:6006
```

Local sign-in emails land in the Supabase mail viewer that `supabase start` prints (Mailpit).

## Design tokens

Edit the JSON in `packages/tokens/tokens/`, then run `pnpm tokens`. Semantic color names match shadcn's CSS variables (`--primary`, `--muted-foreground`, …), so shadcn components pick them up unchanged. Commit the regenerated `apps/ios/OnlySteps/DesignSystem/Tokens.swift`; CI fails if it is stale.

## Slack weekly winner

Each group owner can paste a Slack incoming webhook URL on the group page and pick the day and hour (default Monday 9am in the group's time zone). An hourly cron job calls the `weekly-winner` function, which posts last week's leaderboard for every group whose time has come and remembers the week it announced. There's also a "Send test post" button.

To enable it on a hosted Supabase project, see the comments in `supabase/migrations/*_schedule_weekly_winner.sql`.

## License

[GPL-3.0](LICENSE). Components in `packages/ui/src/components` start from [shadcn/ui](https://github.com/shadcn-ui/ui) (MIT).
