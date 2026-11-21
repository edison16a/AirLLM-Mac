import Foundation

/// An error whose message is already written for the person using the app.
struct AppError: LocalizedError, Equatable {
    let message: String
    init(_ message: String) { self.message = message }
    var errorDescription: String? { message }
}
