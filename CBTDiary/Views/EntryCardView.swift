import SwiftUI

/// Карточка-«нить»: событие → мысль → чувство с вертикальной линией.
struct EntryCardView: View {
    let entry: Entry
    var onEdit: ((Entry) -> Void)?
    var onDelete: ((Entry) -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Время + кнопка удаления.
            HStack {
                Text(DateText.time(entry.createdAt))
                    .font(.sans(12, weight: .semibold))
                    .foregroundStyle(Palette.inkFaint)
                Spacer()
                HStack(spacing: 16) {
                    if let onEdit {
                        Button {
                            onEdit(entry)
                        } label: {
                            Image(systemName: "pencil")
                                .font(.system(size: 14))
                                .foregroundStyle(Palette.inkFaint)
                        }
                        .accessibilityLabel("Изменить запись")
                    }
                    if let onDelete {
                        Button {
                            onDelete(entry)
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 14))
                                .foregroundStyle(Palette.inkFaint)
                        }
                        .accessibilityLabel("Удалить запись")
                    }
                }
            }

            // Нить из трёх элементов.
            HStack(alignment: .top, spacing: 0) {
                ThreadLine()
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 14) {
                    item(label: "Событие", color: Palette.event, text: entry.event)
                    item(label: "Мысль", color: Palette.thought, text: entry.thought)
                    feelingItem
                    if !entry.note.isEmpty {
                        item(label: "Заметка", color: Palette.note, text: entry.note)
                    }
                }
            }
        }
        .padding(EdgeInsets(top: 14, leading: 16, bottom: 16, trailing: 16))
        .background(Palette.card, in: RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18).stroke(Palette.line, lineWidth: 1)
        )
    }

    private func item(label: String, color: Color, text: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 0) {
                Text(label.uppercased())
                    .font(.sans(11, weight: .bold))
                    .tracking(1.1)
                    .foregroundStyle(color)
            }
            Text(text.isEmpty ? "—" : text)
                .font(.sans(15))
                .foregroundStyle(Palette.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .overlay(dot(color: color), alignment: .topLeading)
    }

    private var feelingItem: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("ЧУВСТВО")
                .font(.sans(11, weight: .bold))
                .tracking(1.1)
                .foregroundStyle(Palette.feeling)

            let feelings = entry.sortedFeelings
            if feelings.isEmpty {
                Text("—").font(.sans(15)).foregroundStyle(Palette.ink)
            } else {
                FlowLayout(spacing: 6) {
                    ForEach(feelings, id: \.persistentModelID) { f in
                        Text("\(f.name) · \(f.intensity)")
                            .font(.sans(12, weight: .semibold))
                            .foregroundStyle(Palette.feeling)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Palette.feelingTint, in: Capsule())
                    }
                }
            }
        }
        .overlay(dot(color: Palette.feeling), alignment: .topLeading)
    }

    private func dot(color: Color) -> some View {
        Circle()
            .fill(color)
            .frame(width: 12, height: 12)
            .overlay(Circle().stroke(Palette.card, lineWidth: 2.5))
            .offset(x: -23, y: 2)
    }
}

/// Вертикальная линия-«нить» слева от элементов.
private struct ThreadLine: View {
    var body: some View {
        GeometryReader { geo in
            Rectangle()
                .fill(Palette.line)
                .frame(width: 2)
                .frame(maxHeight: .infinity)
                .position(x: 13, y: geo.size.height / 2)
                .padding(.vertical, 8)
        }
    }
}
