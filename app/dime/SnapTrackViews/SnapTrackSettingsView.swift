import SwiftUI
import UIKit

struct SnapTrackSettingsView: View {
    @EnvironmentObject var auth: AuthViewModel
    @EnvironmentObject var settings: SettingsStore
    @State private var showDeleteConfirmation = false
    @State private var isDeleting = false

    private var userEmail: String? {
        SupabaseService.shared.currentUser?.email
    }

    private var userId: String? {
        SupabaseService.shared.currentUser?.id.uuidString
    }

    private var appVersion: String {
        let version = UIApplication.appVersion ?? "1.0"
        let build = UIApplication.buildNumber ?? "0"
        return "\(version) (\(build))"
    }

    var body: some View {
        ZStack {
            Color.PrimaryBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    Text("Settings")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(Color.PrimaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    profileSection
                    preferencesSection
                    dangerSection
                    aboutSection

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
            }
        }
        .confirmationDialog(
            "Delete Account?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Account", role: .destructive) {
                deleteAccount()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete your account and all meal history. This cannot be undone.")
        }
        .overlay(
            MessageToast(message: $auth.message),
            alignment: .top
        )
    }

    private var profileSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Account")
                .font(.headline)
                .foregroundColor(Color.PrimaryText)

            VStack(alignment: .leading, spacing: 12) {
                if let email = userEmail {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Email")
                            .font(.caption)
                            .foregroundColor(Color.SubtitleText)
                        Text(email)
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .foregroundColor(Color.PrimaryText)
                            .lineLimit(1)
                    }
                }

                if let id = userId {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("User ID")
                            .font(.caption)
                            .foregroundColor(Color.SubtitleText)
                        Text(id)
                            .font(.caption2)
                            .foregroundColor(Color.SubtitleText)
                            .lineLimit(1)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.TertiaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .padding(20)
        .background(Color.SecondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    private var preferencesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Preferences")
                .font(.headline)
                .foregroundColor(Color.PrimaryText)

            HStack {
                Text("Units")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(Color.PrimaryText)
                Spacer()
                Picker("Units", selection: $settings.unitSystem) {
                    ForEach(UnitSystem.allCases) { unit in
                        Text(unit.shortTitle).tag(unit)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 160)
            }
            .padding()
            .background(Color.TertiaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .padding(20)
        .background(Color.SecondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    private var dangerSection: some View {
        VStack(spacing: 12) {
            Button {
                Haptics.shared.light()
                Task { await auth.signOut() }
            } label: {
                HStack {
                    Image(systemName: "arrow.right.square")
                    Text("Log Out")
                    Spacer()
                }
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundColor(Color.PrimaryText)
                .padding()
                .background(Color.SecondaryBackground)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }

            Button {
                Haptics.shared.warning()
                showDeleteConfirmation = true
            } label: {
                HStack {
                    Image(systemName: "trash")
                    if isDeleting {
                        ProgressView()
                            .tint(Color.AlertRed)
                            .padding(.leading, 4)
                    } else {
                        Text("Delete Account")
                    }
                    Spacer()
                }
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundColor(Color.AlertRed)
                .padding()
                .background(Color.AlertRed.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .disabled(isDeleting)
        }
    }

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("About")
                .font(.headline)
                .foregroundColor(Color.PrimaryText)

            HStack {
                Text("Version")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(Color.PrimaryText)
                Spacer()
                Text(appVersion)
                    .font(.subheadline)
                    .foregroundColor(Color.SubtitleText)
            }
            .padding()
            .background(Color.TertiaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .padding(20)
        .background(Color.SecondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    private func deleteAccount() {
        isDeleting = true
        Task {
            do {
                try await SupabaseService.shared.deleteAccount()
                Haptics.shared.success()
                await auth.signOut()
            } catch {
                Haptics.shared.error()
                auth.present(.error(error))
            }
            isDeleting = false
        }
    }
}
