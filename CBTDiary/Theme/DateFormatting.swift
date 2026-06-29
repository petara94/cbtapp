import Foundation

/// Помощники форматирования дат на русском, как в макете.
enum DateText {
    static let ruLocale = Locale(identifier: "ru_RU")

    static func sameDay(_ a: Date, _ b: Date) -> Bool {
        Calendar.current.isDate(a, inSameDayAs: b)
    }

    /// Ключ дня для группировки записей.
    static func dayKey(_ d: Date) -> Date {
        Calendar.current.startOfDay(for: d)
    }

    /// «Сегодня» / «Вчера» / «понедельник, 5 июня».
    static func dayLabel(_ d: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(d) { return "Сегодня" }
        if cal.isDateInYesterday(d) { return "Вчера" }
        let f = DateFormatter()
        f.locale = ruLocale
        f.setLocalizedDateFormatFromTemplate("EEEE d MMMM")
        return f.string(from: d)
    }

    /// «понедельник, 5 июня» — для заголовка экрана «Сегодня».
    static func fullDate(_ d: Date) -> String {
        let f = DateFormatter()
        f.locale = ruLocale
        f.setLocalizedDateFormatFromTemplate("EEEE d MMMM")
        return f.string(from: d)
    }

    static func time(_ d: Date) -> String {
        let f = DateFormatter()
        f.locale = ruLocale
        f.dateFormat = "HH:mm"
        return f.string(from: d)
    }

    /// Приветствие в зависимости от времени суток.
    static func greeting(for date: Date = Date()) -> String {
        let h = Calendar.current.component(.hour, from: date)
        switch h {
        case ..<5: return "Доброй ночи"
        case ..<12: return "Доброе утро"
        case ..<18: return "Добрый день"
        default: return "Добрый вечер"
        }
    }
}
