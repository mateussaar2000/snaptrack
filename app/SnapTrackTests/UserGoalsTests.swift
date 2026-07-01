import XCTest
@testable import SnapTrack

final class UserGoalsTests: XCTestCase {
    func testProgressClampedToOne() {
        let goals = UserGoals(calories: 2000, protein: 100, carbs: 200, fat: 60)
        let totals = (calories: 3000, protein: 150, carbs: 300, fat: 100)
        let progress = goals.progress(for: totals)
        XCTAssertEqual(progress.calories, 1.0, accuracy: 0.001)
        XCTAssertEqual(progress.protein, 1.0, accuracy: 0.001)
        XCTAssertEqual(progress.carbs, 1.0, accuracy: 0.001)
        XCTAssertEqual(progress.fat, 1.0, accuracy: 0.001)
    }

    func testProgressZeroWhenNoGoal() {
        let goals = UserGoals(calories: 0, protein: 0, carbs: 0, fat: 0)
        let totals = (calories: 100, protein: 10, carbs: 20, fat: 5)
        let progress = goals.progress(for: totals)
        XCTAssertEqual(progress.calories, 0.0, accuracy: 0.001)
        XCTAssertEqual(progress.protein, 0.0, accuracy: 0.001)
        XCTAssertEqual(progress.carbs, 0.0, accuracy: 0.001)
        XCTAssertEqual(progress.fat, 0.0, accuracy: 0.001)
    }

    func testProgressPartial() {
        let goals = UserGoals(calories: 2000, protein: 100, carbs: 200, fat: 60)
        let totals = (calories: 1000, protein: 50, carbs: 100, fat: 30)
        let progress = goals.progress(for: totals)
        XCTAssertEqual(progress.calories, 0.5, accuracy: 0.001)
        XCTAssertEqual(progress.protein, 0.5, accuracy: 0.001)
        XCTAssertEqual(progress.carbs, 0.5, accuracy: 0.001)
        XCTAssertEqual(progress.fat, 0.5, accuracy: 0.001)
    }
}
