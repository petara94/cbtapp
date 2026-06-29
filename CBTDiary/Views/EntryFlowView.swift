import SwiftUI
import SwiftData

/// Пошаговое создание/редактирование записи: событие → мысль → чувства.
struct EntryFlowView: View {
    /// Если задано — режим редактирования существующей записи.
    var editing: Entry?
    /// Вызывается после успешного сохранения (например, для переключения вкладки).
    var onFinished: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @Query(sort: \EmotionCategory.sortOrder) private var categories: [EmotionCategory]

    @State private var step: FlowStep = .event
    @State private var createdAt: Date
    @State private var event: String
    @State private var thought: String
    @State private var feelings: [String: Int]   // name -> intensity

    @FocusState private var fieldFocused: Bool

    // Инлайн-создание раздела/эмоции.
    @State private var addingOptionTo: EmotionCategory?
    @State private var newOptionName = ""
    @State private var addingCategory = false
    @State private var newCategoryName = ""

    init(editing: Entry? = nil, onFinished: (() -> Void)? = nil) {
        self.editing = editing
        self.onFinished = onFinished
        _createdAt = State(initialValue: editing?.createdAt ?? Date())
        _event = State(initialValue: editing?.event ?? "")
        _thought = State(initialValue: editing?.thought ?? "")
        var map: [String: Int] = [:]
        for f in editing?.feelings ?? [] { map[f.name] = f.intensity }
        _feelings = State(initialValue: map)
    }

