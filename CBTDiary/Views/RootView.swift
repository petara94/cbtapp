import SwiftUI
import SwiftData

enum Tab: Hashable {
    case today, journal, patterns
}

/// Корневой экран: контент + кастомный таб-бар + плавающая кнопка.
struct RootView: View {
    @Query(sort: \Entry.createdAt, order: .reverse) private var entries: [Entry]
    @Environment(\.modelContext) private var context

    @State private var tab: Tab = .today
    @State private var sheet: ActiveSheet?

    /// Что показываем в модальном листе.
    private enum ActiveSheet: Identifiable {
        case compose
        case settings
        case edit(Entry)

        var id: String {
            switch self {
            case .compose: return "compose"
            case .settings: return "settings"
            case .edit(let entry): return "edit-\(entry.persistentModelID.hashValue)"
            }
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Palette.canvas.ignoresSafeArea()

            // Контент выбранной вкладки.
            Group {
                switch tab {
                case .today:
                    TodayView(
                        entries: entries,
                        onCompose: { sheet = .compose },
                        onEdit: { sheet = .edit($0) },
                        onSettings: { sheet = .settings }
                    )
                case .journal:
                    JournalView(
                        entries: entries,
                        onCompose: { sheet = .compose },
                        onEdit: { sheet = .edit($0) },
                        onDelete: delete
                    )
                case .patterns:
                    PatternsView(entries: entries)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Плавающая кнопка добавления.
            fab

            TabBar(tab: $tab)
        }
        .sheet(item: $sheet) { route in
            switch route {
            case .compose:
                EntryFlowView { tab = .today }
            case .edit(let entry):
                EntryFlowView(editing: entry)
            case .settings:
                SettingsView()
            }
        }
    }

    private var fab: some View {
        Button(action: { sheet = .compose }) {
            Image(systemName: "plus")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 58, height: 58)
                .background(Palette.feeling, in: Circle())
                .shadow(color: Palette.feeling.opacity(0.42), radius: 13, x: 0, y: 10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        .padding(.trailing, 18)
        .padding(.bottom, 90)
        .accessibilityLabel("Новая запись")
    }

    private func delete(_ entry: Entry) {
        context.delete(entry)
    }
}

/// Нижняя навигация в стиле макета.
private struct TabBar: View {
    @Binding var tab: Tab

    var body: some View {
        HStack(spacing: 8) {
            item(.today, "sun.max", "Сегодня")
            item(.journal, "book", "Дневник")
            item(.patterns, "sparkles", "Узоры")
        }
        .padding(.horizontal, 8)
        .padding(.top, 8)
        .padding(.bottom, 8)
        .background(.regularMaterial)
        .overlay(Rectangle().frame(height: 1).foregroundStyle(Palette.line), alignment: .top)
    }

    private func item(_ value: Tab, _ icon: String, _ title: String) -> some View {
        Button {
            tab = value
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .regular))
                Text(title)
                    .font(.sans(11, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .foregroundStyle(tab == value ? Palette.ink : Palette.inkFaint)
        }
    }
}
