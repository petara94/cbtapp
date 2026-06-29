import SwiftUI

struct PatternsView: View {
    let entries: [Entry]

    private struct EmoStat: Identifiable {
        let name: String
        let count: Int
        let avg: Int
        var id: String { name }
    }

    private struct Stats {
        var top: [EmoStat] = []
        var days = 0
        var emoTotal = 0
        var maxCount = 1
    }

    private var stats: Stats {
        var emoMap: [String: (count: Int, sum: Int)] = [:]
        var days = Set<Date>()
        var emoTotal = 0
        for e in entries {
            days.insert(DateText.dayKey(e.createdAt))
            for f in e.feelings ?? [] {
                var m = emoMap[f.name] ?? (0, 0)
                m.count += 1
                m.sum += f.intensity
                emoMap[f.name] = m
                emoTotal += 1
            }
        }
        let top = emoMap
            .map { EmoStat(name: $0.key, count: $0.value.count, avg: Int((Double($0.value.sum) / Double($0.value.count)).rounded())) }
            .sorted { $0.count > $1.count }
            .prefix(6)
        var s = Stats()
        s.top = Array(top)
        s.days = days.count
        s.emoTotal = emoTotal
        s.maxCount = top.first?.count ?? 1
        return s
    }

    private var enough: Bool { entries.count >= 2 }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("Узоры")
                    .font(.serif(28))
                    .foregroundStyle(Palette.ink)
                    .padding(.bottom, 18)

                if !enough {
                    EmptyState(
                        icon: "sparkles",
                        title: "Скоро появятся узоры",
                        message: "Сделайте несколько записей — и здесь проявятся повторяющиеся чувства и связи между ними."
                    )
                    .padding(.top, 30)
                } else {
                    statRow
                    if !stats.top.isEmpty {
                        SectionTitle("Частые чувства")
                            .padding(.top, 26)
                            .padding(.bottom, 12)
                        VStack(spacing: 15) {
                            ForEach(stats.top) { e in
                                barRow(e)
                            }
                        }
                    }
                    insight
                }
            }
            .padding(.horizontal, 22)
            .padding(.top, 30)
            .padding(.bottom, 130)
        }
    }

    private var statRow: some View {
        HStack(spacing: 10) {
            statCard("\(entries.count)", "записей")
            statCard("\(stats.days)", stats.days == 1 ? "день" : "дней")
            statCard("\(stats.emoTotal)", "чувств")
        }
    }

    private func statCard(_ num: String, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(num)
                .font(.serif(28))
                .foregroundStyle(Palette.ink)
            Text(label)
                .font(.sans(12, weight: .medium))
                .foregroundStyle(Palette.inkSoft)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(EdgeInsets(top: 16, leading: 14, bottom: 16, trailing: 14))
        .background(Palette.card, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Palette.line, lineWidth: 1))
    }

    private func barRow(_ e: EmoStat) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(alignment: .firstTextBaseline) {
                Text(e.name)
                    .font(.sans(15, weight: .semibold))
                    .foregroundStyle(Palette.ink)
                Spacer()
                Text("\(e.count)× · сила \(e.avg)")
                    .font(.sans(12, weight: .medium))
                    .foregroundStyle(Palette.inkFaint)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Palette.feelingTint)
                    Capsule()
                        .fill(Palette.feeling)
                        .frame(width: geo.size.width * CGFloat(e.count) / CGFloat(stats.maxCount))
                }
            }
            .frame(height: 10)
        }
    }

    private var insight: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Что это значит")
                .font(.serif(18))
                .foregroundStyle(Palette.event)
            Text("Чувства возникают не из самих событий, а из мыслей о них. Когда вы видите, какая мысль чаще всего ведёт к тяжёлому чувству, появляется выбор: проверить эту мысль на реалистичность — и почувствовать себя иначе.")
                .font(.sans(14))
                .foregroundStyle(Palette.ink)
                .lineSpacing(5)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.eventTint, in: RoundedRectangle(cornerRadius: 18))
        .padding(.top, 24)
    }
}
