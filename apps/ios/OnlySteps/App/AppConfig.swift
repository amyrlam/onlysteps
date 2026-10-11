import Foundation

/// Values that come from the build settings in Config/Base.xcconfig,
/// passed through Info.plist. This is the one place the app reads them.
enum AppConfig {
    /// The product name shown to people. Set by `APP_DISPLAY_NAME`.
    static let displayName: String = string("CFBundleDisplayName", fallback: "OnlySteps")

    static let supabaseURL: URL = url("SupabaseURL")
    static let supabaseAnonKey: String = string("SupabaseAnonKey", fallback: "")

    /// Website that serves invite links, e.g. https://onlysteps.app
    static let webBaseURL: URL = url("WebBaseURL")

    static func inviteURL(code: String) -> URL {
        InviteLink.url(for: code, base: webBaseURL)
    }

    private static func string(_ key: String, fallback: String) -> String {
        let value = Bundle.main.object(forInfoDictionaryKey: key) as? String
        guard let value, !value.isEmpty else { return fallback }
        return value
    }

    private static func url(_ key: String) -> URL {
        let raw = string(key, fallback: "")
        guard let url = URL(string: raw), url.scheme != nil else {
            fatalError("Info.plist key \(key) is missing or not a URL (\"\(raw)\"). Check Config/Secrets.xcconfig.")
        }
        return url
    }
}
