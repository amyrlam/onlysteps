# OnlySteps

pnpm monorepo: `packages/tokens` (DTCG tokens, Style Dictionary), `packages/ui` (shadcn on Base UI + Storybook), `apps/web` (Next.js 16), `apps/ios` (SwiftUI, XcodeGen), `supabase` (migrations, Edge Functions).

- Product name is not final: never hard-code it; use `APP_NAME` (web), `AppConfig.displayName` (iOS), `APP_NAME` env (functions).
- Tokens: edit `packages/tokens/tokens/*.tokens.json` (DTCG 2025.10), run `pnpm tokens`, commit `Tokens.swift`.
- Web UI uses components from `@onlysteps/ui`; add new shadcn components there (Base UI variant), not in `apps/web`.
- `supabase/functions/_shared` must stay runtime-neutral (imported by both Deno and Next.js).
- Checks: `pnpm --filter @onlysteps/tokens test`, `pnpm --filter @onlysteps/functions test`, `pnpm --filter @onlysteps/ui typecheck`, `pnpm --filter @onlysteps/web build`. iOS is built in CI on macOS.
