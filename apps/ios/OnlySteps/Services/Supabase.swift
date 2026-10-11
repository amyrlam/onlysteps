import Foundation
import Supabase

/// The app's single Supabase client. The session (tokens) is stored in the
/// Keychain by the SDK and refreshed automatically.
let supabase = SupabaseClient(
    supabaseURL: AppConfig.supabaseURL,
    supabaseKey: AppConfig.supabaseAnonKey,
    options: SupabaseClientOptions(
        auth: .init(emitLocalSessionAsInitialSession: true)
    )
)
