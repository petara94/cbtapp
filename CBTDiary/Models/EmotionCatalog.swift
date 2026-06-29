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
    /// Флаг разового досева раздела телесных наблюдений.
    private static let bodySeededKey = "emotionCatalog.bodySeeded.v1"

    /// Заполняет каталог дефолтными разделами при первом запуске, а для уже
    /// существующих каталогов один раз досеивает раздел «Тело».
    static func seedIfNeeded(_ context: ModelContext) {
        let existing = (try? context.fetch(FetchDescriptor<EmotionCategory>())) ?? []

        guard existing.isEmpty else {
            seedBodyIfNeeded(context, existing: existing)
            return
        }

        for (ci, group) in Content.emotionGroups.enumerated() {
            let category = EmotionCategory(name: group.label, sortOrder: ci)
            context.insert(category)
            for (oi, name) in group.items.enumerated() {
                let option = EmotionOption(name: name, sortOrder: oi, category: category)
                context.insert(option)
            }
        }
        try? context.save()
        // Свежий каталог уже содержит «Тело» — отмечаем, чтобы не досеивать повторно.
        UserDefaults.standard.set(true, forKey: bodySeededKey)
    }

    /// Одноразовый досев раздела «Тело» пользователям, чей каталог был создан
    /// до его появления. Уважает удаление: после установки флага раздел
    /// больше не возвращается, даже если пользователь его удалит.
    private static func seedBodyIfNeeded(_ context: ModelContext, existing: [EmotionCategory]) {
        guard !UserDefaults.standard.bool(forKey: bodySeededKey) else { return }
        UserDefaults.standard.set(true, forKey: bodySeededKey)

        let group = Content.bodyGroup
        guard !existing.contains(where: { $0.name == group.label }) else { return }

        let order = (existing.map(\.sortOrder).max() ?? -1) + 1
        let category = EmotionCategory(name: group.label, sortOrder: order)
        context.insert(category)
        for (oi, name) in group.items.enumerated() {
            let option = EmotionOption(name: name, sortOrder: oi, category: category)
            context.insert(option)
        }
        try? context.save()
    }
}
