import SwiftUI

struct InterestOnboardingView: View {
    @EnvironmentObject private var session: SessionManager
    @StateObject private var viewModel = InterestOnboardingViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Pilih Topik Marketing")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(AppTheme.textPrimary)

                        Text("Kami akan merekomendasikan komunitas berdasarkan minat yang kamu pilih.")
                            .font(.system(size: 15))
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    .padding(.horizontal, AppTheme.Spacing.lg)
                    .padding(.top, AppTheme.Spacing.lg)

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 10)], spacing: 10) {
                        ForEach(AppConstants.marketingInterests, id: \.self) { interest in
                            Button {
                                viewModel.toggleInterest(interest)
                            } label: {
                                HStack {
                                    Text(interest)
                                        .font(.system(size: 14, weight: .semibold))
                                        .multilineTextAlignment(.leading)

                                    Spacer(minLength: 8)

                                    Image(systemName: viewModel.selectedInterests.contains(interest) ? "checkmark.circle.fill" : "circle")
                                }
                                .foregroundColor(viewModel.selectedInterests.contains(interest) ? AppTheme.primary : AppTheme.textPrimary)
                                .padding(12)
                                .frame(minHeight: 58)
                                .background(viewModel.selectedInterests.contains(interest) ? AppTheme.primary.opacity(0.12) : AppTheme.surface)
                                .cornerRadius(AppTheme.Radius.md)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, AppTheme.Spacing.lg)

                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(AppTheme.error)
                            .padding(.horizontal, AppTheme.Spacing.lg)
                    }

                    Button {
                        Task {
                            await viewModel.save(session: session)
                        }
                    } label: {
                        if viewModel.isLoading {
                            ProgressView()
                        } else {
                            Text("Lanjut")
                        }
                    }
                    .primaryButton(isEnabled: !viewModel.selectedInterests.isEmpty && !viewModel.isLoading)
                    .disabled(viewModel.selectedInterests.isEmpty || viewModel.isLoading)
                    .padding(.horizontal, AppTheme.Spacing.lg)
                    .padding(.bottom, AppTheme.Spacing.xl)
                }
            }
            .background(Color(hex: "F2F2F7").ignoresSafeArea())
        }
    }
}

#Preview {
    InterestOnboardingView()
        .environmentObject(SessionManager())
}
