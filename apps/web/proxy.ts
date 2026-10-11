import { createServerClient } from "@supabase/ssr"
import { NextResponse, type NextRequest } from "next/server"

const PUBLIC_PATHS = ["/", "/login", "/auth", "/join"]

// Refreshes the Supabase session cookie on every request and sends
// signed-out visitors to /login for app pages.
export async function proxy(request: NextRequest) {
  let response = NextResponse.next({ request })
  const supabase = createServerClient(process.env.NEXT_PUBLIC_SUPABASE_URL!, process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!, {
    cookies: {
      getAll: () => request.cookies.getAll(),
      setAll: (toSet) => {
        toSet.forEach(({ name, value }) => request.cookies.set(name, value))
        response = NextResponse.next({ request })
        toSet.forEach(({ name, value, options }) => response.cookies.set(name, value, options))
      },
    },
  })

  const {
    data: { user },
  } = await supabase.auth.getUser()

  const path = request.nextUrl.pathname
  const isPublic = PUBLIC_PATHS.some((p) => path === p || (p !== "/" && path.startsWith(`${p}/`)))
  if (!user && !isPublic) {
    const url = request.nextUrl.clone()
    url.pathname = "/login"
    url.searchParams.set("next", path)
    return NextResponse.redirect(url)
  }
  return response
}

export const config = {
  matcher: ["/((?!_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)"],
}
