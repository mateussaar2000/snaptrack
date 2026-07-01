import Foundation
import Supabase

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isLoading = true
    @Published var message: UserMessage?

    init() {
        Task { await checkSession() }
    }

    func checkSession() async {
        isLoading = true
        defer { isLoading = false }
        do {
            _ = try await SupabaseService.shared.refreshSession()
            isAuthenticated = SupabaseService.shared.isAuthenticated
        } catch {
            isAuthenticated = false
        }
    }

    func signUp(email: String, password: String) async {
        guard validate(email: email, password: password) else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            try await SupabaseService.shared.signUp(email: email, password: password)
            isAuthenticated = true
            post(.success(title: "Account created"))
        } catch {
            isAuthenticated = false
            post(.error(error))
        }
    }

    func signIn(email: String, password: String) async {
        guard validate(email: email, password: password) else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            try await SupabaseService.shared.signIn(email: email, password: password)
            isAuthenticated = true
            post(.success(title: "Welcome back"))
        } catch {
            isAuthenticated = false
            post(.error(error))
        }
    }

    func signOut() async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await SupabaseService.shared.signOut()
            isAuthenticated = false
        } catch {
            post(.error(error))
        }
    }

    func resetPassword(email: String) async {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard isValidEmail(trimmed) else {
            post(.error(AppError.validation(message: "Please enter a valid email address.")))
            return
        }
        isLoading = true
        defer { isLoading = false }
        do {
            try await SupabaseService.shared.resetPassword(email: trimmed)
            post(.success(title: "Reset link sent", subtitle: "Check your email for instructions."))
        } catch {
            post(.error(error))
        }
    }

    func clearMessage() {
        message = nil
    }

    func present(_ message: UserMessage) {
        post(message)
    }

    // MARK: - Validation

    private func validate(email: String, password: String) -> Bool {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard isValidEmail(trimmedEmail) else {
            post(.error(AppError.validation(message: "Please enter a valid email address.")))
            return false
        }
        guard password.count >= 6 else {
            post(.error(AppError.validation(message: "Password must be at least 6 characters.")))
            return false
        }
        return true
    }

    private func isValidEmail(_ email: String) -> Bool {
        let regex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: email)
    }

    private func post(_ message: UserMessage) {
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
}
