import SwiftUI

struct ContentView: View {
    @Environment(WorkScheduleSettings.self) private var schedule

    private var preferredColorScheme: ColorScheme? {
        switch schedule.colorSchemePreference {
        case "light": return .light
        case "dark":  return .dark
        default:      return nil   // "system" → iOS-Einstellung übernehmen
        }
    }

    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Heute", systemImage: "house")
                }

            SettingsView()
                .tabItem {
                    Label("Einstellungen", systemImage: "gearshape")
                }
        }
        .tint(.emerald)
        .preferredColorScheme(preferredColorScheme)
        .sheet(isPresented: Binding(
            get: { !schedule.hasCompletedOnboarding },
            set: { _ in }
        )) {
            OnboardingView()
                .interactiveDismissDisabled()
        }
    }
}
