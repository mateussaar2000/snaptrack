import Foundation
import Supabase

@MainActor
final class SupabaseService {
    static let shared = SupabaseService()

    private let client: SupabaseClient

    private init() {
        client = SupabaseClient(supabaseURL: Config.supabaseURL, supabaseKey: Config.supabaseAnonKey)
    }

    var currentUser: User? {
        client.auth.currentUser
    }

    var isAuthenticated: Bool {
        currentUser != nil
    }

    func refreshSession() async throws -> User? {
        let session = try await client.auth.session
        return session.user
    }

    // MARK: - Auth

    func signUp(email: String, password: String) async throws {
        _ = try await client.auth.signUp(email: email, password: password)
    }

    func signIn(email: String, password: String) async throws {
        _ = try await client.auth.signIn(email: email, password: password)
    }

    func signOut() async throws {
        try await client.auth.signOut()
    }

    func resetPassword(email: String) async throws {
        try await client.auth.resetPasswordForEmail(email)
    }

    // MARK: - Meals

    func fetchMeals(for userId: UUID, on date: Date) async throws -> [Meal] {
        let start = DateUtils.isoString(from: DateUtils.startOfDay(date))
        let end = DateUtils.isoString(from: DateUtils.endOfDay(date))

        return try await client
            .from("meals")
            .select()
            .eq("user_id", value: userId.uuidString)
            .gte("created_at", value: start)
            .lte("created_at", value: end)
            .order("created_at", ascending: false)
            .execute()
            .value
    }

    func createMeal(
        foodName: String,
        calories: Int,
        protein: Int,
        carbs: Int,
        fat: Int,
        imageUrl: String? = nil,
        for userId: UUID
    ) async throws -> Meal {
        let meal = Meal(
            id: UUID(),
            createdAt: DateUtils.isoString(from: Date()),
            imageUrl: imageUrl,
            foodName: foodName,
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat,
            userId: userId
        )

        try await client
            .from("meals")
            .insert(meal)
            .execute()

        return meal
    }

    func deleteMeal(id: UUID, for userId: UUID) async throws {
        try await client
            .from("meals")
            .delete()
            .eq("id", value: id.uuidString)
            .eq("user_id", value: userId.uuidString)
            .execute()
    }

    func updateMeal(id: UUID, for userId: UUID, updates: MealUpdate) async throws {
        try await client
            .from("meals")
            .update(updates)
            .eq("id", value: id.uuidString)
            .eq("user_id", value: userId.uuidString)
            .execute()
    }

    func fetchRecentMeals(for userId: UUID, days: Int = 60) async throws -> [MealDate] {
        let start = DateUtils.isoString(from: Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date())
        return try await client
            .from("meals")
            .select("created_at")
            .eq("user_id", value: userId.uuidString)
            .gte("created_at", value: start)
            .order("created_at", ascending: false)
            .execute()
            .value
    }

    func fetchWeeklyMacros(for userId: UUID, days: Int = 30) async throws -> [DayMacros] {
        let end = Date()
        let start = Calendar.current.date(byAdding: .day, value: -days, to: end) ?? end

        let meals: [MealMacros] = try await client
            .from("meals")
            .select("created_at, calories, protein, carbs, fat")
            .eq("user_id", value: userId.uuidString)
            .gte("created_at", value: DateUtils.isoString(from: start))
            .lte("created_at", value: DateUtils.isoString(from: end))
            .execute()
            .value

        var days: [String: DayMacros] = [:]
        for meal in meals {
            guard let date = DateUtils.parseISO(meal.createdAt) else { continue }
            let key = DateUtils.dateKey(date)
            let base = days[key]
            days[key] = DayMacros(
                date: date,
                dateKey: key,
                calories: (base?.calories ?? 0) + meal.calories,
                protein: (base?.protein ?? 0) + meal.protein,
                carbs: (base?.carbs ?? 0) + meal.carbs,
                fat: (base?.fat ?? 0) + meal.fat
            )
        }
        return days.values.sorted { $0.dateKey < $1.dateKey }
    }

    // MARK: - Analysis

    func analyzeImage(_ imageData: Data, hint: String, for userId: UUID) async throws {
        let filename = "mobile/\(userId.uuidString)/\(Int(Date().timeIntervalSince1970 * 1000)).jpg"

        try await client.storage
            .from("food-photos")
            .upload(
                filename,
                data: imageData,
                options: FileOptions(cacheControl: "3600", contentType: "image/jpeg", upsert: false)
            )

        let publicURL = try client.storage.from("food-photos").getPublicURL(path: filename)

        let request = AnalyzeRequest(imageUrl: publicURL.absoluteString, hint: hint, userId: userId.uuidString)
        let _: AnalyzeResponse = try await client.functions.invoke(
            "analyze",
            options: FunctionInvokeOptions(body: request)
        )
    }

    func analyzeText(_ foodName: String, for userId: UUID) async throws {
        let request = AnalyzeRequest(foodName: foodName, userId: userId.uuidString)
        let _: AnalyzeResponse = try await client.functions.invoke(
            "analyze",
            options: FunctionInvokeOptions(body: request)
        )
    }

    func reanalyzeMeal(id: UUID, foodName: String, imageUrl: String?, for userId: UUID) async throws {
        let request = AnalyzeRequest(
            imageUrl: imageUrl,
            foodName: foodName,
            hint: foodName,
            userId: userId.uuidString,
            mealId: id.uuidString
        )
        let _: AnalyzeResponse = try await client.functions.invoke(
            "analyze",
            options: FunctionInvokeOptions(body: request)
        )
    }

    func deleteAccount() async throws {
        struct DeleteResponse: Codable {
            let success: Bool?
            let error: String?
        }
        let response: DeleteResponse = try await client.functions.invoke(
            "delete-user",
            options: FunctionInvokeOptions(body: [String: String]())
        )
        if response.success != true {
            throw NSError(
                domain: "SnapTrack",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: response.error ?? "Account deletion failed"]
            )
        }
    }
}

private struct AnalyzeRequest: Codable {
    let imageUrl: String?
    let foodName: String?
    let hint: String?
    let userId: String
    let mealId: String?

    enum CodingKeys: String, CodingKey {
        case imageUrl = "image_url"
        case foodName = "food_name"
        case hint
        case userId = "user_id"
        case mealId = "meal_id"
    }

    init(imageUrl: String? = nil, foodName: String? = nil, hint: String? = nil, userId: String, mealId: String? = nil) {
        self.imageUrl = imageUrl
        self.foodName = foodName
        self.hint = hint
        self.userId = userId
        self.mealId = mealId
    }
}
