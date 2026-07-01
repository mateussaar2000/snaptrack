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
}

struct DayMacros: Identifiable, Equatable {
    let id = UUID()
    let date: Date
    let dateKey: String
    let calories: Int
    let protein: Int
    let carbs: Int
    let fat: Int
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
