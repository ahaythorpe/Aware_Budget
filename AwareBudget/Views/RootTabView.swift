import SwiftUI

enum RootTab: Int, Hashable {
    case home = 0
    case log = 1
    case insights = 2
    case awareness = 3
    case research = 4
}

struct RootTabView: View {
    @State private var selection: RootTab = .home
    @Bindable private var router = NotificationRouter.shared

    var body: some View {
        TabView(selection: $selection) {
            NavigationStack { HomeView(selectedTab: $selection) }
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(RootTab.home)
            NavigationStack { MoneyEventView(selectedTab: $selection) }
                .tabItem { Label("Log", systemImage: "plus.circle.fill") }
                .tag(RootTab.log)
            NavigationStack { InsightFeedView(selectedTab: $selection) }
                .tabItem { Label("Insights", systemImage: "chart.line.uptrend.xyaxis") }
                .tag(RootTab.insights)
            NavigationStack { AwarenessView() }
                .tabItem { Label("Awareness", systemImage: "brain.head.profile") }
                .tag(RootTab.awareness)
            NavigationStack { ResearchView() }
                .tabItem { Label("Research", systemImage: "book.closed.fill") }
                .tag(RootTab.research)
        }
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarBackground(DS.cardBg, for: .tabBar)
        .tint(DS.accent)
        .onChange(of: router.pendingSlot) { _, slot in
            guard slot != nil else { return }
            // Notification tap → jump to Log tab. The slot stays set
            // so MoneyEventView can read it and pre-highlight tiles.
            // Cleared by MoneyEventView once acted on.
            selection = .log
        }
    }
}

#Preview {
    RootTabView()
}
