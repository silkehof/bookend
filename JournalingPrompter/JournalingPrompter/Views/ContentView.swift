import SwiftUI

struct ContentView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        if hasCompletedOnboarding {
            TabView {
                DailyView()
                    .tabItem {
                        Label("Today", systemImage: "sun.max.fill")
                    }

                JourneyView()
                    .tabItem {
                        Label("Journey", systemImage: "tree.fill")
                    }

                PromptsLibraryView()
                    .tabItem {
                        Label("Prompts", systemImage: "text.quote")
                    }

                HistoryView()
                    .tabItem {
                        Label("History", systemImage: "clock.fill")
                    }

                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gearshape.fill")
                    }
            }
            .tint(Color.warmAccent)
        } else {
            OnboardingView()
        }
    }
}

#Preview {
    ContentView()
}
