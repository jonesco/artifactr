import SwiftUI
import SwiftData

@main
struct ArtifactrApp: App {
    let container: ModelContainer = {
        let schema = Schema([Entry.self, CategoryItem.self])
        let config = ModelConfiguration(
            schema: schema,
            cloudKitDatabase: .private("iCloud.artifactr")
        )
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
        #if os(macOS)
        .defaultSize(width: 1100, height: 750)
        #endif

        #if os(macOS)
        Settings {
            ExportImportView()
                .padding()
                .frame(minWidth: 540, minHeight: 440)
        }
        #endif
    }
}
