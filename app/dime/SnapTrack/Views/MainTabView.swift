import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var auth: AuthViewModel
    @State private var currentTab = "Log"
    @State private var showAddMeal = false

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $currentTab) {
                DashboardView()
                    .environmentObject(auth)
                    .tag("Log")

                InsightsPlaceholderView()
                    .tag("Insights")

                GoalsPlaceholderView()
                    .tag("Goals")

                SettingsPlaceholderView()
                    .environmentObject(auth)
                    .tag("Settings")
            }
            .safeAreaInset(edge: .bottom) {
                tabBar
            }
        }
        .fullScreenCover(isPresented: $showAddMeal) {
            DashboardView()
                .environmentObject(auth)
        }
    }

    private var tabBar: some View {
        HStack(spacing: 0) {
            tabButton(name: "Log", icon: "Log", outlineIcon: "Log Outline")
            tabButton(name: "Insights", icon: "Insights", outlineIcon: "Insights Outline")

            Spacer()

            Button {
                Haptics.medium()
                showAddMeal = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(Color.LightIcon)
                    .frame(width: 58, height: 44)
                    .background(Color.DarkBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .pressable()
            .accessibilityLabel("Log a meal")

            Spacer()

            tabButton(name: "Goals", icon: "Budget", outlineIcon: "Budget Outline")
            tabButton(name: "Settings", icon: "Settings", outlineIcon: "Settings Outline")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.PrimaryBackground)
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color.Outline.opacity(0.3)),
            alignment: .top
        )
    }

    private func tabButton(name: String, icon: String, outlineIcon: String) -> some View {
        Button {
            Haptics.select()
            currentTab = name
        } label: {
            Image(currentTab == name ? icon : outlineIcon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 26, height: 26)
                .frame(maxWidth: .infinity)
                .foregroundColor(currentTab == name ? Color.DarkIcon : Color.GreyIcon)
        }
        .pressable()
        .accessibilityLabel("\(name) tab")
    }
}

struct InsightsPlaceholderView: View {
    var body: some View {
        ZStack {
            Color.PrimaryBackground.ignoresSafeArea()
            VStack(spacing: 12) {
                Image("Insights")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 64, height: 64)
                    .foregroundStyle(Color.GreyIcon)
                Text("Insights")
                    .font(AppFont.title2)
                Text("Macro trends and meal breakdowns are coming soon.")
                    .font(AppFont.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
    }
}

struct GoalsPlaceholderView: View {
    var body: some View {
        ZStack {
            Color.PrimaryBackground.ignoresSafeArea()
            VStack(spacing: 12) {
                Image("Budget")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 64, height: 64)
                    .foregroundStyle(Color.GreyIcon)
                Text("Goals")
                    .font(AppFont.title2)
                Text("Daily calorie and macro goals are coming soon.")
                    .font(AppFont.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
    }
}

struct SettingsPlaceholderView: View {
    @EnvironmentObject var auth: AuthViewModel
    @State private var showDeleteConfirmation = false

    var body: some View {
        ZStack {
            Color.PrimaryBackground.ignoresSafeArea()
            VStack(spacing: 16) {
                Text("Settings")
                    .font(AppFont.title2)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Button {
                    Haptics.light()
                    Task { await auth.signOut() }
                } label: {
                    HStack {
                        Image(systemName: "arrow.right.square")
                        Text("Log Out")
                        Spacer()
                    }
                    .font(AppFont.headline)
                    .foregroundStyle(.primary)
                    .padding()
                    .background(Color.SecondaryBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .pressable()

                Button {
                    Haptics.warning()
                    showDeleteConfirmation = true
                } label: {
                    HStack {
                        Image(systemName: "trash")
                        Text("Delete Account")
                        Spacer()
                    }
                    .font(AppFont.headline)
                    .foregroundStyle(Color.AlertRed)
                    .padding()
                    .background(Color.AlertRed.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .pressable()

                Spacer()
            }
            .padding(.horizontal, AppLayout.horizontalPadding)
            .padding(.top, 12)
        }
        .confirmationDialog(
            "Delete Account?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Account", role: .destructive) {
                Task {
                    do {
                        try await SupabaseService.shared.deleteAccount()
                        Haptics.success()
                        await auth.signOut()
                    } catch {
                        Haptics.error()
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete your account and all meal history. This cannot be undone.")
        }
    }
}
