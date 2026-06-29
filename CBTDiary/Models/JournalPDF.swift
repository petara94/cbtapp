import UIKit

/// Сборка PDF из записей дневника с постраничной разбивкой.
enum JournalPDF {
    /// Рендерит записи в PDF-файл во временной папке и возвращает его URL.
    static func make(from entries: [Entry]) -> URL? {
        guard !entries.isEmpty else { return nil }

        // A4 в пунктах.
        let pageW: CGFloat = 595.2
        let pageH: CGFloat = 841.8
        let margin: CGFloat = 46
        let contentW = pageW - margin * 2
        let bounds = CGRect(x: 0, y: 0, width: pageW, height: pageH)

        // Палитра приложения в UIColor.
        let ink = UIColor(hex: 0x262320)
        let inkFaint = UIColor(hex: 0x9A9488)
        let event = UIColor(hex: 0x2E5F5B)
        let thought = UIColor(hex: 0xAE7A2C)
        let feeling = UIColor(hex: 0xBB5D4C)
        let note = UIColor(hex: 0x5E5A52)

        func serif(_ size: CGFloat, bold: Bool = true) -> UIFont {
            UIFont(name: bold ? "Georgia-Bold" : "Georgia", size: size)
                ?? .systemFont(ofSize: size, weight: bold ? .semibold : .regular)
        }
        func attr(_ string: String, _ font: UIFont, _ color: UIColor, kern: CGFloat = 0, lineSpacing: CGFloat = 2) -> NSAttributedString {
            let p = NSMutableParagraphStyle()
            p.lineSpacing = lineSpacing
            return NSAttributedString(string: string, attributes: [
                .font: font, .foregroundColor: color, .kern: kern, .paragraphStyle: p,
            ])
        }

        // Группировка по дням, как в дневнике.
        let groups = Dictionary(grouping: entries) { DateText.dayKey($0.createdAt) }
            .map { (day: $0.key, items: $0.value.sorted { $0.createdAt > $1.createdAt }) }
            .sorted { $0.day > $1.day }

        let renderer = UIGraphicsPDFRenderer(bounds: bounds)
        let data = renderer.pdfData { ctx in
            var y: CGFloat = 0

            func newPage() {
                ctx.beginPage()
                y = margin
            }
            func draw(_ s: NSAttributedString, spacingAfter: CGFloat) {
                let h = ceil(s.boundingRect(
                    with: CGSize(width: contentW, height: .greatestFiniteMagnitude),
                    options: [.usesLineFragmentOrigin, .usesFontLeading],
                    context: nil
                ).height)
                if y + h > pageH - margin { newPage() }
                s.draw(in: CGRect(x: margin, y: y, width: contentW, height: h))
                y += h + spacingAfter
            }

            newPage()

            // Шапка.
            draw(attr("Дневник мыслей", serif(26), ink), spacingAfter: 4)
            let df = DateFormatter()
            df.locale = DateText.ruLocale
            df.setLocalizedDateFormatFromTemplate("d MMMM yyyy")
            draw(attr("Экспортировано \(df.string(from: Date())) · записей: \(entries.count)",
                      .systemFont(ofSize: 11, weight: .medium), inkFaint, kern: 0.3), spacingAfter: 20)

            for g in groups {
                draw(attr(DateText.dayLabel(g.day).uppercased(),
                          .systemFont(ofSize: 12, weight: .bold), inkFaint, kern: 1.2), spacingAfter: 12)

                for e in g.items {
                    draw(attr(DateText.time(e.createdAt),
                              .systemFont(ofSize: 11, weight: .semibold), inkFaint), spacingAfter: 7)

                    draw(attr("СОБЫТИЕ", .systemFont(ofSize: 10, weight: .bold), event, kern: 1.1), spacingAfter: 3)
                    draw(attr(e.event.isEmpty ? "—" : e.event, .systemFont(ofSize: 13), ink, lineSpacing: 3), spacingAfter: 9)

                    draw(attr("МЫСЛЬ", .systemFont(ofSize: 10, weight: .bold), thought, kern: 1.1), spacingAfter: 3)
                    draw(attr(e.thought.isEmpty ? "—" : e.thought, .systemFont(ofSize: 13), ink, lineSpacing: 3), spacingAfter: 9)

                    let feelings = e.sortedFeelings
                    draw(attr("ЧУВСТВО", .systemFont(ofSize: 10, weight: .bold), feeling, kern: 1.1), spacingAfter: 3)
                    let ftext = feelings.isEmpty ? "—" : feelings.map { "\($0.name) · \($0.intensity)" }.joined(separator: "    ")
                    draw(attr(ftext, .systemFont(ofSize: 13), ink, lineSpacing: 3), spacingAfter: e.note.isEmpty ? 18 : 9)

                    if !e.note.isEmpty {
                        draw(attr("ЗАМЕТКА", .systemFont(ofSize: 10, weight: .bold), note, kern: 1.1), spacingAfter: 3)
                        draw(attr(e.note, .systemFont(ofSize: 13), ink, lineSpacing: 3), spacingAfter: 18)
                    }
                }
            }
        }

        let url = FileManager.default.temporaryDirectory.appendingPathComponent("Дневник мыслей.pdf")
        do {
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            return nil
        }
    }
}

private extension UIColor {
    convenience init(hex: UInt) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}
