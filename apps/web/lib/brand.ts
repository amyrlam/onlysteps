// The product name isn't final, so every user-facing mention reads from here.
export const APP_NAME = process.env.NEXT_PUBLIC_APP_NAME ?? "OnlySteps"
// Vercel sets NEXT_PUBLIC_VERCEL_URL on every deployment, so preview links
// point at the preview itself unless NEXT_PUBLIC_SITE_URL overrides it.
export const SITE_URL =
  process.env.NEXT_PUBLIC_SITE_URL ??
  (process.env.NEXT_PUBLIC_VERCEL_URL ? `https://${process.env.NEXT_PUBLIC_VERCEL_URL}` : "http://localhost:3000")
