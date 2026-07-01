import XCTest
@testable import SnapTrack

final class DateUtilsTests: XCTestCase {
    func testDateKeyFormat() {
        var components = DateComponents()
        components.year = 2026
        components.month = 7
        components.day = 1
        let date = Calendar.current.date(from: components)!
        let key = DateUtils.dateKey(date)
        XCTAssertEqual(key, "2026-07-01")
    }

    func testStartOfDayBeforeEndOfDay() {
        let now = Date()
        let start = DateUtils.startOfDay(now)
        let end = DateUtils.endOfDay(now)
        XCTAssertLessThan(start, end)
        XCTAssertTrue(Calendar.current.isDate(start, inSameDayAs: now))
        XCTAssertTrue(Calendar.current.isDate(end, inSameDayAs: now))
    }

    func testISOStringRoundTrip() {
        let now = Date()
        let iso = DateUtils.isoString(from: now)
        XCTAssertFalse(iso.isEmpty)
        let parsed = DateUtils.parseISO(iso)
        XCTAssertNotNil(parsed)
    }
}
