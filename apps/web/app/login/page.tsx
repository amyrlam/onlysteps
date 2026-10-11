import type { Metadata } from "next"
import { APP_NAME } from "@/lib/brand"
import { LoginForm } from "./login-form"

export const metadata: Metadata = { title: "Sign in" }

export default async function LoginPage({ searchParams }: { searchParams: Promise<{ next?: string; error?: string }> }) {
  const { next, error } = await searchParams
  return (
    <main className="flex min-h-dvh items-center justify-center px-6">
      <div className="flex w-full max-w-sm flex-col gap-6">
        <div className="flex flex-col gap-1 text-center">
          <h1 className="text-3xl font-semibold">Sign in to {APP_NAME}</h1>
          <p className="text-muted-foreground text-sm">Use the same account as the iPhone app so your steps show up.</p>
        </div>
        {error ? <p className="text-destructive text-center text-sm">Sign-in failed. Please try again.</p> : null}
        <LoginForm next={next?.startsWith("/") && !next.startsWith("//") ? next : "/groups"} />
      </div>
    </main>
  )
}
