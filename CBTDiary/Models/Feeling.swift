import Foundation
import SwiftData

/// Отдельное чувство внутри записи с его силой (0–100).
@Model
final class Feeling {
    var name: String = ""
    var intensity: Int = 0
    var entry: Entry?

    init(name: String = "", intensity: Int = 0, entry: Entry? = nil) {
        self.name = name
        self.intensity = intensity
        self.entry = entry
    }
}
