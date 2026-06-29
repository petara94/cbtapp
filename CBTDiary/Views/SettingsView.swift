import SwiftUI
import SwiftData

/// Настройки: каталог эмоций (разделы + эмоции) и экспорт дневника.
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @Query(sort: \EmotionCategory.sortOrder) private var categories: [EmotionCategory]
    @Query(sort: \Entry.createdAt, order: .reverse) private var entries: [Entry]

    @State private var addingCategory = false
    @State private var newCategoryName = ""
    @State private var shareItem: ShareItem?
    @State private var exportError = false

    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (\(b))"
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(categories) { category in
                        NavigationLink {
                            CategoryEditorView(category: category)
                        } label: {
                            HStack {
                                Text(category.name)
                                    .font(.sans(16))
                                    .foregroundStyle(Palette.ink)
                                Spacer()
                                Text("\(category.sortedOptions.count)")
                                    .font(.sans(14))
                                    .foregroundStyle(Palette.inkFaint)
                            }
                        }
                        .listRowBackground(Palette.card)
                    }
                    .onDelete(perform: deleteCategories)

                    Button {
                        newCategoryName = ""
                        addingCategory = true
                    } label: {
                        Label("Добавить раздел", systemImage: "plus")
                            .font(.sans(16, weight: .medium))
                            .foregroundStyle(Palette.feeling)
                    }
                    .listRowBackground(Palette.card)
                } header: {
                    Text("Разделы и эмоции")
                } footer: {
                    Text("Эти разделы и эмоции доступны при создании и редактировании записи. Удаление не затрагивает уже сохранённые записи.")
                }

                Section("Экспорт") {
                    Button {
                        export()
                    } label: {
                        Label("Экспортировать в PDF", systemImage: "square.and.arrow.up")
                            .font(.sans(16, weight: .medium))
                            .foregroundStyle(entries.isEmpty ? Palette.inkFaint : Palette.event)
                    }
                    .disabled(entries.isEmpty)
                    .listRowBackground(Palette.card)
                }

                Section("О приложении") {
                    HStack {
                        Text("Версия").font(.sans(16)).foregroundStyle(Palette.ink)
                        Spacer()
                        Text(appVersion).font(.sans(15)).foregroundStyle(Palette.inkFaint)
                    }
                    .listRowBackground(Palette.card)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Palette.canvas.ignoresSafeArea())
            .navigationTitle("Настройки")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") { dismiss() }
                }
            }
            .alert("Новый раздел", isPresented: $addingCategory) {
                TextField("Название раздела", text: $newCategoryName)
                Button("Добавить") { addCategory() }
                Button("Отмена", role: .cancel) {}
            }
            .alert("Не удалось создать PDF", isPresented: $exportError) {
                Button("Ок", role: .cancel) {}
            }
            .sheet(item: $shareItem) { item in
                ShareSheet(items: [item.url])
            }
        }
    }

    private func addCategory() {
        let name = newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        let order = (categories.map(\.sortOrder).max() ?? -1) + 1
        context.insert(EmotionCategory(name: name, sortOrder: order))
    }

    private func deleteCategories(_ offsets: IndexSet) {
        for index in offsets {
            context.delete(categories[index])
        }
    }

    private func export() {
        if let url = JournalPDF.make(from: entries) {
            shareItem = ShareItem(url: url)
        } else {
            exportError = true
        }
    }
}

/// Редактор одного раздела: переименование и управление эмоциями.
private struct CategoryEditorView: View {
    @Bindable var category: EmotionCategory
    @Environment(\.modelContext) private var context

    @State private var addingOption = false
    @State private var newOptionName = ""

    var body: some View {
        List {
            Section("Название раздела") {
                TextField("Название", text: $category.name)
                    .font(.sans(16))
                    .foregroundStyle(Palette.ink)
                    .listRowBackground(Palette.card)
            }

            Section {
                ForEach(category.sortedOptions, id: \.persistentModelID) { option in
                    OptionRow(option: option)
                        .listRowBackground(Palette.card)
                }
                .onDelete(perform: deleteOptions)

                Button {
                    newOptionName = ""
                    addingOption = true
                } label: {
                    Label("Добавить эмоцию", systemImage: "plus")
                        .font(.sans(16, weight: .medium))
                        .foregroundStyle(Palette.feeling)
                }
                .listRowBackground(Palette.card)
            } header: {
                Text("Эмоции")
            }
        }
        .scrollContentBackground(.hidden)
        .background(Palette.canvas.ignoresSafeArea())
        .navigationTitle(category.name)
        .navigationBarTitleDisplayMode(.inline)
        .alert("Новая эмоция", isPresented: $addingOption) {
            TextField("Название эмоции", text: $newOptionName)
            Button("Добавить") { addOption() }
            Button("Отмена", role: .cancel) {}
        }
    }

    private func addOption() {
        let name = newOptionName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        let order = category.sortedOptions.count
        context.insert(EmotionOption(name: name, sortOrder: order, category: category))
    }

    private func deleteOptions(_ offsets: IndexSet) {
        let options = category.sortedOptions
        for index in offsets {
            context.delete(options[index])
        }
    }
}

/// Строка эмоции с инлайн-переименованием.
private struct OptionRow: View {
    @Bindable var option: EmotionOption

    var body: some View {
        TextField("Название", text: $option.name)
            .font(.sans(16))
            .foregroundStyle(Palette.ink)
    }
}
