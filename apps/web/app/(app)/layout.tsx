import Link from "next/link"
import { Button } from "@onlysteps/ui/components/button"
import { APP_NAME } from "@/lib/brand"
import { signOut } from "../actions"

export default function AppLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="flex min-h-dvh flex-col">
      <header className="border-b">
        <div className="mx-auto flex h-14 max-w-3xl items-center justify-between px-4">
          <Link href="/groups" className="font-display text-lg font-semibold">
            {APP_NAME}
          </Link>
          <form action={signOut}>
            <Button variant="ghost" size="sm" type="submit">
              Sign out
            </Button>
          </form>
        </div>
      </header>
      <main className="mx-auto w-full max-w-3xl flex-1 px-4 py-8">{children}</main>
    </div>
  )
}
