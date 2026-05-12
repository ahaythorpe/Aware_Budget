import Foundation

/// App-wide constants that change between launch / pre-launch / dev builds.
/// Keep URLs and contact strings here — both SettingsView and the paywall
/// read from this single source of truth.
///
/// **Update before App Store submission:**
///   - `privacyPolicyURL` — replace placeholder with the live Notion /
///     GitHub Pages URL once Bella publishes the Privacy Policy.
///   - `supportEmail` — replace placeholder with the actual support
///     inbox you'll monitor for refund / help requests.
enum AppConfig {

    /// GoldMind Terms of Service hosted on the marketing site. Covers
    /// auto-renewable subscription disclosure (Apple 3.1.2(a)), AFSL
    /// disclaimer, refund policy, governing law (Victoria, AU).
    static let termsOfServiceURL = URL(string:
        "https://mygoldmind.vercel.app/terms"
    )!

    /// GoldMind Privacy Policy hosted on the marketing site. Privacy Act
    /// 1988 (Cth) + Australian Privacy Principles compliant.
    static let privacyPolicyURL = URL(string:
        "https://mygoldmind.vercel.app/privacy"
    )!

    /// Inbox monitored for App Store / refund inquiries / accessibility
    /// feedback. Set to Bella's personal hotmail for launch — swap to
    /// `support@goldmind.app` once a custom domain is set up post-launch
    /// (one-line change, no migrations needed).
    static let supportEmail = "ahaythorpe@gmail.com"

    /// Used by the Support section to compose a pre-filled email.
    /// Includes app version + build for easier triage.
    static var supportMailtoURL: URL {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let build   = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        let subject = "GoldMind support: v\(version) (\(build))"
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return URL(string: "mailto:\(supportEmail)?subject=\(subject)")!
    }
}
