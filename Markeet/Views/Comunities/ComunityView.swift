//
//  ComunityView.swift
//  Marko
//
//  Created by student on 28/05/26.
//

import SwiftUI

struct ComunityView: View {
    @EnvironmentObject private var session: SessionManager
    @StateObject private var viewModel = CommunityDiscoveryViewModel()

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

                Section("Recommended For You") {
                    if viewModel.recommendations.isEmpty && !viewModel.isLoading {
                        Text("No matching communities are available right now.")
                            .foregroundColor(AppTheme.textSecondary)
                    }

                    ForEach(viewModel.recommendations) { item in
                        communityRow(item)
                    }
                }

                Section("All Communities") {
                    if viewModel.allCommunities.isEmpty && !viewModel.isLoading {
                        Text("No communities available.")
                            .foregroundColor(AppTheme.textSecondary)
                    }

                    ForEach(viewModel.allCommunities) { item in
                        communityRow(item)
                    }
                }
            }
            .navigationTitle("Komunitas")
            .navigationBarTitleDisplayMode(.inline)
            .overlay {
                if viewModel.isLoading && viewModel.allCommunities.isEmpty {
                    ProgressView()
                }
            }
            .task {
                await viewModel.load(session: session)
            }
            .refreshable {
                await viewModel.load(session: session)
            }
        }
    }

    private func communityRow(_ item: CommunityDiscoveryItem) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(item.group.groupName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppTheme.textPrimary)

                    Text("\(item.group.members.count)/\(min(item.group.maxMembers, AppConstants.maxGroupMembers)) members")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.textSecondary)
                }

                Spacer()

                if item.score > 0 {
                    RoleBadge(role: "\(item.score) match", color: AppTheme.primary)
                }
            }

            if !item.group.tags.isEmpty {
                FlowLayout(spacing: 6) {
                    ForEach(item.group.tags, id: \.self) { tag in
                        Text(tag)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(AppTheme.primary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(AppTheme.primary.opacity(0.1))
                            .cornerRadius(AppTheme.Radius.pill)
                    }
                }
            }

            Button {
                Task {
                    await viewModel.join(item, session: session)
                }
            } label: {
                Label(item.alreadyJoined ? "Joined" : "Join Community", systemImage: item.alreadyJoined ? "checkmark.circle.fill" : "person.badge.plus")
            }
            .buttonStyle(.borderedProminent)
            .disabled(!item.canJoin || item.alreadyJoined || viewModel.isLoading)
        }
        .padding(.vertical, 6)
    }
}
#Preview {
    ComunityView()
        .environmentObject(SessionManager())
}
