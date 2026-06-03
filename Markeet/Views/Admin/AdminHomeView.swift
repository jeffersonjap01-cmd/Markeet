import SwiftUI

struct AdminHomeView: View {
    @EnvironmentObject private var session: SessionManager
    @StateObject private var viewModel = AdminNewsViewModel()
    @State private var editingNews: NewsModel?
    @State private var showingEditor = false

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

                ForEach(viewModel.news) { news in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(news.category.isEmpty ? "Update" : news.category)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(AppTheme.primary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(AppTheme.primary.opacity(0.12))
                                .cornerRadius(AppTheme.Radius.pill)

                            Spacer()

                            Text(news.createdAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.system(size: 11))
                                .foregroundColor(AppTheme.textTertiary)
                        }

                        Text(news.title)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(AppTheme.textPrimary)

                        Text(news.description)
                            .font(.system(size: 14))
                            .foregroundColor(AppTheme.textSecondary)
                            .lineLimit(3)

                        HStack {
                            Button {
                                editingNews = news
                                showingEditor = true
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            .buttonStyle(.bordered)

                            Button(role: .destructive) {
                                Task {
                                    await viewModel.deleteNews(news, session: session)
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            .buttonStyle(.bordered)
                        }
                        .font(.system(size: 13, weight: .medium))
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        editingNews = nil
                        showingEditor = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
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
            .sheet(isPresented: $showingEditor) {
                AdminNewsEditorView(news: editingNews) { title, description, category, imageURL in
                    await viewModel.saveNews(
                        news: editingNews,
                        title: title,
                        description: description,
                        category: category,
                        imageURL: imageURL,
                        session: session
                    )
                }
            }
        }
    }
}

private struct AdminNewsEditorView: View {
    let news: NewsModel?
    let onSave: (String, String, String, String?) async -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var description: String
    @State private var category: String
    @State private var imageURL: String

    init(news: NewsModel?, onSave: @escaping (String, String, String, String?) async -> Void) {
        self.news = news
        self.onSave = onSave
        _title = State(initialValue: news?.title ?? "")
        _description = State(initialValue: news?.description ?? "")
        _category = State(initialValue: news?.category ?? "Update")
        _imageURL = State(initialValue: news?.imageURL ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Title", text: $title)
                TextField("Category", text: $category)
                TextField("Image URL", text: $imageURL)

                Section("Content") {
                    TextEditor(text: $description)
                        .frame(minHeight: 180)
                }
            }
            .navigationTitle(news == nil ? "New Update" : "Edit Update")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await onSave(
                                title.trimmingCharacters(in: .whitespacesAndNewlines),
                                description.trimmingCharacters(in: .whitespacesAndNewlines),
                                category.trimmingCharacters(in: .whitespacesAndNewlines),
                                imageURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : imageURL
                            )
                            dismiss()
                        }
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
