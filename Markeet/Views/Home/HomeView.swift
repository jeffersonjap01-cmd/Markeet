//
//  HomeView.swift
//  Marko
//
//  Created by student on 28/05/26.
//

import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = NewsViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(AppTheme.error)
                            .padding(.horizontal, AppTheme.Spacing.lg)
                    }

                    if viewModel.news.isEmpty && !viewModel.isLoading {
                        EmptyStateView(
                            icon: "newspaper",
                            title: "Belum Ada Update",
                            subtitle: "Update dari admin akan muncul di sini."
                        )
                        .padding(.top, AppTheme.Spacing.xxl)
                    } else {
                        ForEach(viewModel.news) { news in
                            newsCard(news)
                                .padding(.horizontal, AppTheme.Spacing.lg)
                        }
                    }
                }
                .padding(.vertical, AppTheme.Spacing.lg)
            }
            .background(Color(hex: "F2F2F7").ignoresSafeArea())
            .navigationTitle("Beranda")
            .navigationBarTitleDisplayMode(.inline)
            .overlay {
                if viewModel.isLoading && viewModel.news.isEmpty {
                    ProgressView()
                }
            }
            .task {
                await viewModel.loadNews()
            }
            .refreshable {
                await viewModel.loadNews()
            }
        }
    }

    private func newsCard(_ news: NewsModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if let imageURL = news.imageURL, let url = URL(string: imageURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    default:
                        Rectangle()
                            .fill(AppTheme.primary.opacity(0.12))
                            .overlay {
                                Image(systemName: "newspaper.fill")
                                    .foregroundColor(AppTheme.primary)
                            }
                    }
                }
                .frame(height: 160)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.md))
            }

            HStack {
                Text(news.category.isEmpty ? "Update" : news.category)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(AppTheme.primary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AppTheme.primary.opacity(0.12))
                    .cornerRadius(AppTheme.Radius.pill)

                Spacer()

                Text(news.createdAt.relativeTimeString)
                    .font(.system(size: 11))
                    .foregroundColor(AppTheme.textTertiary)
            }

            Text(news.title)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(AppTheme.textPrimary)

            Text(news.description)
                .font(.system(size: 14))
                .foregroundColor(AppTheme.textSecondary)
                .lineSpacing(4)
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.surface)
        .cornerRadius(AppTheme.Radius.lg)
        .shadow(color: AppTheme.Shadow.soft, radius: 8, y: 2)
    }
}

#Preview {
    HomeView()
}
