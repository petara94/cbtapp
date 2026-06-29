import SwiftUI
import SwiftData

@main
struct CBTDiaryApp: App {
    let container: ModelContainer

    init() {
        do {
            // Локальное хранение (без CloudKit), чтобы приложение можно было
            // подписать бесплатным Apple ID и запустить на устройстве.
            //
            // Чтобы включить синхронизацию через iCloud:
            //  1. добавить таргету Capability «iCloud» c CloudKit (entitlements
            //     уже лежат в CBTDiary.entitlements);
            //  2. заменить конфигурацию ниже на:
            //       ModelConfiguration("CBTDiary", cloudKitDatabase: .automatic)
            //  Требуется платный аккаунт Apple Developer.
            let config = ModelConfiguration("CBTDiary")
            container = try ModelContainer(
                for: Entry.self, Feeling.self, EmotionCategory.self, EmotionOption.self,
                configurations: config
            )
            EmotionCatalog.seedIfNeeded(container.mainContext)
        } catch {
            fatalError("Не удалось создать ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .tint(Palette.feeling)
                .preferredColorScheme(.light)   // приложение всегда в светлой теме
        }
        .modelContainer(container)
    }
}
