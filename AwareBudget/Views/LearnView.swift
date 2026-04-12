import SwiftUI

struct LearnView: View {
    @State private var allLessons: [BiasLesson] = []
    @State private var selectedCategory: String = "All"
    @State private var currentIndex: Int = 0
    @State private var dragOffset: CGSize = .zero

    private let categories: [String] = [
        "All",
        "Avoidance",
        "Decision Making",
        "Money Psychology",
        "Time Perception",
        "External Influence",
        "Self Perception",
        "Inertia"
    ]

    private let frontBorder = DS.accent.opacity(0.25)
    private let middleBg = Color(hex: "C8E6C9")
    private let backBg   = Color(hex: "A5D6A7")

    private var filteredLessons: [BiasLesson] {
        guard selectedCategory != "All" else { return allLessons }
        return allLessons.filter { $0.category == selectedCategory }
    }

    var body: some View {
        ZStack {
            DS.bg.ignoresSafeArea()
            VStack(spacing: 20) {
                header
                filterPillRow
                Spacer(minLength: 0)
                if filteredLessons.isEmpty {
                    emptyState
                } else {
                    cardStack
                }
                Spacer(minLength: 0)
                if filteredLessons.count > 1 {
                    dotIndicator
                        .padding(.bottom, 24)
                }
            }
            .padding(.top, 8)
        }
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if allLessons.isEmpty {
                allLessons = BiasLessonsMock.seed
            }
        }
        .onChange(of: selectedCategory) { _, _ in
            currentIndex = 0
            dragOffset = .zero
        }
        .navigationDestination(for: BiasLesson.self) { lesson in
            BiasDetailView(lesson: lesson)
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Understanding your money mind")
                .font(.title2.weight(.bold))
                .foregroundStyle(DS.textPrimary)
            Text("Swipe through biases. Learn one. Notice it tomorrow.")
                .font(.subheadline)
                .foregroundStyle(DS.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, DS.hPadding)
    }

    // MARK: - Filter pills

    private var filterPillRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(categories, id: \.self) { cat in
                    filterPill(cat)
                }
            }
            .padding(.horizontal, DS.hPadding)
        }
    }

    private func filterPill(_ cat: String) -> some View {
        let selected = selectedCategory == cat
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedCategory = cat
            }
        } label: {
            Text(cat)
                .font(.footnote.weight(.semibold))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule().fill(selected ? DS.primary : DS.cardBg)
                )
                .foregroundStyle(selected ? .white : DS.textPrimary)
                .overlay(
                    Capsule().stroke(selected ? .clear : DS.accent, lineWidth: 0.5)
                )
        }
        .buttonStyle(.plain)
    }

    // Category tile colours per PRD v1.1
    static func categoryColour(for category: String) -> (bg: Color, text: Color) {
        switch category {
        case "Avoidance":
            return (Color(hex: "E1F5EE"), Color(hex: "085041"))
        case "Decision Making":
            return (Color(hex: "E8F5E9"), Color(hex: "2E7D32"))
        case "Money Psychology":
            return (Color(hex: "FAEEDA"), Color(hex: "412402"))
        case "Time Perception":
            return (Color(hex: "F3E5F5"), Color(hex: "4A148C"))
        case "External Influence":
            return (Color(hex: "FAECE7"), Color(hex: "4A1B0C"))
        case "Self Perception":
            return (Color(hex: "E0F7FA"), Color(hex: "006064"))
        case "Inertia":
            return (Color(hex: "FBE9E7"), Color(hex: "BF360C"))
        default:
            return (DS.paleGreen, DS.primary)
        }
    }

    // MARK: - Card stack

    private var cardStack: some View {
        ZStack {
            if currentIndex + 2 < filteredLessons.count {
                cardBase(fill: backBg, border: false)
                    .scaleEffect(0.92)
                    .offset(y: 24)
            }
            if currentIndex + 1 < filteredLessons.count {
                cardBase(fill: middleBg, border: false)
                    .scaleEffect(0.96)
                    .offset(y: 12)
            }
            if currentIndex < filteredLessons.count {
                frontCard(filteredLessons[currentIndex])
                    .offset(x: dragOffset.width)
                    .rotationEffect(.degrees(Double(dragOffset.width / 30)))
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                dragOffset = CGSize(width: value.translation.width, height: 0)
                            }
                            .onEnded { value in
                                if value.translation.width < -80 {
                                    advance(direction: -1)
                                } else if value.translation.width > 80 {
                                    advance(direction: 1)
                                } else {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                        dragOffset = .zero
                                    }
                                }
                            }
                    )
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 540)
        .padding(.horizontal, DS.hPadding)
    }

    private func cardBase(fill: Color, border: Bool) -> some View {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .fill(fill)
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(border ? frontBorder : .clear, lineWidth: 0.5)
            )
    }

    private func frontCard(_ lesson: BiasLesson) -> some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(DS.cardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(frontBorder, lineWidth: 0.5)
                )

            VStack(alignment: .leading, spacing: 14) {
                Text(lesson.emoji)
                    .font(.system(size: 48))

                HStack(spacing: 8) {
                    categoryPill(lesson.category)
                    seenBadge
                }

                Text(lesson.biasName)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(DS.primary)

                Text(lesson.shortDescription)
                    .font(.body)
                    .foregroundStyle(DS.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                Divider().padding(.vertical, 2)

                Text("IN REAL LIFE")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(DS.accent)
                    .tracking(0.8)

                Text(lesson.realWorldExample)
                    .font(.footnote)
                    .foregroundStyle(DS.textSecondary)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(DS.paleGreen)
                    )
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)

                NavigationLink(value: lesson) {
                    HStack {
                        Text("How to counter it")
                            .font(.subheadline.weight(.semibold))
                        Spacer()
                        Image(systemName: "arrow.right")
                            .font(.subheadline.weight(.bold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 14)
                    .background(DS.primary, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            .padding(22)
        }
    }

    private func categoryPill(_ cat: String) -> some View {
        let colours = Self.categoryColour(for: cat)
        return Text(cat)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Capsule().fill(colours.bg))
            .foregroundStyle(colours.text)
    }

    private var seenBadge: some View {
        Text("Seen 0 times")
            .font(.caption.weight(.medium))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Capsule().fill(DS.paleGreen))
            .foregroundStyle(DS.textSecondary)
    }

    // MARK: - Dot indicator

    private var dotIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<filteredLessons.count, id: \.self) { i in
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        currentIndex = i
                        dragOffset = .zero
                    }
                } label: {
                    Circle()
                        .fill(i == currentIndex ? DS.primary : DS.textTertiary.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "sparkles")
                .font(.largeTitle)
                .foregroundStyle(DS.textTertiary)
            Text("No biases in this category yet")
                .font(.subheadline)
                .foregroundStyle(DS.textSecondary)
        }
        .padding(32)
    }

    // MARK: - Actions

    private func advance(direction: Int) {
        withAnimation(.easeOut(duration: 0.25)) {
            dragOffset = CGSize(width: CGFloat(direction) * -600, height: 0)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            if direction > 0 {
                currentIndex = (currentIndex + 1) % max(filteredLessons.count, 1)
            } else {
                currentIndex = (currentIndex - 1 + filteredLessons.count) % max(filteredLessons.count, 1)
            }
            dragOffset = .zero
        }
    }
}

#Preview {
    NavigationStack { LearnView() }
}
