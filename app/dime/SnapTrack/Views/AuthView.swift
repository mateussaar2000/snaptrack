import SwiftUI

struct AuthView: View {
    @EnvironmentObject var auth: AuthViewModel
    let onClose: (() -> Void)?

    @State private var mode = AuthMode.login
    @State private var email = ""
    @State private var password = ""
    @State private var isPasswordVisible = false
    @State private var shakeAmount: CGFloat = 0
    @State private var fieldErrors = AuthFieldErrors()

    init(onClose: (() -> Void)? = nil) {
        self.onClose = onClose
    }

    private var isFormValid: Bool {
        email.isValidEmail && password.count >= 6
    }

    var body: some View {
        VStack(spacing: 0) {
            // Drag handle
            RoundedRectangle(cornerRadius: 2.5)
                .fill(Color(.systemGray4))
                .frame(width: 40, height: 5)
                .padding(.top, 12)
                .padding(.bottom, 8)

            if let onClose {
                HStack {
                    Spacer()
                    Button {
                        Haptics.light()
                        onClose()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .frame(width: 32, height: 32)
                            .background(AppColor.surfaceSecondary)
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 20)
            }

            VStack(spacing: 24) {
                VStack(spacing: 6) {
                    Text(mode == .login ? "Welcome back" : "Create account")
                        .font(AppFont.title)
                    Text(mode == .login ? "Log in to continue tracking" : "Start your nutrition journey today")
                        .font(AppFont.body)
                        .foregroundStyle(.secondary)
                }

                // Mode tabs
                HStack(spacing: 0) {
                    ForEach(AuthMode.allCases, id: \.self) { m in
                        Button {
                            Haptics.select()
                            withAnimation(AppAnimation.spring) { mode = m }
                        } label: {
                            Text(m.title)
                                .font(AppFont.callout)
                                .foregroundStyle(mode == m ? .white : .primary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(mode == m ? AppColor.primary : Color.clear)
                                .clipShape(Capsule())
                        }
                    }
                }
                .padding(4)
                .background(AppColor.surfaceSecondary)
                .clipShape(Capsule())

                // Error banner
                if let error = auth.errorMessage {
                    HStack(spacing: 10) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundStyle(AppColor.destructive)
                        Text(error)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                        Spacer()
                    }
                    .padding(14)
                    .background(AppColor.destructive.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(AppColor.destructive.opacity(0.15), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                VStack(spacing: 14) {
                    inputField(
                        icon: "envelope.fill",
                        placeholder: "Email",
                        text: $email,
                        keyboard: .emailAddress,
                        contentType: .emailAddress,
                        error: fieldErrors.email
                    )
                    .textInputAutocapitalization(.never)
                    .onChange(of: email) { _ in validate() }

                    passwordField
                        .onChange(of: password) { _ in validate() }
                }
                .offset(x: shakeAmount)

                Button {
                    attemptAuth()
                } label: {
                    HStack(spacing: 10) {
                        if auth.isLoading {
                            ProgressView()
                                .tint(.white)
                        }
                        Text(mode == .login ? "Log In" : "Create Account")
                    }
                    .primaryButton(isLoading: auth.isLoading, isDisabled: !isFormValid || auth.isLoading)
                }
                .disabled(!isFormValid || auth.isLoading)
                .pressable()
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 28)
        }
    }

    private var passwordField: some View {
        HStack(spacing: 12) {
            Image(systemName: "lock.fill")
                .foregroundStyle(AppColor.primary)
                .frame(width: 20)

            Group {
                if isPasswordVisible {
                    TextField("Password", text: $password)
                } else {
                    SecureField("Password", text: $password)
                }
            }
            .font(AppFont.body)
            .textContentType(mode == .login ? .password : .newPassword)

            Button {
                Haptics.light()
                isPasswordVisible.toggle()
            } label: {
                Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(AppColor.surfaceSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(fieldErrors.password != nil ? AppColor.destructive : AppColor.separator.opacity(0.5), lineWidth: 1)
        )
    }

    private func inputField(
        icon: String,
        placeholder: String,
        text: Binding<String>,
        keyboard: UIKeyboardType,
        contentType: UITextContentType,
        error: String?
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(AppColor.primary)
                .frame(width: 20)
            TextField(placeholder, text: text)
                .font(AppFont.body)
                .keyboardType(keyboard)
                .textContentType(contentType)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(AppColor.surfaceSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(error != nil ? AppColor.destructive : AppColor.separator.opacity(0.5), lineWidth: 1)
        )
    }

    private func validate() {
        fieldErrors.email = email.isEmpty || email.isValidEmail ? nil : "Please enter a valid email"
        fieldErrors.password = password.isEmpty || password.count >= 6 ? nil : "Password must be at least 6 characters"
    }

    private func attemptAuth() {
        Haptics.medium()
        if !isFormValid {
            withAnimation(AppAnimation.spring) {
                shakeAmount = 10
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(AppAnimation.spring) { shakeAmount = -10 }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(AppAnimation.spring) { shakeAmount = 0 }
            }
            Haptics.error()
            return
        }

        Task {
            if mode == .login {
                await auth.signIn(email: email, password: password)
            } else {
                await auth.signUp(email: email, password: password)
            }
            if auth.isAuthenticated {
                Haptics.success()
                onClose?()
            } else {
                Haptics.error()
            }
        }
    }
}

struct AuthFieldErrors {
    var email: String?
    var password: String?
}

enum AuthMode: CaseIterable {
    case login, signup

    var title: String {
        switch self {
        case .login: return "Log In"
        case .signup: return "Sign Up"
        }
    }
}

extension String {
    var isValidEmail: Bool {
        let regex = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: self)
    }
}
