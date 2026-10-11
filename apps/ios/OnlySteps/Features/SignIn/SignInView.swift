import AuthenticationServices
import SwiftUI

struct SignInView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.colorScheme) private var colorScheme
    @State private var nonce: String?

    var body: some View {
        VStack(spacing: OSSpace._6) {
            Spacer()

            Image(systemName: "figure.walk.circle.fill")
                .font(.system(size: 88))
                .foregroundStyle(OSColor.primary)
            VStack(spacing: OSSpace._2) {
                Text(AppConfig.displayName)
                    .font(.largeTitle.bold())
                Text("Weekly step competitions with friends.")
                    .font(.body)
                    .foregroundStyle(OSColor.mutedForeground)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            if app.pendingInviteCode != nil {
                Text("Sign in to join the group you were invited to.")
                    .font(.footnote)
                    .foregroundStyle(OSColor.accentForeground)
                    .padding(OSSpace._3)
                    .frame(maxWidth: .infinity)
                    .background(OSColor.accent, in: RoundedRectangle(cornerRadius: OSRadius.md))
            }

            SignInWithAppleButton(.signIn) { request in
                let raw = AppleNonce.random()
                nonce = raw
                request.requestedScopes = [.fullName]
                request.nonce = AppleNonce.sha256(raw)
            } onCompletion: { result in
                handle(result)
            }
            .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
            .frame(height: 50)
            .clipShape(RoundedRectangle(cornerRadius: OSRadius.md, style: .continuous))

            if let error = app.signInError {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(OSColor.destructive)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(OSSpace._6)
        .foregroundStyle(OSColor.foreground)
        .background(OSColor.background)
    }

    private func handle(_ result: Result<ASAuthorization, any Error>) {
        switch result {
        case .failure(let error):
            if (error as? ASAuthorizationError)?.code == .canceled { return }
            app.signInError = error.localizedDescription
        case .success(let authorization):
            guard
                let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                let tokenData = credential.identityToken,
                let idToken = String(data: tokenData, encoding: .utf8),
                let nonce
            else {
                app.signInError = "Sign in with Apple did not return a valid token."
                return
            }
            let fullName = credential.fullName
            Task { await app.signInWithApple(idToken: idToken, nonce: nonce, fullName: fullName) }
        }
    }
}
