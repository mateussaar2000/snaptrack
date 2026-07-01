import SwiftUI

@main
struct SnapTrackApp: App {
    @StateObject private var auth = AuthViewModel()
    @StateObject private var store = NutritionStore()
    @StateObject private var goals = GoalsStore()
    @StateObject private var settings = SettingsStore()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ZStack {
                Color.PrimaryBackground.ignoresSafeArea()

                if auth.isLoading {
                    LaunchScreen()
                        .environmentObject(auth)
                } else if auth.isAuthenticated {
                    SnapTrackHomeView()
                        .environmentObject(auth)
                        .environmentObject(store)
                        .environmentObject(goals)
                        .environmentObject(settings)
                } else {
                    SnapTrackAuthView()
                        .environmentObject(auth)
                }
            }
            .onChange(of: auth.isAuthenticated) { isAuthenticated in
                if isAuthenticated {
                    Task {
                        await store.load()
                    }
                } else {
                    store.meals = []
                    store.weeklyMacros = []
                    Task {
                        await LocalMealCache.shared.clear()
                    }
                }
            }
            .onChange(of: scenePhase) { phase in
                if phase == .active, auth.isAuthenticated {
                    Task {
                        await store.load()
                    }
                }
            }
        }
    }
}

struct LaunchScreen: View {
    @EnvironmentObject var auth: AuthViewModel

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "camera.fill")
                .font(.system(size: 56, weight: .bold))
                .foregroundColor(Color.DarkBackground)
                .frame(width: 110, height: 110)
                .background(Color.SecondaryBackground)
                .clipShape(RoundedRectangle(cornerRadius: 32))

            Text("SnapTrack")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundColor(Color.PrimaryText)

            ProgressView()
                .tint(Color.DarkBackground)
                .padding(.top, 8)
        }
    }
}
