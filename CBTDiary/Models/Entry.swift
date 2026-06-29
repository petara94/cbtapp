import Foundation
import SwiftData

/// Одна запись дневника: событие → мысль → чувства.
///
/// Все свойства имеют значения по умолчанию, а связь опциональна — это
/// требования CloudKit для автоматической синхронизации через SwiftData.
@Model
final class Entry {
    var id: UUID = UUID()
    var createdAt: Date = Date()
    var event: String = ""
    var thought: String = ""
    /// Свободная заметка: всё, что не вошло в структуру событие→мысль→чувство.
    var note: String = ""

    @Relationship(deleteRule: .cascade, inverse: \Feeling.entry)
    var feelings: [Feeling]? = []

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        event: String = "",
        thought: String = "",
        note: String = "",
        feelings: [Feeling] = []
    ) {
        self.id = id
        self.createdAt = createdAt
        self.event = event
        self.thought = thought
        self.note = note
        self.feelings = feelings
    }

    /// Чувства, отсортированные по интенсивности (по убыванию).
    var sortedFeelings: [Feeling] {
        (feelings ?? []).sorted { $0.intensity > $1.intensity }
    }
}
