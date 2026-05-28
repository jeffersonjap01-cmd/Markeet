import SwiftUI

struct RegisterView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var session: SessionManager
    @StateObject private var viewModel = AuthViewModel()

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Full name", text: $viewModel.fullName)
                    TextField("Email", text: $viewModel.email)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                    SecureField("Password", text: $viewModel.password)
                    SecureField("Confirm password", text: $viewModel.confirmPassword)
                }

                Section {
                    Button {
                        Task {
                            await viewModel.register(session: session)
                            if viewModel.errorMessage == nil {
                                dismiss()
                            }
                        }
                    } label: {
                        if viewModel.isLoading {
                            ProgressView()
                        } else {
                            Label("Register", systemImage: "person.badge.plus")
                        }
                    }
                    .disabled(viewModel.isLoading)
                }

                Section("Onboarding") {
                    Text("New accounts start as Default User and receive a 7-day onboarding window for admin consultation and community recommendation.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }

                if let errorMessage = viewModel.errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Create Account")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    RegisterView()
        .environmentObject(SessionManager())
}
