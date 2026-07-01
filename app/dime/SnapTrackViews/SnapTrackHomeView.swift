import SwiftUI

struct SnapTrackHomeView: View {
    @EnvironmentObject var store: NutritionStore
    @EnvironmentObject var goals: GoalsStore

    @State private var currentTab = "Log"
    @State private var showAddMeal = false

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $currentTab) {
                SnapTrackLogView()
                    .tag("Log")

                SnapTrackInsightsView()
                    .tag("Insights")

                SnapTrackGoalsView()
                    .tag("Goals")

                SnapTrackSettingsView()
                    .tag("Settings")
            }
            .safeAreaInset(edge: .bottom) {
                tabBar
            }
        }
        .fullScreenCover(isPresented: $showAddMeal) {
            SnapTrackAddMealView()
                .environmentObject(store)
        }
        .overlay(
            MessageToast(message: $store.message),
            alignment: .top
        )
    }

    private var tabBar: some View {
        HStack(spacing: 0) {
            tabButton(name: "Log", icon: "Log", outlineIcon: "Log Outline")
            tabButton(name: "Insights", icon: "Insights", outlineIcon: "Insights Outline")

            Spacer()

            Button {
                Haptics.shared.medium()
                showAddMeal = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(Color.LightIcon)
                    .frame(width: 58, height: 44)
                    .background(Color.DarkBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
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
            Haptics.shared.select()
            currentTab = name
        } label: {
            Image(currentTab == name ? icon : outlineIcon)
                .resizable()
                .renderingMode(.template)
                .aspectRatio(contentMode: .fit)
                .frame(width: 26, height: 26)
                .frame(maxWidth: .infinity)
                .foregroundColor(currentTab == name ? Color.DarkIcon : Color.SubtitleText)
        }
        .accessibilityLabel("\(name) tab")
    }
}

struct MessageToast: View {
    @Binding var message: UserMessage?

    var body: some View {
        Group {
            if let message = message {
                HStack(spacing: 10) {
                    Image(systemName: message.systemImage)
                        .foregroundColor(message.color)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(message.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(Color.PrimaryText)
                        if let subtitle = message.subtitle {
                            Text(subtitle)
                                .font(.caption)
                                .foregroundColor(Color.SubtitleText)
                        }
                    }
                    Spacer()
                    Button {
                        self.message = nil
                    } label: {
                        Image(systemName: "xmark")
                            .font(.caption.weight(.bold))
                            .foregroundColor(Color.SubtitleText)
                    }
                }
                .padding()
                .background(Color.SecondaryBackground)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: message?.id)
    }
}
