import SwiftUI

/// Tab routes used by NotificationRouter + view code. Renamed 2026-05-11:
/// `.awareness` removed as a top-level tab (its content folded into the new
/// Education tab); `.education` repurposed as the Learn slot at position 3;
/// `.research` becomes the Reference tab at position 4.
enum RootTab: Int, Hashable {
    case home      = 0
    case log       = 1
    case insights  = 2
    case education = 3
    case research  = 4
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
            NavigationStack { ResearchView(mode: .learn) }
                .tabItem { Label("Education", systemImage: "graduationcap.fill") }
                .tag(RootTab.education)
            NavigationStack { ResearchView(mode: .reference) }
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
        .onChange(of: router.pendingRoute) { _, route in
            guard let route else { return }
            // Notification routes target a specific tab. Home routes
            // (e.g. finance editor) swing to Home; insights routes
            // (weekly + monthly review pushes) swing to Insights.
            switch route {
            case .openFinanceEditor:
                // HomeView reads pendingRoute to open the editor sheet
                // and clears it once acted on, so don't nil here.
                selection = .home
            case .openInsights:
                selection = .insights
                // No view consumes openInsights beyond the tab switch,
                // so clear it now to avoid re-firing on next nav.
                router.pendingRoute = nil
            }
        }
        .task {
            // Cold-launch case: if the user tapped a notification while the
            // app was closed, the router may already have a pending value
            // before any view's onChange observers start firing. Apply the
            // initial routing once.
            if let route = router.pendingRoute {
                switch route {
                case .openFinanceEditor: selection = .home
                case .openInsights:      selection = .insights
                }
            }
            if router.pendingSlot != nil { selection = .log }
        }
    }
}

#Preview {
    RootTabView()
}
