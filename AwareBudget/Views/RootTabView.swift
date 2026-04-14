import SwiftUI

enum RootTab: Int, Hashable {
    case why = 0
    case home = 1
    case log = 2
    case insights = 3
    case awareness = 4
}

struct RootTabView: View {
    @State private var selection: RootTab = .home

    var body: some View {
        TabView(selection: $selection) {
            NavigationStack { WhyView() }
                .tabItem { Label("Why", systemImage: "questionmark.circle") }
                .tag(RootTab.why)
            NavigationStack { HomeView() }
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(RootTab.home)
            NavigationStack { MoneyEventView(selectedTab: $selection) }
                .tabItem { Label("Log", systemImage: "plus.circle.fill") }
                .tag(RootTab.log)
            NavigationStack { InsightFeedView() }
                .tabItem { Label("Insights", systemImage: "chart.line.uptrend.xyaxis") }
                .tag(RootTab.insights)
            NavigationStack { AwarenessView() }
                .tabItem { Label("Awareness", systemImage: "brain.head.profile") }
                .tag(RootTab.awareness)
        }
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarBackground(DS.cardBg, for: .tabBar)
        .tint(DS.accent)
    }
}

#Preview {
    RootTabView()
}
