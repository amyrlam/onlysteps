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

extension PostgrestBuilder {
    /// Runs the request and decodes the result without leaving the SDK's
    /// non-Sendable response type in the caller's actor. Swift 6 rejects
    /// `try await query.execute().value` from @MainActor code because the
    /// response object would cross actors; only the Sendable value does here.
    nonisolated func fetchValue<T: Decodable & Sendable>(as type: T.Type = T.self) async throws -> T {
        try await execute().value
    }
}
