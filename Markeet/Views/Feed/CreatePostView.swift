import SwiftUI

struct CreatePostView: View {

    @Environment(\.dismiss) var dismiss

    @State private var postContent = ""

    var onPost: (String) -> Void

    var body: some View {

        NavigationView {

            VStack {

                TextEditor(text: $postContent)
                    .padding()
                    .frame(maxHeight: .infinity)
                    .background(Color(.systemGray6))
                    .cornerRadius(20)
                    .padding()
            }
            .navigationTitle("Create Post")
            .navigationBarTitleDisplayMode(.inline)

            .toolbar {

                ToolbarItem(placement: .topBarLeading) {

                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {

                    Button("Post") {

                        guard !postContent.trimmingCharacters(in: .whitespaces).isEmpty else {
                            return
                        }

                        onPost(postContent)

                        dismiss()

                    }
                    .fontWeight(.bold)
                }
            }
        }
    }
}

#Preview {

    CreatePostView { _ in

    }
}
