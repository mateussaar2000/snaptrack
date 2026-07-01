import Foundation
import Network

@MainActor
final class NutritionStore: ObservableObject {
    @Published var meals: [Meal] = []
    @Published var weeklyMacros: [DayMacros] = []
    @Published var selectedDate: Date = Date()
    @Published var isLoading: Bool = false
    @Published var isAnalyzing: Bool = false
    @Published var message: UserMessage?
    @Published var isOffline: Bool = false

    var totals: (calories: Int, protein: Int, carbs: Int, fat: Int) {
        meals.reduce((0, 0, 0, 0)) { acc, meal in
            (acc.calories + meal.calories, acc.protein + meal.protein, acc.carbs + meal.carbs, acc.fat + meal.fat)
        }
    }

    private var currentUserId: UUID? {
        SupabaseService.shared.currentUser?.id
    }

    init() {
        Task { @MainActor in
            for await value in NetworkMonitor.shared.$isConnected.values {
                self.isOffline = !value
            }
        }
    }

    // MARK: - Load

    func load() async {
        await loadMeals(for: selectedDate)
        await loadWeeklyMacros()
    }

    func loadMeals(for date: Date) async {
        guard let userId = currentUserId else {
            post(.error(AppError.unauthorized))
            return
        }
        if isOffline {
            meals = await LocalMealCache.shared.meals(for: date)
            if meals.isEmpty {
                post(.error(AppError.network))
            }
            return
        }
        isLoading = true
        defer { isLoading = false }
        do {
            let fetched = try await SupabaseService.shared.fetchMeals(for: userId, on: date)
            try Task.checkCancellation()
            meals = fetched
            await LocalMealCache.shared.saveMeals(fetched, for: date)
        } catch is CancellationError {
            // Ignore cancellation.
        } catch {
            let cached = await LocalMealCache.shared.meals(for: date)
            if !cached.isEmpty {
                meals = cached
                post(.info(title: "Offline mode", subtitle: "Showing cached meals."))
            } else {
                post(.error(error))
            }
        }
    }

    func loadWeeklyMacros() async {
        guard let userId = currentUserId else { return }
        if isOffline {
            weeklyMacros = await LocalMealCache.shared.weeklyMacros()
            return
        }
        do {
            let macros = try await SupabaseService.shared.fetchWeeklyMacros(for: userId)
            try Task.checkCancellation()
            weeklyMacros = macros
            await LocalMealCache.shared.saveWeeklyMacros(macros)
        } catch is CancellationError {
            // Ignore cancellation.
        } catch {
            let cached = await LocalMealCache.shared.weeklyMacros()
            if !cached.isEmpty {
                weeklyMacros = cached
            } else {
                post(.error(error))
            }
        }
    }

    // MARK: - Date navigation

    func changeDay(by delta: Int) {
        guard let newDate = Calendar.current.date(byAdding: .day, value: delta, to: selectedDate) else { return }
        selectedDate = newDate
    }

    func resetToToday() {
        selectedDate = Date()
    }

    // MARK: - Mutations

    func deleteMeal(_ meal: Meal) async {
        guard let userId = currentUserId else {
            post(.error(AppError.unauthorized))
            return
        }
        do {
            try await SupabaseService.shared.deleteMeal(id: meal.id, for: userId)
            await load()
            post(.success(title: "Meal deleted"))
        } catch {
            post(.error(error))
        }
    }

    func updateMeal(
        _ meal: Meal,
        foodName: String? = nil,
        calories: Int,
        protein: Int,
        carbs: Int,
        fat: Int
    ) async {
        guard let userId = currentUserId else {
            post(.error(AppError.unauthorized))
            return
        }
        do {
            let updates = MealUpdate(
                foodName: foodName?.trimmingCharacters(in: .whitespacesAndNewlines),
                calories: calories,
                protein: protein,
                carbs: carbs,
                fat: fat
            )
            try await SupabaseService.shared.updateMeal(id: meal.id, for: userId, updates: updates)
            await load()
            post(.success(title: "Meal updated"))
        } catch {
            post(.error(error))
        }
    }

    func analyzeImage(_ imageData: Data, hint: String) async {
        guard let userId = currentUserId else {
            post(.error(AppError.unauthorized))
            return
        }
        guard !isOffline else {
            post(.error(AppError.network))
            return
        }
        isAnalyzing = true
        defer { isAnalyzing = false }
        do {
            try await SupabaseService.shared.analyzeImage(imageData, hint: hint.trimmingCharacters(in: .whitespacesAndNewlines), for: userId)
            await load()
            post(.success(title: "Meal logged!"))
        } catch {
            post(.error(error))
        }
    }

    func analyzeText(_ foodName: String) async {
        guard let userId = currentUserId else {
            post(.error(AppError.unauthorized))
            return
        }
        guard !isOffline else {
            post(.error(AppError.network))
            return
        }
        isAnalyzing = true
        defer { isAnalyzing = false }
        let cleaned = foodName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else {
            post(.error(AppError.validation(message: "Please describe what you ate.")))
            return
        }
        do {
            try await SupabaseService.shared.analyzeText(cleaned, for: userId)
            await load()
            post(.success(title: "Meal logged!"))
        } catch {
            post(.error(error))
        }
    }

    func addManualMeal(
        foodName: String,
        calories: Int,
        protein: Int,
        carbs: Int,
        fat: Int
    ) async {
        guard let userId = currentUserId else {
            post(.error(AppError.unauthorized))
            return
        }
        guard !isOffline else {
            post(.error(AppError.network))
            return
        }
        isAnalyzing = true
        defer { isAnalyzing = false }
        let cleaned = foodName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else {
            post(.error(AppError.validation(message: "Please enter a food name.")))
            return
        }
        guard calories >= 0, protein >= 0, carbs >= 0, fat >= 0 else {
            post(.error(AppError.validation(message: "Macros cannot be negative.")))
            return
        }
        do {
            _ = try await SupabaseService.shared.createMeal(
                foodName: cleaned,
                calories: calories,
                protein: protein,
                carbs: carbs,
                fat: fat,
                for: userId
            )
            await load()
            post(.success(title: "Meal added!"))
        } catch {
            post(.error(error))
        }
    }

    func reanalyzeMeal(_ meal: Meal, newName: String) async {
        guard let userId = currentUserId else {
            post(.error(AppError.unauthorized))
            return
        }
        guard !isOffline else {
            post(.error(AppError.network))
            return
        }
        isAnalyzing = true
        defer { isAnalyzing = false }
        let cleaned = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else {
            post(.error(AppError.validation(message: "Please enter a food name.")))
            return
        }
        do {
            try await SupabaseService.shared.reanalyzeMeal(id: meal.id, foodName: cleaned, imageUrl: meal.imageUrl, for: userId)
            await load()
            post(.success(title: "Meal reanalyzed"))
        } catch {
            post(.error(error))
        }
    }

    // MARK: - Messaging

    func post(_ message: UserMessage) {
        self.message = message
        if let duration = message.dismissAfter {
            Task { [weak self] in
                try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
                await MainActor.run {
                    if self?.message?.id == message.id {
                        self?.message = nil
                    }
                }
            }
        }
    }

    func clearMessage() {
        message = nil
    }
}
