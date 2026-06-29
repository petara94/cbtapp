import SwiftUI
import SwiftData

@main
struct CBTDiaryApp: App {
    let container: ModelContainer

    init() {
        do {
            // Автоматическая синхронизация через приватную базу CloudKit.
            let config = ModelConfiguration(
                "CBTDiary",
                cloudKitDatabase: .automatic
            )
            container = try ModelContainer(
                for: Entry.self, Feeling.self,
                configurations: config
            )
        } catch {
            fatalError("Не удалось создать ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .tint(Palette.feeling)
        }
        .modelContainer(container)
    }
}
