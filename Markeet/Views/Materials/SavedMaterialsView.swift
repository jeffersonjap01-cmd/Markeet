import SwiftUI

struct SavedMaterialsView: View {
    @EnvironmentObject private var session: SessionManager
    @StateObject private var viewModel = MaterialsViewModel()

    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.savedMaterials) { material in
                    NavigationLink {
                        MaterialDetailView(material: material)
                            .environmentObject(session)
                    } label: {
                        MaterialRowView(material: material, isSaved: true)
                    }
                }

                if viewModel.savedMaterials.isEmpty && !viewModel.isLoading {
                    ContentUnavailableView("No Saved Materials", systemImage: "bookmark", description: Text("Tap the bookmark icon on learning materials to save them here."))
                }
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                }
            }
            .navigationTitle("Saved Materials")
            .task {
                if let user = session.currentUser {
                    await viewModel.loadSavedMaterials(for: user)
                }
            }
            .refreshable {
                if let user = session.currentUser {
                    await viewModel.loadSavedMaterials(for: user)
                }
            }
        }
    }
}
