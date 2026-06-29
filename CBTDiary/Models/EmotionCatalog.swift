import Foundation
import SwiftData

/// Раздел каталога эмоций (например «Тревожные», «Светлые»).
///
/// Хранится в SwiftData, чтобы пользователь мог создавать свои разделы и
/// эмоции. Значения по умолчанию и опциональная связь — те же требования
/// CloudKit, что и у `Entry`/`Feeling`.
@Model
final class EmotionCategory {
    var name: String = ""
    var sortOrder: Int = 0
    var createdAt: Date = Date()

    @Relationship(deleteRule: .cascade, inverse: \EmotionOption.category)
    var options: [EmotionOption]? = []

    init(name: String = "", sortOrder: Int = 0, createdAt: Date = Date()) {
        self.name = name
        self.sortOrder = sortOrder
        self.createdAt = createdAt
    }

    /// Эмоции раздела в заданном порядке.
    var sortedOptions: [EmotionOption] {
        (options ?? []).sorted { $0.sortOrder < $1.sortOrder }
    }
}

/// Отдельная эмоция внутри раздела каталога.
@Model
final class EmotionOption {
    var name: String = ""
    var sortOrder: Int = 0
    var category: EmotionCategory?

    init(name: String = "", sortOrder: Int = 0, category: EmotionCategory? = nil) {
        self.name = name
        self.sortOrder = sortOrder
        self.category = category
    }
}

enum EmotionCatalog {
    /// Заполняет каталог дефолтными разделами при первом запуске.
    static func seedIfNeeded(_ context: ModelContext) {
        let existing = (try? context.fetchCount(FetchDescriptor<EmotionCategory>())) ?? 0
        guard existing == 0 else { return }

        for (ci, group) in Content.emotionGroups.enumerated() {
            let category = EmotionCategory(name: group.label, sortOrder: ci)
            context.insert(category)
            for (oi, name) in group.items.enumerated() {
                let option = EmotionOption(name: name, sortOrder: oi, category: category)
                context.insert(option)
            }
        }
        try? context.save()
    }
}
