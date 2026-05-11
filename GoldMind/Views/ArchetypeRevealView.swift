import SwiftUI

/// Shown after the Money Mind Quiz completes. Reveals the user's archetype
/// with a soft fade-in, then lists the top biases they're likely prone to.
///
/// Per the canonical framework (project_goldmind_archetypes.md): archetype
/// is the SURFACE label, biases are the DEEP data. Citation footer credits
/// Klontz, Pompian, and the underlying BFAS bias canon.
struct ArchetypeRevealView: View {
    let archetype: Archetype
    let scores: [Archetype: Int]
    var onDone: () -> Void = {}

    @Environment(\.dismiss) private var dismiss
    @State private var revealed: Bool = false

    private var topBiasPatterns: [BiasPattern] {
        let names = Set(archetype.topBiasNames)
        return allBiasPatterns.filter { names.contains($0.name) }
    }

    var body: some View {
        ZStack {
            DS.bg.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    heroCard
                    biasesSection
                    citationFooter
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 32)
                .opacity(revealed ? 1.0 : 0.0)
                .offset(y: revealed ? 0 : 12)
                .animation(.easeOut(duration: 0.55), value: revealed)
            }
            VStack {
                Spacer()
                doneButton
            }
        }
        .onAppear {
            revealed = true
        }
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: archetype.sfSymbol)
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(.white)
                Text("YOUR ARCHETYPE")
                    .font(.system(size: 12, weight: .heavy))
                    .tracking(1.5)
                    .foregroundStyle(.white.opacity(0.85))
                Spacer()
            }
            Text(archetype.displayName)
                .font(.system(size: 36, weight: .black, design: .serif))
                .foregroundStyle(.white)
            Text(archetype.oneLiner)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(.white.opacity(0.92))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(DS.heroGradient)
        )
        .shadow(color: .black.opacity(0.12), radius: 16, y: 6)
    }

    private var biasesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("YOU'RE LIKELY PRONE TO")
                .font(.system(size: 12, weight: .heavy))
                .tracking(1.5)
                .foregroundStyle(DS.accent)
            ForEach(topBiasPatterns) { p in
                biasRow(p)
            }
            if topBiasPatterns.isEmpty {
                Text("Awareness of the underlying patterns is most of the work.")
                    .font(.system(size: 14))
                    .foregroundStyle(DS.textSecondary)
            }
        }
    }

    private func biasRow(_ p: BiasPattern) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color(hex: p.iconBg))
                Image(systemName: p.sfSymbol)
                    .foregroundStyle(Color(hex: p.iconColor))
                    .font(.system(size: 18, weight: .semibold))
            }
            .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(p.displayName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(DS.textPrimary)
                Text(p.oneLiner)
                    .font(.system(size: 13))
                    .foregroundStyle(DS.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(p.keyRef)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(DS.textSecondary.opacity(0.7))
                    .padding(.top, 2)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(DS.cardBg)
                .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
        )
    }

    private var citationFooter: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("ABOUT THIS ASSESSMENT")
                .font(.system(size: 11, weight: .heavy))
                .tracking(1.4)
                .foregroundStyle(DS.textSecondary)
            Text("Based on the BFAS framework (Pompian, 2012) with archetype mapping drawn from Klontz & Britt's Money Scripts (2011), Pompian's Behavioral Investor Types (2012), and underlying research (Kahneman & Tversky 1974, 1979; Thaler 1985; Laibson 1997; Samuelson & Zeckhauser 1988; Banerjee 1992; Galai & Sade 2006).")
                .font(.system(size: 11))
                .foregroundStyle(DS.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 8)
    }

    private var doneButton: some View {
        Button {
            onDone()
            dismiss()
        } label: {
            Text("Take me to my Education")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(DS.heroGradient)
                )
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 24)
        .background(
            LinearGradient(colors: [DS.bg.opacity(0), DS.bg], startPoint: .top, endPoint: .center)
        )
    }
}

#Preview {
    ArchetypeRevealView(archetype: .reactor, scores: [.reactor: 6, .now: 3])
}
