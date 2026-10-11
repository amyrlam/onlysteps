import Foundation

/// Invite links look like `https://onlysteps.app/join/<code>`.
/// The custom scheme `onlysteps://join/<code>` is accepted too (handy for testing).
enum InviteLink {
    static func url(for code: String, base: URL) -> URL {
        base.appending(path: "join").appending(path: code)
    }

    /// The invite code in a link, or nil if the link is not an invite.
    static func code(from url: URL) -> String? {
        var parts = url.pathComponents.filter { $0 != "/" }
        let isWeb = url.scheme == "https" || url.scheme == "http"
        if !isWeb, let host = url.host(), !host.isEmpty {
            parts.insert(host, at: 0)
        }
        guard parts.count >= 2, parts[0] == "join" else { return nil }
        let code = clean(parts[1])
        return code.isEmpty ? nil : code
    }

    /// Turns whatever someone typed or pasted (a bare code or a full link)
    /// into a code.
    static func normalize(_ input: String) -> String {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.contains("/"), let url = URL(string: trimmed), let code = code(from: url) {
            return code
        }
        return clean(trimmed)
    }

    private static func clean(_ code: String) -> String {
        code.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}
