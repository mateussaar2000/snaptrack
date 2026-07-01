import SwiftUI

// MARK: - Colors

enum AppColor {
    static let primary = Color("AccentColor")
    static let primaryGradient = LinearGradient(
        colors: [Color("AccentColor"), Color("AccentColor").opacity(0.8)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let surface = Color(.systemBackground)
    static let surfaceSecondary = Color(.secondarySystemBackground)
    static let surfaceTertiary = Color(.tertiarySystemBackground)
    static let separator = Color(.separator)
    static let success = Color.green
    static let warning = Color.orange
    static let destructive = Color.red

    static let landingGradient = LinearGradient(
        colors: [
            Color(red: 0.94, green: 0.97, blue: 1.0),
            Color(red: 0.98, green: 0.99, blue: 1.0),
            Color.white
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    static let heroGradient = LinearGradient(
        colors: [Color("AccentColor"), Color(red: 0.0, green: 0.35, blue: 0.75)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Typography

enum AppFont {
    static let hero = Font.system(size: 44, weight: .bold, design: .rounded)
    static let title = Font.system(size: 28, weight: .bold, design: .rounded)
    static let title2 = Font.system(size: 22, weight: .bold, design: .rounded)
    static let headline = Font.system(size: 17, weight: .semibold, design: .rounded)
    static let body = Font.system(size: 16, weight: .regular, design: .default)
    static let callout = Font.system(size: 15, weight: .medium)
    static let caption = Font.system(size: 13, weight: .medium)
    static let largeNumber = Font.system(size: 34, weight: .bold, design: .rounded)
    static let statNumber = Font.system(size: 26, weight: .bold, design: .rounded)
}

// MARK: - Spacing / Sizing

enum AppLayout {
    static let cardRadius: CGFloat = 24
    static let cardPadding: CGFloat = 20
    static let smallRadius: CGFloat = 16
    static let buttonRadius: CGFloat = 20
    static let sectionSpacing: CGFloat = 20
    static let horizontalPadding: CGFloat = 20
    static let shadowColor = Color.black.opacity(0.06)
    static let shadowRadius: CGFloat = 16
    static let shadowY: CGFloat = 6
}

// MARK: - Animations

enum AppAnimation {
    static let spring = Animation.spring(response: 0.38, dampingFraction: 0.82)
    static let ease = Animation.easeInOut(duration: 0.25)
    static let slowEase = Animation.easeInOut(duration: 0.45)
}

// MARK: - View Modifiers

struct PrimaryButtonStyle: ViewModifier {
    let isLoading: Bool
    let isDisabled: Bool

    func body(content: Content) -> some View {
        content
            .font(AppFont.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isDisabled ? AppColor.primary.opacity(0.4) : AppColor.primary)
            .clipShape(RoundedRectangle(cornerRadius: AppLayout.buttonRadius))
            .shadow(color: AppColor.primary.opacity(isDisabled ? 0 : 0.35), radius: 12, x: 0, y: 6)
            .scaleEffect(isLoading ? 0.98 : 1.0)
            .animation(AppAnimation.spring, value: isLoading)
    }
}

struct CardStyle: ViewModifier {
    var padding: CGFloat = AppLayout.cardPadding
    var radius: CGFloat = AppLayout.cardRadius

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(AppColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: radius))
            .shadow(color: AppLayout.shadowColor, radius: AppLayout.shadowRadius, x: 0, y: AppLayout.shadowY)
    }
}

struct SecondaryCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(AppLayout.cardPadding)
            .background(AppColor.surfaceSecondary)
            .clipShape(RoundedRectangle(cornerRadius: AppLayout.smallRadius))
    }
}

struct PressableScale: ViewModifier {
    @State private var isPressed = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .opacity(isPressed ? 0.9 : 1.0)
            .animation(AppAnimation.spring, value: isPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in isPressed = true }
                    .onEnded { _ in isPressed = false }
            )
    }
}

extension View {
    func primaryButton(isLoading: Bool = false, isDisabled: Bool = false) -> some View {
        modifier(PrimaryButtonStyle(isLoading: isLoading, isDisabled: isDisabled))
    }

    func appCard(padding: CGFloat = AppLayout.cardPadding, radius: CGFloat = AppLayout.cardRadius) -> some View {
        modifier(CardStyle(padding: padding, radius: radius))
    }

    func secondaryCard() -> some View {
        modifier(SecondaryCardStyle())
    }

    func pressable() -> some View {
        modifier(PressableScale())
    }
}

// MARK: - Input Field Style

struct AppTextFieldStyle: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .font(AppFont.body)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(AppColor.surfaceSecondary)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(AppColor.separator.opacity(0.5), lineWidth: 1)
            )
    }
}

extension View {
    func appTextField() -> some View {
        modifier(AppTextFieldStyle())
    }
}
