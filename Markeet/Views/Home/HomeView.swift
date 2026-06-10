//
//  HomeView.swift
//  Marko
//
//  Created by student on 28/05/26.
//

import SwiftUI

/// Home tab for regular users.
/// Displays admin-managed news loaded from Firestore.
struct HomeView: View {
    // MARK: - State

    @EnvironmentObject private var session: SessionManager
    @StateObject private var viewModel = NewsViewModel()
    @StateObject private var materialsViewModel = MaterialsViewModel()
    @State private var showingAddMaterial = false

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
                            title: "No Updates Yet",
                            subtitle: "Admin updates will appear here."
                        )
                        .padding(.top, AppTheme.Spacing.xxl)
                    } else {
                        ForEach(viewModel.news) { news in
                            newsCard(news)
                                .padding(.horizontal, AppTheme.Spacing.lg)
                        }
                    }

                    materialsSection
                }
                .padding(.vertical, AppTheme.Spacing.lg)
            }
            .background(Color(hex: "F2F2F7").ignoresSafeArea())
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.inline)
            .overlay {
                if viewModel.isLoading && viewModel.news.isEmpty {
                    ProgressView()
                }
            }
            .task {
                await loadHomeData()
            }
            .refreshable {
                await loadHomeData()
            }
            .sheet(isPresented: $showingAddMaterial) {
                MaterialEditorView { title, description, videoURL, thumbnailURL, category, tags in
                    await materialsViewModel.saveMaterial(
                        existing: nil,
                        title: title,
                        description: description,
                        videoURL: videoURL,
                        thumbnailURL: thumbnailURL,
                        category: category,
                        tags: tags,
                        session: session
                    )
                }
            }
        }
    }

    private var materialsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Materi Pembelajaran")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                    Text("Video marketing terbaru dari mentor")
                        .font(.system(size: 13))
                        .foregroundColor(AppTheme.textSecondary)
                }

                Spacer()

                if session.currentUser?.role == .mentor {
                    Button {
                        showingAddMaterial = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 34, height: 34)
                            .background(AppTheme.primary)
                            .clipShape(Circle())
                    }
                }
            }
            .padding(.horizontal, AppTheme.Spacing.lg)
            .padding(.top, AppTheme.Spacing.md)

            if materialsViewModel.isLoading && materialsViewModel.materials.isEmpty {
                ProgressView("Loading materials...")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppTheme.Spacing.lg)
            } else if materialsViewModel.materials.isEmpty {
                EmptyStateView(
                    icon: "play.rectangle",
                    title: "Belum ada materi pembelajaran.",
                    subtitle: session.currentUser?.role == .mentor ? "Tap Add to upload your first video material." : "Video materials uploaded by mentors will appear here."
                )
                .padding(.horizontal, AppTheme.Spacing.lg)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppTheme.Spacing.md) {
                        ForEach(materialsViewModel.materials.prefix(6)) { material in
                            NavigationLink {
                                MaterialDetailView(material: material)
                                    .environmentObject(session)
                            } label: {
                                homeMaterialCard(material)
                            }
                            .buttonStyle(.plain)
                        }

                        NavigationLink {
                            MaterialsListView()
                                .environmentObject(session)
                        } label: {
                            VStack(spacing: AppTheme.Spacing.sm) {
                                Image(systemName: "arrow.right.circle.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(AppTheme.primary)
                                Text("View All")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(AppTheme.textPrimary)
                            }
                            .frame(width: 140, height: 210)
                            .background(AppTheme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.lg))
                            .shadow(color: AppTheme.Shadow.soft, radius: 8, y: 2)
                        }
                    }
                    .padding(.horizontal, AppTheme.Spacing.lg)
                }
            }
        }
    }

    private func homeMaterialCard(_ material: MaterialModel) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack(alignment: .center) {
                AsyncImage(url: material.thumbnailURL.flatMap(URL.init(string:))) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    default:
                        Rectangle()
                            .fill(AppTheme.primary.opacity(0.12))
                            .overlay {
                                Image(systemName: "play.rectangle.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(AppTheme.primary.opacity(0.45))
                            }
                    }
                }
                .frame(height: 105)
                .frame(maxWidth: .infinity)
                .clipped()

                Image(systemName: "play.circle.fill")
                    .font(.system(size: 34))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.25), radius: 6, y: 2)
            }
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.md))

            Text(material.title)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(AppTheme.textPrimary)
                .lineLimit(2)

            Text(material.mentorName)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(AppTheme.textSecondary)
                .lineLimit(1)

            Text(material.createdAt.relativeTimeString)
                .font(.system(size: 10))
                .foregroundColor(AppTheme.textTertiary)
        }
        .padding(AppTheme.Spacing.sm)
        .frame(width: 210, height: 210, alignment: .topLeading)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.lg))
        .shadow(color: AppTheme.Shadow.soft, radius: 8, y: 2)
    }

    private func loadHomeData() async {
        await viewModel.loadNews()
        await materialsViewModel.loadMaterials()
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
