import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var session: SessionManager
    @StateObject private var viewModel = AuthViewModel()
    @State private var showingRegister = false
    @State private var showingForgotPassword = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Email", text: $viewModel.email)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                    SecureField("Password", text: $viewModel.password)
                }

                Section {
                    Button {
                        Task { await viewModel.login(session: session) }
                    } label: {
                        if viewModel.isLoading {
                            ProgressView()
                        } else {
                            Label("Login", systemImage: "arrow.right.circle.fill")
                        }
                    }
                    .disabled(viewModel.isLoading)

                    Button("Create Account") {
                        showingRegister = true
                    }

                    Button("Forgot Password") {
                        showingForgotPassword = true
                    }
                }

                if let errorMessage = viewModel.errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Markeet Login")
            .sheet(isPresented: $showingRegister) {
                RegisterView()
                    .environmentObject(session)
            }
            .sheet(isPresented: $showingForgotPassword) {
                ForgotPasswordView()
            }
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(SessionManager())
}
