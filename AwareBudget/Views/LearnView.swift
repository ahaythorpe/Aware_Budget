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
    private let backBg = Color(hex: "C8E6C9")
    private let cardHeight: CGFloat = 340

    private var filteredLessons: [BiasLesson] {
        guard selectedCategory != "All" else { return allLessons }
        return allLessons.filter { $0.category == selectedCategory }
    }

    var body: some View {
        ZStack {
            DS.bg.ignoresSafeArea()
            VStack(spacing: 16) {
                header
                filterPillRow
                Spacer(minLength: 0)
                if filteredLessons.isEmpty {
                    emptyState
                } else {
                    cardStack
                    swipeCounter
                }
                Spacer(minLength: 0)
                if filteredLessons.count > 1 {
                    dotIndicator
                        .padding(.bottom, 20)
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
        VStack(alignment: .leading, spacing: 4) {
            Text("Your money mind")
                .font(.title3.weight(.bold))
                .foregroundStyle(DS.textPrimary)
            Text("Swipe to explore. Learn one, notice it tomorrow.")
                .font(.caption)
                .foregroundStyle(DS.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, DS.hPadding)
    }

    // MARK: - Filter pills (compact)

    private var filterPillRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
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
                .font(.system(size: 9, weight: .semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
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

    // MARK: - Card stack (1 back card only)

    private var cardStack: some View {
        ZStack {
            if currentIndex + 1 < filteredLessons.count {
                cardBase(fill: backBg)
                    .scaleEffect(0.96)
                    .offset(y: 10)
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
        .frame(height: cardHeight)
        .padding(.horizontal, DS.hPadding)
    }

    private func cardBase(fill: Color) -> some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(fill)
            .frame(height: cardHeight)
    }

    private func frontCard(_ lesson: BiasLesson) -> some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(DS.cardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(frontBorder, lineWidth: 0.5)
                )

            // Subtle seen badge in corner
            Text("0")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(DS.textTertiary)
                .padding(6)
                .background(Circle().fill(DS.paleGreen))
                .padding(12)

            VStack(spacing: 0) {
                // Emoji centred
                Text(lesson.emoji)
                    .font(.system(size: 52))
                    .frame(maxWidth: .infinity)
                    .padding(.top, 18)

                // Category pill centred
                categoryPill(lesson.category)
                    .padding(.top, 10)

                // Bias name
                Text(lesson.biasName)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(DS.primary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 12)

                // Short description
                Text(lesson.shortDescription)
                    .font(.system(size: 13))
                    .foregroundStyle(DS.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 4)
                    .padding(.horizontal, 8)

                // Divider with breathing room
                Divider()
                    .padding(.vertical, 12)
                    .padding(.horizontal, 8)

                // In real life
                Text("IN REAL LIFE")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(DS.accent)
                    .tracking(0.8)

                Text(lesson.realWorldExample)
                    .font(.system(size: 11))
                    .foregroundStyle(DS.textSecondary)
                    .lineLimit(3)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(DS.paleGreen)
                    )
                    .padding(.horizontal, 8)
                    .padding(.top, 4)

                Spacer(minLength: 0)

                // Gold CTA pinned to bottom
                NavigationLink(value: lesson) {
                    Text("See pattern")
                        .font(.system(size: 12, weight: .bold))
                        .goldButtonStyle()
                }
                .buttonStyle(.plain)
                .padding(.bottom, 16)
            }
            .padding(.horizontal, 14)
        }
        .frame(height: cardHeight)
    }

    private func categoryPill(_ cat: String) -> some View {
        let colours = Self.categoryColour(for: cat)
        return Text(cat)
            .font(.system(size: 10, weight: .semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Capsule().fill(colours.bg))
            .foregroundStyle(colours.text)
    }

    // MARK: - Swipe counter

    private var swipeCounter: some View {
        Text("\(currentIndex + 1) of \(filteredLessons.count)")
            .font(.caption)
            .foregroundStyle(DS.textTertiary)
    }

    // MARK: - Dot indicator

    private var dotIndicator: some View {
        HStack(spacing: 6) {
            ForEach(0..<filteredLessons.count, id: \.self) { i in
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        currentIndex = i
                        dragOffset = .zero
                    }
                } label: {
                    Circle()
                        .fill(i == currentIndex ? DS.primary : DS.textTertiary.opacity(0.3))
                        .frame(width: 7, height: 7)
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
            Text("No biases in this category")
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
