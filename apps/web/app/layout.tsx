import type { Metadata, Viewport } from "next"
import { APP_NAME } from "@/lib/brand"
import "./globals.css"

export const metadata: Metadata = {
  title: { default: APP_NAME, template: `%s · ${APP_NAME}` },
  description: "Step competitions with your friends. Open source, no ads.",
}

export const viewport: Viewport = {
  themeColor: [
    { media: "(prefers-color-scheme: light)", color: "#ffffff" },
    { media: "(prefers-color-scheme: dark)", color: "#08090d" },
  ],
}

// Follows the system theme. Runs before paint to avoid a flash.
const themeScript = `(() => {
  const m = matchMedia("(prefers-color-scheme: dark)");
  const apply = () => document.documentElement.classList.toggle("dark", m.matches);
  apply(); m.addEventListener("change", apply);
})()`

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" suppressHydrationWarning>
      <head>
        <script dangerouslySetInnerHTML={{ __html: themeScript }} />
      </head>
      <body className="min-h-dvh">{children}</body>
    </html>
  )
}
