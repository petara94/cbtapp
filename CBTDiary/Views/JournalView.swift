import SwiftUI

struct JournalView: View {
    let entries: [Entry]
    let onCompose: () -> Void
    let onDelete: (Entry) -> Void

    /// Группировка по дням (по убыванию даты).
    private var grouped: [(day: Date, items: [Entry])] {
        let dict = Dictionary(grouping: entries) { DateText.dayKey($0.createdAt) }
        return dict
            .map { (day: $0.key, items: $0.value.sorted { $0.createdAt > $1.createdAt }) }
            .sorted { $0.day > $1.day }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("Дневник")
                    .font(.serif(28))
                    .foregroundStyle(Palette.ink)
                    .padding(.bottom, 18)

                if entries.isEmpty {
                    EmptyState(
                        icon: "book",
                        title: "Здесь пока пусто",
                        message: "Записи будут собираться сюда. Начните с первого момента — кнопка «+» внизу.",
                        actionTitle: "Записать момент",
                        action: onCompose
                    )
                    .padding(.top, 30)
                } else {
                    ForEach(grouped, id: \.day) { group in
                        SectionTitle(DateText.dayLabel(group.day))
                            .padding(.top, 26)
                            .padding(.bottom, 12)
                        VStack(spacing: 12) {
                            ForEach(group.items, id: \.persistentModelID) { entry in
                                EntryCardView(entry: entry, onDelete: onDelete)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 22)
            .padding(.top, 30)
            .padding(.bottom, 130)
        }
    }
}

/// Пустое состояние с иконкой и опциональной кнопкой.
struct EmptyState: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 0) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(Palette.inkSoft)
                .frame(width: 60, height: 60)
                .background(Palette.card, in: Circle())
                .overlay(Circle().stroke(Palette.line, lineWidth: 1))

            Text(title)
                .font(.serif(20))
                .foregroundStyle(Palette.ink)
                .padding(.top, 16)

            Text(message)
                .font(.sans(15))
                .foregroundStyle(Palette.inkSoft)
                .multilineTextAlignment(.center)
                .lineSpacing(5)
                .frame(maxWidth: 270)
                .padding(.top, 6)

            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.sans(15, weight: .semibold))
                        .foregroundStyle(Palette.canvas)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 14)
                        .background(Palette.ink, in: RoundedRectangle(cornerRadius: 14))
                }
                .padding(.top, 20)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
    }
}
