// MaterialsListView.swift
// Markeet — Premium materials list matching design screenshots

import SwiftUI

struct MaterialsListView: View {
    @EnvironmentObject private var session: SessionManager
    @StateObject private var viewModel = MaterialsViewModel()
    @State private var searchText = ""

    private var filtered: [MaterialModel] {
        if searchText.isEmpty { return viewModel.materials }
        return viewModel.materials.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.description.localizedCaseInsensitiveContains(searchText) ||
            $0.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "F2F2F7").ignoresSafeArea()

                if viewModel.isLoading && viewModel.materials.isEmpty {
                    ProgressView("Memuat materi...")
                        .foregroundColor(AppTheme.textSecondary)
                } else if viewModel.materials.isEmpty {
                    EmptyStateView(
                        icon: "book.closed",
                        title: "Belum Ada Materi",
                        subtitle: "Materi pembelajaran yang diupload admin akan muncul di sini."
                    )
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: AppTheme.Spacing.md) {
                            // Tag filter pills
                            tagFilterRow

                            // Material cards
                            LazyVStack(spacing: AppTheme.Spacing.md) {
                                ForEach(filtered) { material in
                                    NavigationLink {
                                        MaterialDetailView(material: material)
                                            .environmentObject(session)
                                    } label: {
                                        materialCard(material)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, AppTheme.Spacing.lg)

                            if filtered.isEmpty && !searchText.isEmpty {
                                VStack(spacing: 8) {
                                    Image(systemName: "magnifyingglass")
                                        .font(.system(size: 36))
                                        .foregroundColor(AppTheme.textTertiary)
                                    Text("Tidak ditemukan")
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(AppTheme.textSecondary)
                                    Text("Coba kata kunci lain")
                                        .font(.system(size: 13))
                                        .foregroundColor(AppTheme.textTertiary)
                                }
                                .padding(.top, 60)
                            }

                            Spacer(minLength: 100)
                        }
                        .padding(.top, AppTheme.Spacing.sm)
                    }
                    .refreshable {
                        await viewModel.loadMaterials()
                    }
                }
            }
            .navigationTitle("📚 Materi")
            .searchable(text: $searchText, prompt: "Cari materi...")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink {
                        SavedMaterialsView()
                            .environmentObject(session)
                    } label: {
                        Image(systemName: "bookmark.fill")
                            .font(.system(size: 14))
                            .foregroundColor(AppTheme.primary)
                            .padding(8)
                            .background(AppTheme.primary.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
            }
            .task {
                if viewModel.materials.isEmpty {
                    await viewModel.loadMaterials()
                }
            }
        }
    }

    // MARK: - Tag Filter
    @ViewBuilder
    private var tagFilterRow: some View {
        let allTags = Array(Set(viewModel.materials.flatMap { $0.tags })).sorted()
        if !allTags.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(allTags, id: \.self) { tag in
                        Button {
                            if searchText == tag {
                                searchText = ""
                            } else {
                                searchText = tag
                            }
                        } label: {
                            Text(tag)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(searchText == tag ? .white : AppTheme.primary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 7)
                                .background(searchText == tag ? AppTheme.primary : AppTheme.primary.opacity(0.1))
                                .cornerRadius(AppTheme.Radius.pill)
                        }
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.lg)
            }
        }
    }

    // MARK: - Material Card
    private func materialCard(_ material: MaterialModel) -> some View {
        let saved = viewModel.isSaved(material, by: session.currentUser)

        return VStack(alignment: .leading, spacing: 0) {
            // Thumbnail
            ZStack(alignment: .topTrailing) {
                AsyncImage(url: material.thumbnailURL.flatMap(URL.init(string:))) { phase in
                    switch phase {
                    case .success(let img):
                        img.resizable().scaledToFill()
                    default:
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [AppTheme.primary.opacity(0.15), AppTheme.primary.opacity(0.05)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay {
                                Image(systemName: "doc.text.image")
                                    .font(.system(size: 32))
                                    .foregroundColor(AppTheme.primary.opacity(0.4))
                            }
                    }
                }
                .frame(height: 160)
                .frame(maxWidth: .infinity)
                .clipped()

                // Bookmark overlay
                Button {
                    Task { await viewModel.toggleSaved(material: material, session: session) }
                } label: {
                    Image(systemName: saved ? "bookmark.fill" : "bookmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(saved ? .white : .white)
                        .padding(8)
                        .background(saved ? AppTheme.primary : Color.black.opacity(0.35))
                        .clipShape(Circle())
                }
                .padding(10)
            }

            // Info
            VStack(alignment: .leading, spacing: 8) {
                Text(material.title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
                    .lineLimit(2)

                Text(material.description)
                    .font(.system(size: 13))
                    .foregroundColor(AppTheme.textSecondary)
                    .lineLimit(2)

                HStack(spacing: 6) {
                    // Tags
                    ForEach(material.tags.prefix(3), id: \.self) { tag in
                        Text(tag)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(AppTheme.primary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(AppTheme.primary.opacity(0.08))
                            .cornerRadius(AppTheme.Radius.pill)
                    }

                    Spacer()

                    Text(material.createdAt.relativeTimeString)
                        .font(.system(size: 11))
                        .foregroundColor(AppTheme.textTertiary)
                }
            }
            .padding(AppTheme.Spacing.md)
        }
        .background(AppTheme.surface)
        .cornerRadius(AppTheme.Radius.lg)
        .shadow(color: AppTheme.Shadow.soft, radius: 8, y: 2)
    }
}

#Preview {
    MaterialsListView().environmentObject(SessionManager())
}
