import SwiftUI

enum RootTab: Int, Hashable {
    case home = 0
    case checkIn = 1
    case learn = 2
    case month = 3
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
                CheckInView(selectedTab: $selection)
            }
            .tabItem {
                Label("Check in", systemImage: "sparkles")
            }
            .tag(RootTab.checkIn)

            NavigationStack {
                LearnView()
            }
            .tabItem {
                Label("Learn", systemImage: "book.fill")
            }
            .tag(RootTab.learn)

            NavigationStack {
                MonthView()
            }
            .tabItem {
                Label("Month", systemImage: "calendar")
            }
            .tag(RootTab.month)
        }
        .tint(DS.accent)
    }
}

#Preview {
    RootTabView()
}
