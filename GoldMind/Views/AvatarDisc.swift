import SwiftUI

/// Reusable circular avatar for the user. Renders the user's uploaded
/// photo when `avatarUrl` is non-nil; falls back to the Nudge cut-out
/// coin otherwise. (Previously fell back to a gold initial-letter disc;
/// switched to Nudge so users see the mascot as their default profile
/// picture until they upload one — at which point Nudge moves to the
/// right corner of the greeting card.)
///
/// Sized via the `size` parameter.
struct AvatarDisc: View {
    var name: String?
    var avatarUrl: String? = nil
    var size: CGFloat = 44
    /// When true, draws a soft gold ring around the disc. Use on tap
    /// affordances to signal "this is interactive."
    var ring: Bool = true

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
                        nudgeFallback
                    }
                }
                .clipShape(Circle())
            } else {
                nudgeFallback
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

    /// Nudge cut-out used as the default and as the AsyncImage placeholder.
    /// The image is the same asset rendered elsewhere as a floating coin,
    /// so the avatar reads as "Nudge is standing in for your picture."
    private var nudgeFallback: some View {
        Image("nudge")
            .resizable()
            .scaledToFit()
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
