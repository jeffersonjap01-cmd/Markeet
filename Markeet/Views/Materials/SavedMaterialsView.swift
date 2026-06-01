// SavedMaterialsView.swift
// Markeet — Premium saved materials screen

import SwiftUI

struct SavedMaterialsView: View {
    @EnvironmentObject private var session: SessionManager
    @StateObject private var viewModel = MaterialsViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "F2F2F7").ignoresSafeArea()

                if viewModel.isLoading {
                    ProgressView("Memuat materi tersimpan...")
                        .foregroundColor(AppTheme.textSecondary)
                } else if viewModel.savedMaterials.isEmpty {
                    EmptyStateView(
                        icon: "bookmark",
                        title: "Belum Ada yang Disimpan",
                        subtitle: "Ketuk ikon bookmark pada materi pembelajaran untuk menyimpannya di sini."
                    )
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: AppTheme.Spacing.sm) {
                            // Count badge
                            HStack {
                                Text("\(viewModel.savedMaterials.count) materi tersimpan")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(AppTheme.textSecondary)
                                Spacer()
                            }
                            .padding(.horizontal, AppTheme.Spacing.lg)
                            .padding(.top, AppTheme.Spacing.sm)

                            LazyVStack(spacing: AppTheme.Spacing.sm) {
                                ForEach(viewModel.savedMaterials) { material in
                                    NavigationLink {
                                        MaterialDetailView(material: material)
                                            .environmentObject(session)
                                    } label: {
                                        savedMaterialRow(material)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, AppTheme.Spacing.lg)

                            Spacer(minLength: 100)
                        }
                    }
                    .refreshable {
                        if let user = session.currentUser {
                            await viewModel.loadSavedMaterials(for: user)
                        }
                    }
                }
            }
            .navigationTitle("Materi Tersimpan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if navigationController != nil {
                        EmptyView()
                    }
                }
            }
            .task {
                if let user = session.currentUser {
                    await viewModel.loadSavedMaterials(for: user)
                }
            }
        }
    }

    // MARK: - Compact row for saved materials
    private func savedMaterialRow(_ material: MaterialModel) -> some View {
        HStack(spacing: 14) {
            // Thumbnail
            AsyncImage(url: material.thumbnailURL.flatMap(URL.init(string:))) { phase in
                switch phase {
                case .success(let img):
                    img.resizable().scaledToFill()
                default:
                    RoundedRectangle(cornerRadius: AppTheme.Radius.sm)
                        .fill(AppTheme.primary.opacity(0.1))
                        .overlay {
                            Image(systemName: "doc.text.image")
                                .font(.system(size: 18))
                                .foregroundColor(AppTheme.primary.opacity(0.4))
                        }
                }
            }
            .frame(width: 64, height: 64)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.sm))

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(material.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)
                    .lineLimit(2)

                Text(material.description)
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.textSecondary)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    ForEach(material.tags.prefix(2), id: \.self) { tag in
                        Text(tag)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(AppTheme.primary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(AppTheme.primary.opacity(0.08))
                            .cornerRadius(AppTheme.Radius.pill)
                    }
                    Spacer()
                    Text(material.createdAt.relativeTimeString)
                        .font(.system(size: 10))
                        .foregroundColor(AppTheme.textTertiary)
                }
            }

            // Unsave button
            Button {
                Task { await viewModel.toggleSaved(material: material, session: session) }
            } label: {
                Image(systemName: "bookmark.fill")
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.primary)
                    .padding(8)
                    .background(AppTheme.primary.opacity(0.1))
                    .clipShape(Circle())
            }
        }
        .padding(12)
        .background(AppTheme.surface)
        .cornerRadius(AppTheme.Radius.md)
        .shadow(color: AppTheme.Shadow.soft, radius: 6, y: 2)
    }

    // Helper to detect if we're inside a NavigationController (pushed vs presented)
    private var navigationController: Bool? {
        nil // always show title inline
    }
}

#Preview {
    SavedMaterialsView().environmentObject(SessionManager())
}
