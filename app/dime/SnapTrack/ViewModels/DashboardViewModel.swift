import Foundation
import SwiftUI

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var currentDate = Date()
    @Published var meals: [Meal] = []
    @Published var weeklyData: [DayMacros] = []
    @Published var streak: Int = 0
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var captureState = CaptureState.idle
    @Published var toastMessage: String?

    private let service = SupabaseService.shared

    var totals: (calories: Int, protein: Int, carbs: Int, fat: Int) {
        meals.reduce((0, 0, 0, 0)) { acc, meal in
            (acc.0 + meal.calories, acc.1 + meal.protein, acc.2 + meal.carbs, acc.3 + meal.fat)
        }
    }

    var isAnalyzing: Bool {
        if case .analyzing = captureState { return true }
        return false
    }

    func load() async {
        guard let userId = service.currentUser?.id else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            async let mealsTask: () = loadMeals(userId: userId)
            async let weeklyTask: () = loadWeekly(userId: userId)
            async let streakTask: () = loadStreak(userId: userId)
            _ = try await (mealsTask, weeklyTask, streakTask)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadMeals(userId: UUID) async throws {
        meals = try await service.fetchMeals(for: userId, on: currentDate)
    }

    func loadWeekly(userId: UUID) async throws {
        weeklyData = try await service.fetchWeeklyMacros(for: userId)
    }

    func loadStreak(userId: UUID) async throws {
        let recent = try await service.fetchRecentMeals(for: userId, days: 120)
        streak = computeStreak(from: recent)
    }

    func changeDay(by delta: Int) {
        currentDate = Calendar.current.date(byAdding: .day, value: delta, to: currentDate) ?? currentDate
        Task { await load() }
    }

    func deleteMeal(_ meal: Meal) async {
        guard let userId = service.currentUser?.id else { return }
        do {
            try await service.deleteMeal(id: meal.id, for: userId)
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateMeal(_ meal: Meal, calories: Int, protein: Int, carbs: Int, fat: Int) async {
        guard let userId = service.currentUser?.id else { return }
        do {
            let updates = MealUpdate(foodName: nil, calories: calories, protein: protein, carbs: carbs, fat: fat)
            try await service.updateMeal(id: meal.id, for: userId, updates: updates)
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func reanalyzeMeal(_ meal: Meal, newName: String) async {
        guard let userId = service.currentUser?.id else { return }
        do {
            try await service.reanalyzeMeal(id: meal.id, foodName: newName, imageUrl: meal.imageUrl, for: userId)
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func analyzeImage(_ image: UIImage, hint: String) async {
        guard let userId = service.currentUser?.id else { return }
        captureState = .analyzing
        do {
            guard let data = ImageResizer.resize(image) else {
                throw NSError(domain: "SnapTrack", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not resize image"])
            }
            try await service.analyzeImage(data, hint: hint, for: userId)
            captureState = .idle
            toastMessage = "Meal logged!"
            await load()
        } catch {
            captureState = .idle
            errorMessage = error.localizedDescription
        }
    }

    func analyzeText(_ name: String) async {
        guard let userId = service.currentUser?.id else { return }
        isLoading = true
        do {
            try await service.analyzeText(name, for: userId)
            await load()
            toastMessage = "Meal logged!"
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func computeStreak(from meals: [MealDate]) -> Int {
        let keys = Set(meals.compactMap { DateUtils.parseISO($0.createdAt).map(DateUtils.dateKey) }).sorted(by: >)
        guard !keys.isEmpty else { return 0 }

        let today = DateUtils.dateKey(Date())
        var checkDate = Date()
        if keys.first != today {
            checkDate = Calendar.current.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
        }

        var streak = 0
        for key in keys {
            if key == DateUtils.dateKey(checkDate) {
                streak += 1
                checkDate = Calendar.current.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
            } else if key < DateUtils.dateKey(checkDate) {
                break
            }
        }
        return streak
    }
}

enum CaptureState {
    case idle
    case preview(UIImage)
    case analyzing
}
