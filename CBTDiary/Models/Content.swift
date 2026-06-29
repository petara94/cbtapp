import Foundation

/// Группа эмоций для выбора на шаге «Чувство».
struct EmotionGroup: Identifiable {
    let label: String
    let items: [String]
    var id: String { label }
}

/// Статичный контент дневника: группы эмоций и тексты шагов.
enum Content {
    /// Телесные наблюдения — отдельный дефолтный раздел каталога.
    /// Хранится отдельной константой, чтобы досеять его пользователям,
    /// у которых каталог был создан до появления этого раздела.
    static let bodyGroup = EmotionGroup(
        label: "Тело",
        items: ["Дрожь", "Скованность", "Руки сцеплены", "Учащённое сердцебиение",
                "Ком в горле", "Напряжение в плечах", "Тяжесть в груди",
                "Нехватка воздуха", "Потливость"]
    )

    static let emotionGroups: [EmotionGroup] = [
        EmotionGroup(label: "Тревожные", items: ["Тревога", "Страх", "Паника", "Беспокойство"]),
        EmotionGroup(label: "Грустные", items: ["Грусть", "Тоска", "Подавленность", "Одиночество", "Безнадёжность"]),
        EmotionGroup(label: "Злость", items: ["Раздражение", "Обида", "Злость", "Гнев"]),
        EmotionGroup(label: "Стыд и вина", items: ["Стыд", "Вина", "Неловкость"]),
        EmotionGroup(label: "Светлые", items: ["Спокойствие", "Радость", "Облегчение", "Благодарность", "Надежда", "Гордость"]),
        bodyGroup,
    ]
}

/// Шаги создания записи.
enum FlowStep: Int, CaseIterable {
    case event = 0
    case thought = 1
    case feeling = 2
    case note = 3

    var category: String {
        switch self {
        case .event: return "Событие"
        case .thought: return "Мысль"
        case .feeling: return "Чувство"
        case .note: return "Заметка"
        }
    }

    var question: String {
        switch self {
        case .event: return "Что произошло?"
        case .thought: return "Что промелькнуло в голове?"
        case .feeling: return "Что вы почувствовали?"
        case .note: return "Хотите что-то добавить?"
        }
    }

    var help: String {
        switch self {
        case .event:
            return "Только факты — то, что увидела бы камера. Без оценок и выводов."
        case .thought:
            return "Та самая мысль, что вспыхнула в момент события. Она может быть верной — а может сгущать краски."
        case .feeling:
            return "Выберите эмоции и отметьте, насколько сильными они были."
        case .note:
            return "Всё, что не вошло в шаги выше: детали, контекст, мысли вслед. Можно оставить пустым."
        }
    }

    var placeholder: String {
        switch self {
        case .event: return "Например: начальник покритиковал мою работу при коллегах"
        case .thought: return "Например: я ни на что не гожусь, меня скоро уволят"
        case .feeling: return ""
        case .note: return "Например: это повторяется каждый раз перед публичными выступлениями"
        }
    }
}
