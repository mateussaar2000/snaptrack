import Foundation

struct UserGoals: Codable, Equatable {
    var calories: Int = 2500
    var protein: Int = 150
    var carbs: Int = 300
    var fat: Int = 80

    static let `default` = UserGoals()
}

extension UserGoals {
    func progress(for totals: (calories: Int, protein: Int, carbs: Int, fat: Int)) -> (
        calories: Double,
        protein: Double,
        carbs: Double,
        fat: Double
    ) {
        (
            calories > 0 ? min(Double(totals.calories) / Double(calories), 1.0) : 0,
            protein > 0 ? min(Double(totals.protein) / Double(protein), 1.0) : 0,
            carbs > 0 ? min(Double(totals.carbs) / Double(carbs), 1.0) : 0,
            fat > 0 ? min(Double(totals.fat) / Double(fat), 1.0) : 0
        )
    }
}
