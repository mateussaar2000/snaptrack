import UIKit

struct Haptics {
    static let shared = Haptics()

    func light() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    func medium() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    func heavy() {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
    }

    func select() {
        UISelectionFeedbackGenerator().selectionChanged()
    }

    func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    func error() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }

    func warning() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }
}
