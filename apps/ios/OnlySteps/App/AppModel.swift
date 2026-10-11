import Foundation
import Observation
import Supabase

enum AppTab: Hashable {
    case groups, you
}

/// App-wide state: who is signed in, their profile, and navigation that can
/// be triggered from outside (invite links).
@MainActor
@Observable
final class AppModel {
    enum AuthState: Equatable {
        case loading
        case signedOut
        case signedIn(UUID)
    }

    private(set) var authState: AuthState = .loading
    private(set) var profile: Profile?
    var signInError: String?
    var selectedTab: AppTab = .groups
    /// Set when an invite link is opened; the Groups screen consumes it.
    var pendingInviteCode: String?

    private var preparedUserID: UUID?
    private static let profileColumns = "id, display_name, avatar_url, time_zone"

    var userID: UUID? {
        if case .signedIn(let id) = authState { id } else { nil }
    }

    /// Follows the Supabase session for the life of the app.
    func observeAuth() async {
        for await change in supabase.auth.authStateChanges {
            if let session = change.session {
                authState = .signedIn(session.user.id)
                prepare(for: session.user.id)
            } else {
                authState = .signedOut
                profile = nil
                preparedUserID = nil
            }
        }
    }

    func signInWithApple(idToken: String, nonce: String, fullName: PersonNameComponents?) async {
        signInError = nil
        do {
            let session = try await supabase.auth.signInWithIdToken(
                credentials: OpenIDConnectCredentials(provider: .apple, idToken: idToken, nonce: nonce)
            )
            // Apple only shares the name on the very first sign-in.
            let name = [fullName?.givenName, fullName?.familyName]
                .compactMap { $0 }
                .joined(separator: " ")
                .trimmingCharacters(in: .whitespaces)
            if !name.isEmpty {
                await updateProfile(userID: session.user.id, ProfileUpdate(displayName: String(name.prefix(40))))
            }
        } catch {
            signInError = error.localizedDescription
        }
    }

    func signOut() async {
        do {
            try await supabase.auth.signOut()
        } catch {
            signInError = error.localizedDescription
        }
    }

    func handle(url: URL) {
        guard let code = InviteLink.code(from: url) else { return }
        pendingInviteCode = code
        selectedTab = .groups
    }

    func syncStepsIfSignedIn() {
        guard userID != nil else { return }
        Task { await StepSync.shared.syncRecentDays() }
    }

    // MARK: - Private

    /// One-time work after sign-in: load the profile, record the time zone,
    /// and start step syncing.
    private func prepare(for userID: UUID) {
        guard preparedUserID != userID else { return }
        preparedUserID = userID
        Task {
            await loadProfile(userID: userID)
            let zone = TimeZone.current.identifier
            if profile?.timeZone != zone {
                await updateProfile(userID: userID, ProfileUpdate(timeZone: zone))
            }
            await StepSync.shared.activate()
        }
    }

    private func loadProfile(userID: UUID) async {
        do {
            let loaded: Profile = try await supabase
                .from("profiles")
                .select(Self.profileColumns)
                .eq("id", value: userID.uuidString)
                .single()
                .execute()
                .value
            profile = loaded
        } catch {
            print("Loading profile failed: \(error)")
        }
    }

    private func updateProfile(userID: UUID, _ update: ProfileUpdate) async {
        do {
            let updated: Profile = try await supabase
                .from("profiles")
                .update(update)
                .eq("id", value: userID.uuidString)
                .select(Self.profileColumns)
                .single()
                .execute()
                .value
            profile = updated
        } catch {
            print("Updating profile failed: \(error)")
        }
    }
}
