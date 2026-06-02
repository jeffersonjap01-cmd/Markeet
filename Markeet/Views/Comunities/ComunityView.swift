//
//  ComunityView.swift
//  Marko
//
//  Created by student on 28/05/26.
//

import SwiftUI

struct ComunityView: View {
    @EnvironmentObject private var session: SessionManager
    @StateObject private var viewModel = CommunityRecommendationsViewModel()

    var body: some View {
        NavigationStack {
            List {
                if let successMessage = viewModel.successMessage {
                    Text(successMessage)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(AppTheme.success)
                }

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(AppTheme.error)
                }

                Section("Recommendations") {
                    if viewModel.recommendations.isEmpty && !viewModel.isLoading {
                        Text("No community recommendations.")
                            .foregroundColor(AppTheme.textSecondary)
                    }

                    ForEach(viewModel.recommendations) { recommendation in
                        let group = viewModel.groupsById[recommendation.communityId]

                        VStack(alignment: .leading, spacing: 10) {
                            Text(group?.groupName ?? "Community")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(AppTheme.textPrimary)

                            if let group {
                                Text("\(group.members.count)/\(min(group.maxMembers, AppConstants.maxGroupMembers)) members")
                                    .font(.system(size: 12))
                                    .foregroundColor(AppTheme.textSecondary)
                            }

                            HStack {
                                Button {
                                    Task {
                                        await viewModel.accept(recommendation, session: session)
                                    }
                                } label: {
                                    Label("Accept", systemImage: "checkmark.circle.fill")
                                }
                                .buttonStyle(.borderedProminent)

                                Button(role: .destructive) {
                                    Task {
                                        await viewModel.reject(recommendation, session: session)
                                    }
                                } label: {
                                    Label("Reject", systemImage: "xmark.circle")
                                }
                                .buttonStyle(.bordered)
                            }
                            .font(.system(size: 13, weight: .medium))
                        }
                        .padding(.vertical, 6)
                    }
                }
            }
            .navigationTitle("Komunitas")
            .navigationBarTitleDisplayMode(.inline)
            .overlay {
                if viewModel.isLoading && viewModel.recommendations.isEmpty {
                    ProgressView()
                }
            }
            .task {
                if let userId = session.currentUser?.uid {
                    await viewModel.load(userId: userId)
                }
            }
            .refreshable {
                if let userId = session.currentUser?.uid {
                    await viewModel.load(userId: userId)
                }
            }
        }
    }
}

#Preview {
    ComunityView()
        .environmentObject(SessionManager())
}
