import Foundation

enum AppError: LocalizedError, Equatable {
    case network
    case server(message: String)
    case unauthorized
    case validation(message: String)
    case notFound
    case cancelled
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .network:
            return "No internet connection. Please check your network and try again."
        case .server(let message):
            return message.isEmpty ? "Something went wrong on our end. Please try again." : message
        case .unauthorized:
            return "Your session has expired. Please sign in again."
        case .validation(let message):
            return message
        case .notFound:
            return "The requested item could not be found."
        case .cancelled:
            return "Request was cancelled."
        case .unknown(let error):
            return error.localizedDescription
        }
    }

    static func map(_ error: Error) -> AppError {
        if let appError = error as? AppError {
            return appError
        }
        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain {
            switch nsError.code {
            case NSURLErrorNotConnectedToInternet,
                 NSURLErrorNetworkConnectionLost,
                 NSURLErrorTimedOut,
                 NSURLErrorCannotConnectToHost,
                 NSURLErrorDNSLookupFailed:
                return .network
            case NSURLErrorCancelled:
                return .cancelled
            default:
                break
            }
        }
        let message = nsError.localizedDescription
        if message.lowercased().contains("unauthorized") || message.lowercased().contains("session") {
            return .unauthorized
        }
        return .unknown(error)
    }

    static func == (lhs: AppError, rhs: AppError) -> Bool {
        switch (lhs, rhs) {
        case (.network, .network), (.unauthorized, .unauthorized), (.notFound, .notFound), (.cancelled, .cancelled):
            return true
        case (.server(let a), .server(let b)):
            return a == b
        case (.validation(let a), .validation(let b)):
            return a == b
        case (.unknown, .unknown):
            // Two unknown errors are never considered equal for Identifiable purposes.
            return false
        default:
            return false
        }
    }
}
