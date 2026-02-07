import SwiftUI
import SwiftData

@main
struct ReceiptBrainApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Receipt.self])
    }
}
