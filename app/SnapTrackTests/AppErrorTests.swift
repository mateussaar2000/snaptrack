import XCTest
@testable import SnapTrack

final class AppErrorTests: XCTestCase {
    func testNetworkMapping() {
        let networkError = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet)
        let mapped = AppError.map(networkError)
        XCTAssertEqual(mapped, .network)
    }

    func testCancelledMapping() {
        let cancelled = NSError(domain: NSURLErrorDomain, code: NSURLErrorCancelled)
        let mapped = AppError.map(cancelled)
        XCTAssertEqual(mapped, .cancelled)
    }

    func testValidationDescription() {
        let error = AppError.validation(message: "Name required")
        XCTAssertEqual(error.errorDescription, "Name required")
    }

    func testServerDescriptionFallsBack() {
        let error = AppError.server(message: "")
        XCTAssertFalse(error.localizedDescription.isEmpty)
    }
}
