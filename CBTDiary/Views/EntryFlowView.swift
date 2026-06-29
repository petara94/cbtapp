import SwiftUI

/// Пошаговое создание записи: событие → мысль → чувства.
struct EntryFlowView: View {
    /// Возвращает готовую запись для вставки в контекст.
    let onSave: (Entry) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var step: FlowStep = .event
    @State private var event = ""
    @State private var thought = ""
    @State private var feelings: [String: Int] = [:]   // name -> intensity

    private var isLast: Bool { step == .feeling }
    private var canEvent: Bool { !event.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    private var selected: [String] {
        Content.emotionGroups.flatMap { $0.items }.filter { feelings[$0] != nil }
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
                textField(text: $event)
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

    private func textField(text: Binding<String>) -> some View {
        TextEditor(text: text)
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
            ForEach(Content.emotionGroups) { group in
                Text(group.label.uppercased())
                    .font(.sans(12, weight: .semibold))
                    .tracking(0.8)
                    .foregroundStyle(Palette.inkFaint)
                    .padding(.top, 20)
                    .padding(.bottom, 10)
                FlowLayout(spacing: 8) {
                    ForEach(group.items, id: \.self) { name in
                        chip(name)
                    }
                }
            }

            if !selected.isEmpty {
                Divider().background(Palette.line).padding(.top, 20)
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
                        Text("Сохранить")
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
            let entry = Entry(
                event: event.trimmingCharacters(in: .whitespacesAndNewlines),
                thought: thought.trimmingCharacters(in: .whitespacesAndNewlines),
                feelings: feelings.map { Feeling(name: $0.key, intensity: $0.value) }
            )
            onSave(entry)
            dismiss()
        } else {
            withAnimation(.easeOut(duration: 0.2)) {
                step = FlowStep(rawValue: step.rawValue + 1) ?? .feeling
            }
        }
    }

    private func color(for step: FlowStep) -> Color {
        switch step {
        case .event: return Palette.event
        case .thought: return Palette.thought
        case .feeling: return Palette.feeling
        }
    }
}
