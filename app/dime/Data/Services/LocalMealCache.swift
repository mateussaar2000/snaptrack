import Foundation

actor LocalMealCache {
    static let shared = LocalMealCache()

    private enum Keys {
        static let mealsPrefix = "com.snaptrack.cache.meals."
        static let weeklyMacros = "com.snaptrack.cache.weeklyMacros"
    }

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private init() {}

    func meals(for date: Date) -> [Meal] {
        let key = mealsKey(for: date)
        guard let data = UserDefaults.standard.data(forKey: key),
              let meals = try? decoder.decode([Meal].self, from: data) else {
            return []
        }
        return meals
    }

    func saveMeals(_ meals: [Meal], for date: Date) {
        let key = mealsKey(for: date)
        if let data = try? encoder.encode(meals) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    func weeklyMacros() -> [DayMacros] {
        guard let data = UserDefaults.standard.data(forKey: Keys.weeklyMacros),
              let macros = try? decoder.decode([DayMacros].self, from: data) else {
            return []
        }
        return macros
    }

    func saveWeeklyMacros(_ macros: [DayMacros]) {
        if let data = try? encoder.encode(macros) {
            UserDefaults.standard.set(data, forKey: Keys.weeklyMacros)
        }
    }

    func clear() {
        let defaults = UserDefaults.standard
        defaults.dictionaryRepresentation().keys
            .filter { $0.hasPrefix(Keys.mealsPrefix) || $0 == Keys.weeklyMacros }
            .forEach { defaults.removeObject(forKey: $0) }
    }

    private func mealsKey(for date: Date) -> String {
        Keys.mealsPrefix + DateUtils.dateKey(date)
    }
}
