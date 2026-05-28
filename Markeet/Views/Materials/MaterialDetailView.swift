import SwiftUI

struct MaterialDetailView: View {
    @EnvironmentObject private var session: SessionManager
    @StateObject private var viewModel = MaterialsViewModel()

    let material: MaterialModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                AsyncImage(url: material.thumbnailURL.flatMap(URL.init(string:))) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Rectangle()
                        .fill(Color(.secondarySystemBackground))
                        .overlay {
                            Image(systemName: "book")
                                .font(.largeTitle)
                                .foregroundStyle(.secondary)
                        }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 220)
                .clipShape(RoundedRectangle(cornerRadius: 8))

                Text(material.title)
                    .font(.title.bold())

                Text(material.description)
                    .foregroundStyle(.secondary)

                if !material.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(material.tags, id: \.self) { tag in
                                Label(tag, systemImage: "tag")
                                    .font(.caption)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color(.secondarySystemBackground))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }

                if let url = URL(string: material.contentURL) {
                    Link(destination: url) {
                        Label("Open Material", systemImage: "safari")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
        }
        .navigationTitle("Material")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button {
                Task { await viewModel.toggleSaved(material: material, session: session) }
            } label: {
                Image(systemName: viewModel.isSaved(material, by: session.currentUser) ? "bookmark.fill" : "bookmark")
            }
        }
    }
}
