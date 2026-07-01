import SwiftUI

struct SnapTrackAuthView: View {
    @EnvironmentObject var auth: AuthViewModel
    @FocusState private var focusedField: AuthField?

    @State private var isLogin = true
    @State private var email = ""
    @State private var password = ""
    @State private var showResetSheet = false

    private enum AuthField: Hashable {
        case email, password, resetEmail
    }

    private var isValid: Bool {
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && password.count >= 6
    }

    var body: some View {
        ZStack {
            Color.PrimaryBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    Spacer(minLength: 40)

                    VStack(spacing: 8) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 56, weight: .bold))
                            .foregroundColor(Color.DarkIcon)
                            .frame(width: 110, height: 110)
                            .background(Color.SecondaryBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 32))

                        Text("SnapTrack")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(Color.PrimaryText)

                        Text("Snap a meal, track your macros")
                            .font(.subheadline)
                            .foregroundColor(Color.SubtitleText)
                    }

                    Spacer(minLength: 40)

                    VStack(spacing: 16) {
                        Picker("", selection: $isLogin) {
                            Text("Log In").tag(true)
                            Text("Sign Up").tag(false)
                        }
                        .pickerStyle(.segmented)
                        .colorMultiply(Color.DarkBackground)

                        VStack(spacing: 12) {
                            TextField("Email", text: $email)
                                .textContentType(.emailAddress)
                                .keyboardType(.emailAddress)
                                .textInputAutocapitalization(.never)
                                .focused($focusedField, equals: .email)
                                .submitLabel(.next)
                                .onSubmit { focusedField = .password }
                                .padding()
                                .background(Color.SecondaryBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 16))

                            SecureField("Password", text: $password)
                                .textContentType(.password)
                                .focused($focusedField, equals: .password)
                                .submitLabel(.go)
                                .onSubmit { submit() }
                                .padding()
                                .background(Color.SecondaryBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        }

                        if isLogin {
                            Button {
                                showResetSheet = true
                            } label: {
                                Text("Forgot password?")
                                    .font(.subheadline)
                                    .foregroundColor(Color.DarkBackground)
                            }
                            .frame(maxWidth: .infinity, alignment: .trailing)
                        }

                        Button {
                            submit()
                        } label: {
                            HStack {
                                if auth.isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text(isLogin ? "Log In" : "Create Account")
                                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(isValid ? Color.DarkBackground : Color.DarkBackground.opacity(0.4))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .disabled(!isValid || auth.isLoading)
                    }
                    .padding(.horizontal, 24)

                    Spacer(minLength: 40)
                }
                .padding(.vertical)
            }
        }
        .overlay(
            MessageToast(message: $auth.message),
            alignment: .top
        )
        .sheet(isPresented: $showResetSheet) {
            ResetPasswordSheet(email: email)
                .environmentObject(auth)
        }
    }

    private func submit() {
        focusedField = nil
        Task {
            if isLogin {
                await auth.signIn(email: email, password: password)
            } else {
                await auth.signUp(email: email, password: password)
            }
        }
    }
}

struct ResetPasswordSheet: View {
    @EnvironmentObject var auth: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focused: Bool

    @State var email: String

    var body: some View {
        NavigationStack {
            ZStack {
                Color.PrimaryBackground.ignoresSafeArea()

                VStack(spacing: 20) {
                    Text("Enter your email and we’ll send you a reset link.")
                        .font(.subheadline)
                        .foregroundColor(Color.SubtitleText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .focused($focused)
                        .padding()
                        .background(Color.SecondaryBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal)

                    Button {
                        Task {
                            await auth.resetPassword(email: email)
                            if auth.message?.color == Color.IncomeGreen {
                                dismiss()
                            }
                        }
                    } label: {
                        HStack {
                            if auth.isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Send Reset Link")
                                    .font(.headline)
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(email.isEmpty || auth.isLoading ? Color.DarkBackground.opacity(0.4) : Color.DarkBackground)
                        .cornerRadius(12)
                    }
                    .disabled(email.isEmpty || auth.isLoading)
                    .padding(.horizontal)

                    Spacer()
                }
                .padding(.top, 20)
            }
            .navigationTitle("Reset Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Color.DarkBackground)
                }
            }
        }
        .overlay(
            MessageToast(message: $auth.message),
            alignment: .top
        )
        .onAppear { focused = true }
    }
}
