import SwiftUI

/// Mentor-only create/edit form for video learning materials.
/// The form validates YouTube URLs before asking the ViewModel to write to Firestore.
struct MaterialEditorView: View {
    let material: MaterialModel?
    let onSave: (String, String, String, String?, String?, [String]) async -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var description: String
    @State private var videoURL: String
    @State private var thumbnailURL: String
    @State private var category: String
    @State private var tagsText: String
    @State private var validationMessage: String?
    @State private var isSaving = false

    init(
        material: MaterialModel? = nil,
        onSave: @escaping (String, String, String, String?, String?, [String]) async -> Void
    ) {
        self.material = material
        self.onSave = onSave
        _title = State(initialValue: material?.title ?? "")
        _description = State(initialValue: material?.description ?? "")
        _videoURL = State(initialValue: material?.displayVideoURL ?? "")
        _thumbnailURL = State(initialValue: material?.thumbnailURL ?? "")
        _category = State(initialValue: material?.category ?? "")
        _tagsText = State(initialValue: material?.tags.joined(separator: ", ") ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Material Information") {
                    TextField("Title", text: $title)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                    TextField("Category", text: $category)
                }

                Section("Video") {
                    TextField("YouTube URL", text: $videoURL)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                    TextField("Thumbnail URL (optional)", text: $thumbnailURL)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)

                    if let videoId = YouTubeVideoHelper.extractVideoId(from: videoURL) {
                        Label("YouTube video detected: \(videoId)", systemImage: "checkmark.circle.fill")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(AppTheme.success)
                    }
                }

                Section("Tags") {
                    TextField("SEO, Branding, Analytics", text: $tagsText)
                    Text("Separate tags with commas.")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.textSecondary)
                }

                if let validationMessage {
                    Section {
                        Label(validationMessage, systemImage: "exclamationmark.triangle.fill")
                            .foregroundColor(AppTheme.error)
                    }
                }
            }
            .navigationTitle(material == nil ? "Add Material" : "Edit Material")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(isSaving ? "Saving..." : "Save") {
                        Task {
                            await save()
                        }
                    }
                    .disabled(isSaving)
                }
            }
        }
    }

    private func save() async {
        validationMessage = nil
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedVideoURL = videoURL.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedTitle.isEmpty else {
            validationMessage = "Title cannot be empty."
            return
        }

        guard !trimmedVideoURL.isEmpty else {
            validationMessage = "Video URL cannot be empty."
            return
        }

        guard YouTubeVideoHelper.extractVideoId(from: trimmedVideoURL) != nil else {
            validationMessage = "Enter a valid YouTube video URL."
            return
        }

        isSaving = true
        defer { isSaving = false }

        await onSave(
            trimmedTitle,
            description.trimmingCharacters(in: .whitespacesAndNewlines),
            trimmedVideoURL,
            thumbnailURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : thumbnailURL.trimmingCharacters(in: .whitespacesAndNewlines),
            category.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : category.trimmingCharacters(in: .whitespacesAndNewlines),
            tagsText
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
        )
        dismiss()
    }
}
