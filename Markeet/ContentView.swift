import SwiftUI
import FirebaseFirestore

struct ContentView: View {

    var body: some View {

        Button("Test Firebase") {

            let db = Firestore.firestore()

            db.collection("test").addDocument(data: [
                "message": "Hello Firebase"
            ]) { error in

                if let error = error {
                    print("Error: \(error)")
                } else {
                    print("Success")
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
