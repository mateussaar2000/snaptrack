import SwiftUI

struct UserMessage: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let subtitle: String?
    let systemImage: String
    let color: Color
    let dismissAfter: TimeInterval?

    init(
        title: String,
        subtitle: String? = nil,
        systemImage: String = "info.circle.fill",
        color: Color = Color.PrimaryText,
        dismissAfter: TimeInterval? = 3
    ) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.color = color
        self.dismissAfter = dismissAfter
    }

    static func error(_ error: Error) -> UserMessage {
        let appError = error as? AppError ?? AppError.map(error)
        return UserMessage(
            title: appError.errorDescription ?? "Error",
            systemImage: "xmark.circle.fill",
            color: Color.AlertRed
        )
    }

    static func success(title: String, subtitle: String? = nil) -> UserMessage {
        UserMessage(
            title: title,
            subtitle: subtitle,
            systemImage: "checkmark.circle.fill",
            color: Color.IncomeGreen
        )
    }

    static func info(title: String, subtitle: String? = nil) -> UserMessage {
        UserMessage(
            title: title,
            subtitle: subtitle,
            systemImage: "info.circle.fill",
            color: Color.DarkBackground
        )
    }
}
