import XCTest

/// Прогон по основному сценарию приложения с сохранением скриншотов.
///
/// Скриншоты складываются и в результат теста (XCTAttachment), и в папку
/// `Caches/Screenshots` контейнера раннера — оттуда их забирает скрипт для README.
final class CBTDiaryUITests: XCTestCase {
    private var app: XCUIApplication!
    private var shotDir: URL!
    private var shotIndex = 0

    override func setUpWithError() throws {
        continueAfterFailure = false

        shotDir = FileManager.default
            .urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Screenshots", isDirectory: true)
        try? FileManager.default.removeItem(at: shotDir)
        try? FileManager.default.createDirectory(at: shotDir, withIntermediateDirectories: true)

        app = XCUIApplication()
        app.launch()
    }

    func testMainFlowWithScreenshots() throws {
        // 1) «Сегодня» — пустое состояние со вступлением.
        snap("today-empty")

        // 2) Создание записи. Шаг «Событие»: момент + описание.
        tap(app.buttons["Новая запись"])
        type(intoFirstTextView: "Начальник раскритиковал мою работу при коллегах")
        snap("step-event")
        dismissKeyboard()
        tap(app.buttons["Дальше"])

        // 3) Шаг «Мысль».
        type(intoFirstTextView: "Я ни на что не гожусь, меня скоро уволят")
        snap("step-thought")
        dismissKeyboard()
        tap(app.buttons["Дальше"])

        // 4) Шаг «Чувство»: выбор эмоций и интенсивности.
        snap("step-feeling")
        tap(app.buttons["Тревога"])
        tap(app.buttons["Стыд"])
        snap("step-intensity")
        tapButton(containing: "Сохран")

        // 5) «Сегодня» с первой записью.
        XCTAssertTrue(app.buttons["Дневник"].waitForExistence(timeout: 10))
        snap("today-with-entry")

        // Вторая запись — чтобы наполнить «Узоры».
        quickEntry(event: "Не ответили на сообщение весь день",
                   thought: "Я им безразличен",
                   feeling: "Грусть")

        // 6) «Дневник».
        tap(app.buttons["Дневник"])
        snap("journal")

        // 7) «Узоры».
        tap(app.buttons["Узоры"])
        snap("patterns")

        // 8) «Настройки» — каталог эмоций.
        tap(app.buttons["Сегодня"])
        tap(app.buttons["Настройки"])
        XCTAssertTrue(app.cells.firstMatch.waitForExistence(timeout: 10))
        snap("settings")

        // 9) Редактор раздела (тап по названию раздела открывает редактор эмоций).
        let category = app.staticTexts["Тревожные"]
        XCTAssertTrue(category.waitForExistence(timeout: 10), "Нет раздела «Тревожные»")
        category.tap()
        XCTAssertTrue(app.navigationBars["Тревожные"].waitForExistence(timeout: 10), "Редактор раздела не открылся")
        snap("settings-category")
    }

    // MARK: - Хелперы

    private func quickEntry(event: String, thought: String, feeling: String) {
        tap(app.buttons["Новая запись"])
        type(intoFirstTextView: event)
        dismissKeyboard()
        tap(app.buttons["Дальше"])
        type(intoFirstTextView: thought)
        dismissKeyboard()
        tap(app.buttons["Дальше"])
        tap(app.buttons[feeling])
        tapButton(containing: "Сохран")
        XCTAssertTrue(app.buttons["Дневник"].waitForExistence(timeout: 10))
    }

    private func type(intoFirstTextView text: String) {
        let field = app.textViews.firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 10), "Нет текстового поля")
        field.tap()
        field.typeText(text)
    }

    private func dismissKeyboard() {
        let done = app.buttons["Готово"]
        if done.waitForExistence(timeout: 3) {
            done.tap()
        }
    }

    private func tap(_ element: XCUIElement, timeout: TimeInterval = 10) {
        XCTAssertTrue(element.waitForExistence(timeout: timeout), "Не найден элемент: \(element)")
        element.tap()
    }

    private func tapButton(containing text: String, timeout: TimeInterval = 10) {
        let button = app.buttons.containing(
            NSPredicate(format: "label CONTAINS[c] %@", text)
        ).firstMatch
        XCTAssertTrue(button.waitForExistence(timeout: timeout), "Нет кнопки с «\(text)»")
        button.tap()
    }

    private func snap(_ name: String) {
        // Небольшая пауза, чтобы анимации/переходы завершились.
        Thread.sleep(forTimeInterval: 0.6)
        let shot = XCUIScreen.main.screenshot()

        let attachment = XCTAttachment(screenshot: shot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)

        shotIndex += 1
        let url = shotDir.appendingPathComponent(String(format: "%02d-%@.png", shotIndex, name))
        try? shot.pngRepresentation.write(to: url)
    }
}
