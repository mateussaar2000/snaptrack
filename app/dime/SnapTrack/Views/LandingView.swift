import SwiftUI

struct LandingView: View {
    @EnvironmentObject var auth: AuthViewModel
    @State private var showAuth = false
    @State private var logoScale = 0.8
    @State private var logoOpacity = 0.0
    @State private var textOffset: CGFloat = 30
    @State private var textOpacity = 0.0
    @State private var cardOffset: CGFloat = 60
    @State private var cardOpacity = 0.0

    var body: some View {
        ZStack {
            AppColor.landingGradient
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    Spacer(minLength: 50)

                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(AppColor.primary.opacity(0.12))
                                .frame(width: 140, height: 140)
                            Circle()
                                .fill(AppColor.primary.opacity(0.08))
                                .frame(width: 114, height: 114)
                            Image("Logo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 78, height: 78)
                                .clipShape(RoundedRectangle(cornerRadius: 22))
                                .shadow(color: AppColor.primary.opacity(0.25), radius: 18, x: 0, y: 8)
                        }
                        .scaleEffect(logoScale)
                        .opacity(logoOpacity)

                        VStack(spacing: 8) {
                            Text("SnapTrack")
                                .font(.system(size: 40, weight: .bold, design: .rounded))
                                .foregroundStyle(.primary)

                            Text("Track meals in under 5 seconds")
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)

                            Text("Snap a photo. AI estimates calories, protein, carbs, and fat — instantly.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary.opacity(0.85))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }
                        .offset(y: textOffset)
                        .opacity(textOpacity)
                    }
                    .padding(.bottom, 28)

                    VStack(spacing: 12) {
                        FeatureRow(
                            icon: "camera.fill",
                            color: AppColor.primary,
                            title: "Snap a meal",
                            description: "Use your camera to capture what you're eating."
                        )
                        FeatureRow(
                            icon: "mic.fill",
                            color: AppColor.warning,
                            title: "Add voice context",
                            description: "Record a quick note for more accurate estimates."
                        )
                        FeatureRow(
                            icon: "chart.line.uptrend.xyaxis",
                            color: AppColor.success,
                            title: "Track trends",
                            description: "See daily totals and weekly progress at a glance."
                        )
                    }
                    .offset(y: cardOffset)
                    .opacity(cardOpacity)
                    .padding(.horizontal, AppLayout.horizontalPadding)

                    Spacer(minLength: 30)

                    VStack(spacing: 12) {
                        Button {
                            Haptics.medium()
                            withAnimation(AppAnimation.spring) { showAuth = true }
                        } label: {
                            Text("Get Started")
                                .primaryButton()
                        }
                        .pressable()

                        Text("By continuing, you agree to our Terms & Privacy Policy")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .padding(.horizontal, AppLayout.horizontalPadding)
                    .padding(.bottom, 24)
                    .offset(y: cardOffset)
                    .opacity(cardOpacity)
                }
            }

            if showAuth {
                AuthOverlay(onClose: { showAuth = false })
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                    .zIndex(1)
            }
        }
        .onAppear(perform: animateIn)
    }

    private func animateIn() {
        Haptics.prepare()
        withAnimation(AppAnimation.spring.delay(0.1)) {
            logoScale = 1.0
            logoOpacity = 1.0
        }
        withAnimation(AppAnimation.spring.delay(0.25)) {
            textOffset = 0
            textOpacity = 1.0
        }
        withAnimation(AppAnimation.spring.delay(0.45)) {
            cardOffset = 0
            cardOpacity = 1.0
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let color: Color
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(color.opacity(0.12))
                    .frame(width: 52, height: 52)
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(color)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AppFont.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(16)
        .background(AppColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppLayout.smallRadius))
        .shadow(color: AppLayout.shadowColor, radius: 12, x: 0, y: 4)
    }
}

struct AuthOverlay: View {
    let onClose: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .onTapGesture { onClose() }

            VStack {
                Spacer()
                AuthView(onClose: onClose)
                    .appCard(padding: 0, radius: 32)
                    .padding(.horizontal, AppLayout.horizontalPadding)
                    .padding(.bottom, 24)
            }
        }
    }
}
