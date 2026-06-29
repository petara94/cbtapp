import SwiftUI

/// Простой перенос элементов по строкам (как flex-wrap в макете).
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    private struct Item {
        var index: Int
        var x: CGFloat
        var y: CGFloat
        var size: CGSize
        var maxY: CGFloat { y + size.height }
    }

    private struct Result {
        var items: [Item] = []
        var totalHeight: CGFloat = 0
        var totalWidth: CGFloat = 0
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        let result = layout(subviews: subviews, maxWidth: maxWidth)
        let width = maxWidth == .infinity ? result.totalWidth : maxWidth
        return CGSize(width: width, height: result.totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        let result = layout(subviews: subviews, maxWidth: bounds.width)
        for item in result.items {
            let pt = CGPoint(x: bounds.minX + item.x, y: bounds.minY + item.y)
            subviews[item.index].place(at: pt, proposal: ProposedViewSize(item.size))
        }
    }

    private func layout(subviews: Subviews, maxWidth: CGFloat) -> Result {
        var result = Result()
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for (i, sub) in subviews.enumerated() {
            let size = sub.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            result.items.append(Item(index: i, x: x, y: y, size: size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            result.totalWidth = max(result.totalWidth, x - spacing)
        }
        result.totalHeight = y + rowHeight
        return result
    }
}
