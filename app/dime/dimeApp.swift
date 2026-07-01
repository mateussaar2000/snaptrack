//
//  SnapTrackApp.swift
//  SnapTrack
//
//  Based on Dime by Rafael Soh & Jeffrey Chia.
//

import SwiftUI

@main
struct SnapTrackApp: App {
    @StateObject private var auth = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            ZStack {
                if auth.isAuthenticated {
                    MainTabView()
                        .environmentObject(auth)
                        .transition(.opacity)
                } else if auth.isLoading {
                    LaunchScreen()
                        .transition(.opacity)
                } else {
                    LandingView()
                        .environmentObject(auth)
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: auth.isAuthenticated)
            .animation(.easeInOut(duration: 0.3), value: auth.isLoading)
        }
    }
}
