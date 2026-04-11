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

    // Swipe card backgrounds (PRD v1.1 § LearnView swipe card spec)
    private let frontBorder = Color(red: 0x2D/255.0, green: 0x1B/255.0, blue: 0x69/255.0).opacity(0.25)
    private let middleBg = Color(red: 0xF0/255.0, green: 0xEE/255.0, blue: 0xF8/255.0)
    private let backBg = Color(red: 0xE8/255.0, green: 0xE5/255.0, blue: 0xF5/255.0)
    private let deepPurple = Color(red: 0x2D/255.0, green: 0x1B/255.0, blue: 0x69/255.0)
    private let teal = Color(red: 0x00/255.0, green: 0x60/255.0, blue: 0x64/255.0)

    private var filteredLessons: [BiasLesson] {
        guard selectedCategory != "All" else { return allLessons }
        return allLessons.filter { $0.category == selectedCategory }
    }

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
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
            Text("Swipe through biases. Learn one. Notice it tomorrow.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
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
        let colours = Self.categoryColour(for: cat)
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
                    Capsule().fill(selected ? colours.bg : Color(.secondarySystemBackground))
                )
                .foregroundStyle(selected ? colours.text : .primary)
                .overlay(
                    Capsule().stroke(selected ? colours.text.opacity(0.3) : .clear, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    // Category tile colours per PRD v1.1
    static func categoryColour(for category: String) -> (bg: Color, text: Color) {
        switch category {
        case "Avoidance":
            return (Color(red: 0xE1/255.0, green: 0xF5/255.0, blue: 0xEE/255.0),
                    Color(red: 0x08/255.0, green: 0x50/255.0, blue: 0x41/255.0))
        case "Decision Making":
            return (Color(red: 0xEE/255.0, green: 0xED/255.0, blue: 0xFE/255.0),
                    Color(red: 0x3C/255.0, green: 0x34/255.0, blue: 0x89/255.0))
        case "Money Psychology":
            return (Color(red: 0xFA/255.0, green: 0xEE/255.0, blue: 0xDA/255.0),
                    Color(red: 0x41/255.0, green: 0x24/255.0, blue: 0x02/255.0))
        case "Time Perception":
            return (Color(red: 0xF3/255.0, green: 0xE5/255.0, blue: 0xF5/255.0),
                    Color(red: 0x4A/255.0, green: 0x14/255.0, blue: 0x8C/255.0))
        case "External Influence":
            return (Color(red: 0xFA/255.0, green: 0xEC/255.0, blue: 0xE7/255.0),
                    Color(red: 0x4A/255.0, green: 0x1B/255.0, blue: 0x0C/255.0))
        case "Self Perception":
            return (Color(red: 0xE0/255.0, green: 0xF7/255.0, blue: 0xFA/255.0),
                    Color(red: 0x00/255.0, green: 0x60/255.0, blue: 0x64/255.0))
        case "Inertia":
            return (Color(red: 0xFB/255.0, green: 0xE9/255.0, blue: 0xE7/255.0),
                    Color(red: 0xBF/255.0, green: 0x36/255.0, blue: 0x0C/255.0))
        default:
            return (Color(red: 0xEE/255.0, green: 0xED/255.0, blue: 0xFE/255.0),
                    Color(red: 0x3C/255.0, green: 0x34/255.0, blue: 0x89/255.0))
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
                .fill(Color.white)
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
                    .foregroundStyle(deepPurple)

                Text(lesson.shortDescription)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Divider().padding(.vertical, 2)

                Text("IN REAL LIFE")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(teal)
                    .tracking(0.8)

                Text(lesson.realWorldExample)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(teal.opacity(0.08))
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
                    .background(deepPurple, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
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

    // Seen X times badge — mock 0 for now, will use user_bias_progress later.
    private var seenBadge: some View {
        Text("Seen 0 times")
            .font(.caption.weight(.medium))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Capsule().fill(Color(.tertiarySystemBackground)))
            .foregroundStyle(.secondary)
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
                        .fill(i == currentIndex ? deepPurple : Color(.tertiarySystemBackground))
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
                .foregroundStyle(.tertiary)
            Text("No biases in this category yet")
                .font(.subheadline)
                .foregroundStyle(.secondary)
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
