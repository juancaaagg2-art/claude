import SwiftUI

@main
struct NorteApp: App {
    @StateObject private var store = AppStore()
    @StateObject private var focusTimer = FocusTimer()
    @StateObject private var router = AppRouter()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .environmentObject(focusTimer)
                .environmentObject(router)
                .tint(Theme.accent)
        }
    }
}