    private var isEditing: Bool { editing != nil }
    private var isLast: Bool { step == .feeling }
    private var canEvent: Bool { !event.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    /// Выбранные эмоции в порядке каталога, плюс «осиротевшие» (удалённые из каталога).
    private var selected: [String] {
        let catalogNames = categories.flatMap { $0.sortedOptions.map(\.name) }
        let inCatalog = catalogNames.filter { feelings[$0] != nil }
        let extras = feelings.keys.filter { !catalogNames.contains($0) }.sorted()
        return inCatalog + extras
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                stepBody
                    .padding(.horizontal, 22)
                    .padding(.top, 14)
                    .padding(.bottom, 24)
            }
            footer
        }
        .background(Palette.canvas.ignoresSafeArea())
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Готово") { fieldFocused = false }
            }
        }
        .alert("Новая эмоция", isPresented: Binding(
            get: { addingOptionTo != nil },
            set: { if !$0 { addingOptionTo = nil } }
        )) {
            TextField("Например: Зависть", text: $newOptionName)
            Button("Добавить") { addOption() }
            Button("Отмена", role: .cancel) { addingOptionTo = nil }
        } message: {
            if let category = addingOptionTo {
                Text("В раздел «\(category.name)»")
            }
        }
        .alert("Новый раздел", isPresented: $addingCategory) {
            TextField("Например: Усталость", text: $newCategoryName)
            Button("Добавить") { addCategory() }
            Button("Отмена", role: .cancel) {}
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 16) {
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 20, weight: .regular))
                    .foregroundStyle(Palette.inkSoft)
            }
            .accessibilityLabel("Закрыть")

            HStack(spacing: 6) {
                ForEach(FlowStep.allCases, id: \.rawValue) { st in
                    Capsule()
                        .fill(st.rawValue <= step.rawValue ? color(for: st) : Palette.line)
                        .frame(height: 5)
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 18)
        .padding(.bottom, 6)
    }

    // MARK: - Body

    @ViewBuilder
    private var stepBody: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(step.category.uppercased())
                .font(.sans(12, weight: .bold))
                .tracking(1.5)
                .foregroundStyle(color(for: step))
            Text(step.question)
                .font(.serif(26))
                .foregroundStyle(Palette.ink)
                .padding(.top, 10)
            Text(step.help)
                .font(.sans(15))
                .foregroundStyle(Palette.inkSoft)
                .lineSpacing(4)
                .padding(.top, 8)

            switch step {
            case .event:
                eventInputs
            case .thought:
                textField(text: $thought)
            case .feeling:
                feelingPicker
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .id(step)
        .transition(.opacity)
    }

    /// Шаг «Событие»: выбор момента (дата + время) и описание.
    private var eventInputs: some View {
        VStack(alignment: .leading, spacing: 0) {
            whenPicker
            textField(text: $event)
        }
    }

    private var whenPicker: some View {
        HStack(spacing: 10) {
            Image(systemName: "clock")
                .font(.system(size: 15))
                .foregroundStyle(Palette.event)
            Text("Когда это было")
                .font(.sans(15, weight: .medium))
                .foregroundStyle(Palette.ink)
            Spacer(minLength: 8)
            DatePicker(
                "",
                selection: $createdAt,
                in: ...Date(),
                displayedComponents: [.date, .hourAndMinute]
            )
            .labelsHidden()
            .datePickerStyle(.compact)
            .environment(\.locale, DateText.ruLocale)
            .tint(Palette.event)
        }
        .padding(14)
        .background(Palette.card, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Palette.line, lineWidth: 1))
        .padding(.top, 18)
    }

    private func textField(text: Binding<String>) -> some View {
        TextEditor(text: text)
            .focused($fieldFocused)
            .font(.sans(16))
            .foregroundStyle(Palette.ink)
            .scrollContentBackground(.hidden)
            .frame(minHeight: 150)
            .padding(12)
            .background(Palette.card, in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(color(for: step), lineWidth: 1.5))
            .overlay(alignment: .topLeading) {
                if text.wrappedValue.isEmpty {
                    Text(step.placeholder)
                        .font(.sans(16))
                        .foregroundStyle(Palette.inkFaint)
                        .padding(.horizontal, 17)
                        .padding(.vertical, 20)
                        .allowsHitTesting(false)
                }
            }
            .padding(.top, 20)
    }

    private var feelingPicker: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(categories) { category in
                HStack {
                    Text(category.name.uppercased())
                        .font(.sans(12, weight: .semibold))
                        .tracking(0.8)
                        .foregroundStyle(Palette.inkFaint)
                    Spacer()
                    Button {
                        newOptionName = ""
                        addingOptionTo = category
                    } label: {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 16))
                            .foregroundStyle(Palette.inkFaint)
                    }
                    .accessibilityLabel("Добавить эмоцию в раздел")
                }
                .padding(.top, 20)
                .padding(.bottom, 10)

                FlowLayout(spacing: 8) {
                    ForEach(category.sortedOptions, id: \.persistentModelID) { option in
                        chip(option.name)
                    }
                }
            }

            Button {
                newCategoryName = ""
                addingCategory = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Новый раздел")
                }
                .font(.sans(14, weight: .medium))
                .foregroundStyle(Palette.inkSoft)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .overlay(Capsule().stroke(Palette.line, lineWidth: 1.5))
            }
            .buttonStyle(.plain)
            .padding(.top, 18)

            if !selected.isEmpty {
                Divider().background(Palette.line).padding(.top, 22)
                Text("Насколько сильно?".uppercased())
                    .font(.sans(12, weight: .semibold))
                    .tracking(0.8)
                    .foregroundStyle(Palette.inkFaint)
                    .padding(.top, 12)
                    .padding(.bottom, 10)
                ForEach(selected, id: \.self) { name in
                    intensityRow(name)
                }
            }
        }
    }

    private func chip(_ name: String) -> some View {
        let on = feelings[name] != nil
        return Button {
            if on { feelings[name] = nil } else { feelings[name] = 60 }
        } label: {
            Text(name)
                .font(.sans(14, weight: .medium))
                .foregroundStyle(on ? .white : Palette.inkSoft)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(on ? Palette.feeling : Palette.card, in: Capsule())
                .overlay(Capsule().stroke(on ? Palette.feeling : Palette.line, lineWidth: 1.5))
        }
        .buttonStyle(.plain)
    }

    private func intensityRow(_ name: String) -> some View {
        let binding = Binding<Double>(
            get: { Double(feelings[name] ?? 60) },
            set: { feelings[name] = Int($0) }
        )
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(name)
                    .font(.sans(15, weight: .semibold))
                    .foregroundStyle(Palette.ink)
                Spacer()
                Text("\(feelings[name] ?? 60)")
                    .font(.sans(15, weight: .semibold))
                    .foregroundStyle(Palette.feeling)
            }
            Slider(value: binding, in: 0...100, step: 5)
                .tint(Palette.feeling)
        }
        .padding(.bottom, 18)
    }

    // MARK: - Footer

    private var footer: some View {
        HStack(spacing: 12) {
            if step != .event {
                Button {
                    withAnimation(.easeOut(duration: 0.2)) {
                        step = FlowStep(rawValue: step.rawValue - 1) ?? .event
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Palette.ink)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 16)
                        .background(Palette.card, in: RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Palette.line, lineWidth: 1.5))
                }
            }
            Button(action: advance) {
                HStack(spacing: 8) {
                    if isLast {
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .semibold))
                        Text(isEditing ? "Сохранить изменения" : "Сохранить")
                    } else {
                        Text("Дальше")
                    }
                }
                .font(.sans(16, weight: .semibold))
                .foregroundStyle(Palette.canvas)
                .frame(maxWidth: .infinity)
                .padding(16)
                .background(Palette.ink, in: RoundedRectangle(cornerRadius: 14))
                .opacity(step == .event && !canEvent ? 0.35 : 1)
            }
            .disabled(step == .event && !canEvent)
        }
        .padding(.horizontal, 22)
        .padding(.top, 14)
        .padding(.bottom, 16)
        .overlay(Rectangle().frame(height: 1).foregroundStyle(Palette.line), alignment: .top)
    }

    // MARK: - Logic

    private func advance() {
        if step == .event && !canEvent { return }
        if isLast {
            save()
        } else {
            withAnimation(.easeOut(duration: 0.2)) {
                step = FlowStep(rawValue: step.rawValue + 1) ?? .feeling
            }
        }
    }

    private func save() {
        let trimmedEvent = event.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedThought = thought.trimmingCharacters(in: .whitespacesAndNewlines)

        if let entry = editing {
            entry.event = trimmedEvent
            entry.thought = trimmedThought
            entry.createdAt = createdAt
            for f in entry.feelings ?? [] { context.delete(f) }
            entry.feelings = feelings.map { Feeling(name: $0.key, intensity: $0.value) }
        } else {
            let entry = Entry(
                createdAt: createdAt,
                event: trimmedEvent,
                thought: trimmedThought,
                feelings: feelings.map { Feeling(name: $0.key, intensity: $0.value) }
            )
            context.insert(entry)
        }
        try? context.save()
        onFinished?()
        dismiss()
    }

    private func addOption() {
        guard let category = addingOptionTo else { return }
        let name = newOptionName.trimmingCharacters(in: .whitespacesAndNewlines)
        addingOptionTo = nil
        guard !name.isEmpty else { return }
        let order = category.sortedOptions.count
        let option = EmotionOption(name: name, sortOrder: order, category: category)
        context.insert(option)
        feelings[name] = 60   // только что добавленную сразу выбираем
    }

    private func addCategory() {
        let name = newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        let order = (categories.map(\.sortOrder).max() ?? -1) + 1
        let category = EmotionCategory(name: name, sortOrder: order)
        context.insert(category)
    }

    private func color(for step: FlowStep) -> Color {
        switch step {
        case .event: return Palette.event
        case .thought: return Palette.thought
        case .feeling: return Palette.feeling
        }
    }
}
