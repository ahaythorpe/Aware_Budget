import SwiftUI

/// Reusable circular avatar for the user. Renders the user's uploaded
/// photo when `avatarUrl` is non-nil; falls back to the first letter of
/// their display name inside a gold gradient disc otherwise.
///
/// Sized via the `size` parameter. The font scales with the disc.
/// Falls back to "?" when no name is set.
struct AvatarDisc: View {
    var name: String?
    var avatarUrl: String? = nil
    var size: CGFloat = 44
    /// When true, draws a soft gold ring around the disc. Use on tap
    /// affordances to signal "this is interactive."
    var ring: Bool = true

    private var initial: String {
        let trimmed = (name ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard let first = trimmed.first else { return "?" }
        return String(first).uppercased()
    }

    private var photoURL: URL? {
        guard let s = avatarUrl,
              !s.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else { return nil }
        return URL(string: s)
    }

    var body: some View {
        ZStack {
            if let url = photoURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    default:
                        initialDisc
                    }
                }
                .clipShape(Circle())
            } else {
                initialDisc
            }
            if ring {
                Circle()
                    .stroke(DS.goldBase.opacity(0.55), lineWidth: 1)
            }
        }
        .frame(width: size, height: size)
        .shadow(color: Color(hex: "5C3A0A").opacity(0.18), radius: 4, y: 2)
        .accessibilityLabel(Text("Profile, \(name ?? "no name set")"))
    }

    /// Gold-gradient initial-letter disc, used as the default and as the
    /// AsyncImage placeholder/failure fallback.
    private var initialDisc: some View {
        ZStack {
            Circle()
                .fill(DS.nuggetGold)
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.25), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            Text(initial)
                .font(.system(size: size * 0.46, weight: .black, design: .serif))
                .foregroundStyle(.white)
                .shadow(color: Color(hex: "3A2400").opacity(0.45), radius: 1, y: 1)
        }
    }
}

#Preview {
    HStack(spacing: 16) {
        AvatarDisc(name: "Arabella", size: 64)
        AvatarDisc(name: "Sanjay", size: 44)
        AvatarDisc(name: nil, size: 32, ring: false)
    }
    .padding()
    .background(DS.bg)
}
