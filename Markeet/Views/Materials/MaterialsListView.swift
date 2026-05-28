import SwiftUI

struct MaterialsListView: View {
    @EnvironmentObject private var session: SessionManager
    @StateObject private var viewModel = MaterialsViewModel()

    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.materials) { material in
                    NavigationLink {
                        MaterialDetailView(material: material)
                            .environmentObject(session)
                    } label: {
                        MaterialRowView(material: material, isSaved: viewModel.isSaved(material, by: session.currentUser))
                    }
                }

                if viewModel.materials.isEmpty && !viewModel.isLoading {
                    ContentUnavailableView("No Materials", systemImage: "book.closed", description: Text("Learning materials uploaded by admins will appear here."))
                }
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                }
            }
            .navigationTitle("Materials")
            .toolbar {
                NavigationLink {
                    SavedMaterialsView()
                        .environmentObject(session)
                } label: {
                    Image(systemName: "bookmark")
                }
            }
            .task {
                await viewModel.loadMaterials()
            }
            .refreshable {
                await viewModel.loadMaterials()
            }
        }
    }
}

struct MaterialRowView: View {
    let material: MaterialModel
    let isSaved: Bool

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: material.thumbnailURL.flatMap(URL.init(string:))) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                Image(systemName: "doc.text.image")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 56, height: 56)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text(material.title)
                    .font(.headline)
                    .lineLimit(2)
                Text(material.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            if isSaved {
                Image(systemName: "bookmark.fill")
                    .foregroundStyle(.blue)
            }
        }
    }
}
