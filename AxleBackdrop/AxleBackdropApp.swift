import SwiftData
import SwiftUI

@main
struct AxleBackdropApp: App {
    private let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: ListingDraft.self, DealerTemplate.self)
        } catch {
            fatalError("Unable to create AxleBackdrop store: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup { ContentView() }
            .modelContainer(container)
    }
}
