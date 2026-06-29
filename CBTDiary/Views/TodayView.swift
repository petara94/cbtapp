import SwiftUI

struct TodayView: View {
    let entries: [Entry]
    let onCompose: () -> Void
    let onEdit: (Entry) -> Void
    let onSettings: () -> Void

    private var today: [Entry] {
        entries.filter { DateText.sameDay($0.createdAt, Date()) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Заголовок.
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(DateText.fullDate(Date()).uppercased())
                            .font(.sans(12, weight: .semibold))
                            .tracking(1.5)
                            .foregroundStyle(Palette.inkFaint)
                        Text(DateText.greeting())
                            .font(.serif(28))
                            .foregroundStyle(Palette.ink)
                    }
                    Spacer(minLength: 12)
                    Button(action: onSettings) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 20, weight: .regular))
                            .foregroundStyle(Palette.inkSoft)
                            .frame(width: 40, height: 40)
                            .background(Palette.card, in: Circle())
                            .overlay(Circle().stroke(Palette.line, lineWidth: 1))
                    }
                    .accessibilityLabel("Настройки")
                }
                .padding(.bottom, 18)

                // Вводный текст для первого запуска.
                if entries.isEmpty {
                    Text("Одно событие может вызвать разные мысли — и от мысли зависит чувство. Этот дневник помогает разложить трудный момент на три части и заметить связь между ними.")
                        .font(.sans(15))
                        .foregroundStyle(Palette.inkSoft)
                        .lineSpacing(5)
                        .padding(18)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Palette.card, in: RoundedRectangle(cornerRadius: 18))
                        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Palette.line, lineWidth: 1))
                        .padding(.bottom, 16)
                }

                // Большая кнопка-приглашение.
                composePrompt

                if !today.isEmpty {
                    SectionTitle("Сегодня").padding(.top, 26).padding(.bottom, 12)
                    VStack(spacing: 12) {
                        ForEach(today, id: \.persistentModelID) { entry in
                            EntryCardView(entry: entry, onEdit: onEdit)
                        }
                    }
                }
            }
            .padding(.horizontal, 22)
            .padding(.top, 30)
            .padding(.bottom, 130)
        }
    }

    private var composePrompt: some View {
        Button(action: onCompose) {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Записать момент")
                        .font(.serif(19))
                        .foregroundStyle(Palette.ink)
                    Text("Когда настроение изменилось — разложите его на части")
                        .font(.sans(13))
                        .foregroundStyle(Palette.inkSoft)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(Palette.canvas)
                    .frame(width: 46, height: 46)
                    .background(Palette.ink, in: Circle())
            }
            .padding(22)
            .background(
                LinearGradient(
                    colors: [Palette.eventTint, Palette.feelingTint],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 22)
            )
        }
        .buttonStyle(.plain)
    }
}

/// Заголовок секции в стиле макета.
struct SectionTitle: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text.uppercased())
            .font(.sans(12, weight: .semibold))
            .tracking(1)
            .foregroundStyle(Palette.inkFaint)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
