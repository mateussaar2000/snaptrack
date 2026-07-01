import UIKit

enum Haptics {
    static let impactLight = UIImpactFeedbackGenerator(style: .light)
    static let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    static let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
    static let notification = UINotificationFeedbackGenerator()
    static let selection = UISelectionFeedbackGenerator()

    static func prepare() {
        impactLight.prepare()
        impactMedium.prepare()
        impactHeavy.prepare()
        notification.prepare()
        selection.prepare()
    }

    static func light() { impactLight.impactOccurred() }
    static func medium() { impactMedium.impactOccurred() }
    static func heavy() { impactHeavy.impactOccurred() }
    static func success() { notification.notificationOccurred(.success) }
    static func error() { notification.notificationOccurred(.error) }
    static func warning() { notification.notificationOccurred(.warning) }
    static func select() { selection.selectionChanged() }
}
