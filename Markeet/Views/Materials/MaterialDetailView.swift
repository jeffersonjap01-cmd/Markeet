// MaterialDetailView.swift
// Markeet — Premium material detail screen

import SwiftUI

/// Detail view for one learning material.
/// Save state is stored as a material id on the current user document.
struct MaterialDetailView: View {
    // MARK: - State

    @EnvironmentObject private var session: SessionManager
    @StateObject private var viewModel = MaterialsViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showingEdit = false
    @State private var showingDeleteConfirmation = false

    let material: MaterialModel

    private var isSaved: Bool {
        viewModel.isSaved(material, by: session.currentUser)
    }

    var body: some View {
        ZStack {
            Color(hex: "F2F2F7").ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {

                    // ── Hero Image ───────────────────────────
                    ZStack(alignment: .bottomLeading) {
                        AsyncImage(url: material.thumbnailURL.flatMap(URL.init(string:))) { phase in
                            switch phase {
                            case .success(let img):
                                img.resizable().scaledToFill()
                            default:
                                Rectangle()
                                    .fill(
                                        LinearGradient(
                                            colors: [AppTheme.primary.opacity(0.2), AppTheme.primary.opacity(0.05)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .overlay {
                                        Image(systemName: "book.fill")
                                            .font(.system(size: 48))
                                            .foregroundColor(AppTheme.primary.opacity(0.3))
                                    }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 240)
                        .clipped()

                        // Gradient overlay at bottom
                        LinearGradient(
                            colors: [Color.clear, Color.black.opacity(0.5)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 120)

                        // Tags on image
                        if !material.tags.isEmpty {
                            HStack(spacing: 6) {
                                ForEach(material.tags.prefix(3), id: \.self) { tag in
                                    Text(tag)
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .background(AppTheme.primary.opacity(0.9))
                                        .cornerRadius(AppTheme.Radius.pill)
                                }
                            }
                            .padding(AppTheme.Spacing.md)
                        }
                    }

                    // ── Content Card ─────────────────────────
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {

                        // Title
                        Text(material.title)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(AppTheme.textPrimary)

                        // Meta info row
                        HStack(spacing: AppTheme.Spacing.md) {
                            HStack(spacing: 6) {
                                Image(systemName: "calendar")
                                    .font(.system(size: 12))
                                    .foregroundColor(AppTheme.textTertiary)
                                Text(material.createdAt.formatted(date: .abbreviated, time: .omitted))
                                    .font(.system(size: 12))
                                    .foregroundColor(AppTheme.textSecondary)
                            }

                            HStack(spacing: 6) {
                                Image(systemName: "person.circle")
                                    .font(.system(size: 12))
                                    .foregroundColor(AppTheme.textTertiary)
                                Text(material.mentorName)
                                    .font(.system(size: 12))
                                    .foregroundColor(AppTheme.textSecondary)
                            }

                            Spacer()
                        }

                        // Divider
                        Rectangle()
                            .fill(AppTheme.divider)
                            .frame(height: 1)

                        // Description
                        Text("Description")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppTheme.textTertiary)
                            .textCase(.uppercase)
                            .tracking(0.6)

                        Text(material.description)
                            .font(.system(size: 15))
                            .foregroundColor(AppTheme.textPrimary)
                            .lineSpacing(5)

                        // Video player
                        Text("Video")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppTheme.textTertiary)
                            .textCase(.uppercase)
                            .tracking(0.6)

                        if let videoId = YouTubeVideoHelper.extractVideoId(from: material.displayVideoURL) {
                            YouTubePlayerView(videoId: videoId)
                                .aspectRatio(16 / 9, contentMode: .fit)
                                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.md))
                        } else {
                            InvalidVideoURLView()
                        }

                        // Tags section
                        if !material.tags.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Category")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(AppTheme.textTertiary)
                                    .textCase(.uppercase)
                                    .tracking(0.6)

                                FlowLayout(spacing: 8) {
                                    ForEach(material.tags, id: \.self) { tag in
                                        HStack(spacing: 4) {
                                            Image(systemName: "tag.fill")
                                                .font(.system(size: 10))
                                            Text(tag)
                                                .font(.system(size: 13, weight: .medium))
                                        }
                                        .foregroundColor(AppTheme.primary)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(AppTheme.primary.opacity(0.08))
                                        .cornerRadius(AppTheme.Radius.pill)
                                    }
                                }
                            }
                        }

                        // Action buttons
                        VStack(spacing: AppTheme.Spacing.sm) {
                            // Save/unsave
                            Button {
                                Task {
                                    await viewModel.toggleSaved(material: material, session: session)
                                }
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                                        .font(.system(size: 16))
                                    Text(isSaved ? "Remove from Saved" : "Save Material")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                .secondaryButton()
                            }

                            if viewModel.canManage(material, session: session) {
                                Button {
                                    showingEdit = true
                                } label: {
                                    Label("Edit Material", systemImage: "pencil")
                                        .secondaryButton()
                                }

                                Button {
                                    showingDeleteConfirmation = true
                                } label: {
                                    Label("Delete Material", systemImage: "trash")
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 52)
                                        .background(AppTheme.error)
                                        .cornerRadius(AppTheme.Radius.md)
                                        .font(.system(size: 16, weight: .semibold))
                                }
                            }
                        }
                        .padding(.top, 4)
                    }
                    .padding(AppTheme.Spacing.lg)
                    .background(Color(hex: "F2F2F7"))

                    Spacer(minLength: 60)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .sheet(isPresented: $showingEdit) {
            MaterialEditorView(material: material) { title, description, videoURL, thumbnailURL, category, tags in
                await viewModel.saveMaterial(
                    existing: material,
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
        .confirmationDialog(
            "Delete this material?",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Material", role: .destructive) {
                Task {
                    await viewModel.deleteMaterial(material, session: session)
                    dismiss()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This video will no longer appear for users.")
        }
    }
}

private struct InvalidVideoURLView: View {
    var body: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 28))
                .foregroundColor(AppTheme.warning)
            Text("This material does not contain a valid YouTube link.")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 180)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.md))
    }
}

// MARK: - Flow Layout for tags
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> (positions: [CGPoint], size: CGSize) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > maxWidth, currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
        }

        return (positions, CGSize(width: maxWidth, height: currentY + lineHeight))
    }
}
