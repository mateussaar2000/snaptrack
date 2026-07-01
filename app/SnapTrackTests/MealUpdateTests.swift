import XCTest
@testable import SnapTrack

final class MealUpdateTests: XCTestCase {
    func testNilFoodNameIsOmitted() throws {
        let update = MealUpdate(foodName: nil, calories: 100, protein: 10, carbs: 20, fat: 5)
        let data = try JSONEncoder().encode(update)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        XCTAssertNil(json?["food_name"])
        XCTAssertEqual(json?["calories"] as? Int, 100)
        XCTAssertEqual(json?["protein"] as? Int, 10)
        XCTAssertEqual(json?["carbs"] as? Int, 20)
        XCTAssertEqual(json?["fat"] as? Int, 5)
    }

    func testFoodNameIsIncludedWhenPresent() throws {
        let update = MealUpdate(foodName: "Salad", calories: nil, protein: nil, carbs: nil, fat: nil)
        let data = try JSONEncoder().encode(update)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        XCTAssertEqual(json?["food_name"] as? String, "Salad")
        XCTAssertNil(json?["calories"])
    }
}
