import SwiftUI

enum RootTab: Int, Hashable {
    case home = 0
    case log = 1
    case insights = 2
    case library = 3
}

struct RootTabView: View {
    @State private var selection: RootTab = .home

    var body: some View {
        TabView(selection: $selection) {
            NavigationStack {
                HomeView(selectedTab: $selection)
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            .tag(RootTab.home)

            NavigationStack {
                MoneyEventView(selectedTab: $selection)
            }
            .tabItem {
                Label("Log", systemImage: "plus.circle.fill")
            }
            .tag(RootTab.log)

            NavigationStack {
                InsightFeedView()
            }
            .tabItem {
                Label("Insights", systemImage: "chart.line.uptrend.xyaxis")
            }
            .tag(RootTab.insights)

            NavigationStack {
                LearnView()
            }
            .tabItem {
                Label("Bias Tracker", systemImage: "brain")
            }
            .tag(RootTab.library)
        }
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarBackground(Color.white, for: .tabBar)
        .tint(DS.primary)
    }
}

#Preview {
    RootTabView()
}
