import Foundation

struct Meal: Identifiable, Codable, Hashable {
    let id: UUID
    let createdAt: String
    let imageUrl: String?
    let foodName: String
    let calories: Int
    let protein: Int
    let carbs: Int
    let fat: Int
    let userId: UUID

    enum CodingKeys: String, CodingKey {
        case id
        case createdAt = "created_at"
        case imageUrl = "image_url"
        case foodName = "food_name"
        case calories
        case protein
        case carbs
        case fat
        case userId = "user_id"
    }
}

struct MealUpdate: Codable {
    let foodName: String?
    let calories: Int?
    let protein: Int?
    let carbs: Int?
    let fat: Int?

    enum CodingKeys: String, CodingKey {
        case foodName = "food_name"
        case calories
        case protein
        case carbs
        case fat
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(foodName, forKey: .foodName)
        try container.encodeIfPresent(calories, forKey: .calories)
        try container.encodeIfPresent(protein, forKey: .protein)
        try container.encodeIfPresent(carbs, forKey: .carbs)
        try container.encodeIfPresent(fat, forKey: .fat)
    }
}

struct DayMacros: Identifiable, Equatable, Codable {
    let id: UUID
    let date: Date
    let dateKey: String
    let calories: Int
    let protein: Int
    let carbs: Int
    let fat: Int

    init(id: UUID = UUID(), date: Date, dateKey: String, calories: Int, protein: Int, carbs: Int, fat: Int) {
        self.id = id
        self.date = date
        self.dateKey = dateKey
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
    }

    enum CodingKeys: String, CodingKey {
        case id
        case date
        case dateKey
        case calories
        case protein
        case carbs
        case fat
    }
}

struct MealMacros: Codable {
    let createdAt: String
    let calories: Int
    let protein: Int
    let carbs: Int
    let fat: Int

    enum CodingKeys: String, CodingKey {
        case createdAt = "created_at"
        case calories
        case protein
        case carbs
        case fat
    }
}

struct MealDate: Codable {
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case createdAt = "created_at"
    }
}

struct AnalyzeResponse: Codable {
    let success: Bool?
    let analysis: Analysis?
    let error: String?
}

struct Analysis: Codable {
    let foodName: String?
    let calories: Int?
    let protein: Int?
    let carbs: Int?
    let fat: Int?

    enum CodingKeys: String, CodingKey {
        case foodName = "food_name"
        case calories
        case protein
        case carbs
        case fat
    }
}
