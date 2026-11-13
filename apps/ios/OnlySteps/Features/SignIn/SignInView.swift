import AuthenticationServices
import SwiftUI

struct SignInView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.colorScheme) private var colorScheme
    @State private var nonce: String?
    @State private var email = ""
    @State private var code = ""
    /// The address the sign-in email went to; nil while asking for the email.
    @State private var codeSentTo: String?
    /// The email has a code only if the Supabase template includes one.
    @State private var showsCodeField = false
    @State private var isWorking = false
    @FocusState private var focus: Field?

    private enum Field { case email, code }

    private var trimmedEmail: String { email.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var trimmedCode: String { code.trimmingCharacters(in: .whitespacesAndNewlines) }

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

            VStack(spacing: OSSpace._3) {
                if AppConfig.appleSignInEnabled, codeSentTo == nil {
                    appleButton
                    Text("or")
                        .font(.footnote)
                        .foregroundStyle(OSColor.mutedForeground)
                }

                if let codeSentTo {
                    codeEntry(sentTo: codeSentTo)
                } else {
                    emailEntry
                }
            }

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

    private var appleButton: some View {
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
    }

    @ViewBuilder
    private var emailEntry: some View {
        TextField("Email", text: $email)
            .keyboardType(.emailAddress)
            .textContentType(.emailAddress)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .submitLabel(.go)
            .focused($focus, equals: .email)
            .onSubmit(sendCode)
            .modifier(FieldChrome())

        Button(isWorking ? "Sending…" : "Email me a sign-in link", action: sendCode)
            .buttonStyle(AppConfig.appleSignInEnabled ? .osSecondary : .osPrimary)
            .disabled(isWorking || !trimmedEmail.contains("@"))
    }

    @ViewBuilder
    private func codeEntry(sentTo: String) -> some View {
        VStack(spacing: OSSpace._2) {
            Image(systemName: "envelope.badge")
                .font(.title)
                .foregroundStyle(OSColor.primary)
            Text("Check your email")
                .font(.headline)
            Text("We sent a sign-in link to \(sentTo). Open it on this iPhone to finish signing in.")
                .font(.subheadline)
                .foregroundStyle(OSColor.mutedForeground)
                .multilineTextAlignment(.center)
        }

        if showsCodeField {
            TextField("Code", text: $code)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .font(.title3.monospacedDigit())
                .multilineTextAlignment(.center)
                .focused($focus, equals: .code)
                .modifier(FieldChrome())

            Button(isWorking ? "Signing in…" : "Sign in", action: verifyCode)
                .buttonStyle(.osPrimary)
                .disabled(isWorking || trimmedCode.count < 6)
        }

        HStack(spacing: OSSpace._4) {
            Button("Use a different email") {
                codeSentTo = nil
                code = ""
                showsCodeField = false
                app.signInError = nil
                focus = .email
            }
            if !showsCodeField {
                Button("Enter a code instead") {
                    showsCodeField = true
                    focus = .code
                }
            }
        }
        .font(.footnote)
        .foregroundStyle(OSColor.mutedForeground)
    }

    private func sendCode() {
        let address = trimmedEmail
        guard !isWorking, address.contains("@") else { return }
        isWorking = true
        Task {
            if await app.sendSignInCode(to: address) {
                codeSentTo = address
                focus = nil
            }
            isWorking = false
        }
    }

    private func verifyCode() {
        guard !isWorking, let codeSentTo else { return }
        isWorking = true
        Task {
            await app.signIn(email: codeSentTo, code: trimmedCode)
            isWorking = false
        }
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

/// The outline around the sign-in text fields.
private struct FieldChrome: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.vertical, OSSpace._3)
            .padding(.horizontal, OSSpace._4)
            .frame(minHeight: 50)
            .background(
                RoundedRectangle(cornerRadius: OSRadius.md, style: .continuous)
                    .strokeBorder(OSColor.input)
            )
    }
}

#Preview("Sign in") {
    SignInView()
        .environment(AppModel())
}
