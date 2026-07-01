import Foundation
import Combine

@MainActor
final class GoalsStore: ObservableObject {
    private enum Keys {
        static let goals = "com.snaptrack.userGoals"
    }

    @Published var goals: UserGoals {
        didSet {
            save()
        }
    }

    init() {
        if let data = UserDefaults.standard.data(forKey: Keys.goals),
           let decoded = try? JSONDecoder().decode(UserGoals.self, from: data) {
            self.goals = decoded
        } else {
            self.goals = UserGoals.default
        }
    }

    func resetToDefaults() {
        goals = UserGoals.default
    }

    private func save() {
        if let data = try? JSONEncoder().encode(goals) {
            UserDefaults.standard.set(data, forKey: Keys.goals)
        }
    }
}
