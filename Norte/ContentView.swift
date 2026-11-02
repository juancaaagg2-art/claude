import SwiftUI

enum AppTab: Hashable {
    case today, goals, focus, habits, progress
}

final class AppRouter: ObservableObject {
    @Published var tab: AppTab = .today
    @Published var pendingFocusMinutes: Int? = nil

    func goToFocus(minutes: Int) {
        pendingFocusMinutes = minutes
        tab = .focus
    }
}

struct ContentView: View {
    @EnvironmentObject var store: AppStore
    @EnvironmentObject var focusTimer: FocusTimer
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            if store.profile.hasOnboarded {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
        .onAppear {
            let s = store
            focusTimer.onFinish = { session in s.addSession(session) }
            if store.profile.hasOnboarded {
                NotificationManager.scheduleDailyReminders(for: store.profile)
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background || phase == .inactive {
                store.save()
            }
        }
    }
}

struct MainTabView: View {
    @EnvironmentObject var router: AppRouter

    var body: some View {
        TabView(selection: $router.tab) {
            TodayView()
                .tabItem { Label("Hoy", systemImage: "sun.max.fill") }
                .tag(AppTab.today)
            GoalsView()
                .tabItem { Label("Objetivos", systemImage: "flag.fill") }
                .tag(AppTab.goals)
            FocusView()
                .tabItem { Label("Enfoque", systemImage: "timer") }
                .tag(AppTab.focus)
            HabitsView()
                .tabItem { Label("Hábitos", systemImage: "repeat") }
                .tag(AppTab.habits)
            ProgressTabView()
                .tabItem { Label("Progreso", systemImage: "chart.bar.fill") }
                .tag(AppTab.progress)
        }
    }
}
