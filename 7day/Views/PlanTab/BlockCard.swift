import SwiftUI
import SwiftData

struct BlockCard: View {
    let block: Block
    let entries: [WeightEntry]
    let isExpanded: Bool
    let onToggleExpand: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    private var summaries: [WeightViewModel.BlockWeekSummary] {
        WeightViewModel.blockWeekSummaries(for: block, entries: entries)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            summaryRow
            if isExpanded {
                expandedContent
            }
        }
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
    }

    // MARK: - Summary Row

    private var summaryRow: some View {
        Button(action: onToggleExpand) {
            HStack(spacing: 10) {
                typeBadge
                if block.isActive {
                    Text("ACTIVE")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(WeightViewModel.blockColor(for: block.type))
                        .clipShape(Capsule())
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(block.weeks)wk")
                        .font(AppFonts.monoBody())
                        .foregroundStyle(AppColors.textPrimary)
                    Text(dateRangeString)
                        .font(.system(size: 12, design: .rounded))
                        .foregroundStyle(AppColors.textSecondary)
                }
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.caption)
                    .foregroundStyle(AppColors.textMuted)
            }
            .padding(18)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var typeBadge: some View {
        Text(block.type.rawValue.capitalized)
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .foregroundStyle(WeightViewModel.blockColor(for: block.type))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(WeightViewModel.blockColor(for: block.type).opacity(0.12))
            .clipShape(Capsule())
    }

    private var dateRangeString: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM d"
        return "\(fmt.string(from: block.startDate)) – \(fmt.string(from: block.endDate))"
    }

    // MARK: - Expanded Content

    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            Divider()

            // Preview line
            Text(WeightViewModel.blockPreviewString(
                type: block.type,
                startWeight: block.startWeight,
                rate: block.rate,
                weeks: block.weeks
            ))
            .font(AppFonts.monoBody())
            .foregroundStyle(AppColors.textSecondary)
            .padding(.horizontal, 18)
            .padding(.top, 14)
            .padding(.bottom, 10)

            // Week-by-week table
            weekTable

            // Actions
            HStack(spacing: 12) {
                Button(action: onEdit) {
                    Label("Edit", systemImage: "pencil")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.outline)

                Button(action: onDelete) {
                    Label("Delete", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.outline)
            }
            .padding(.horizontal, 18)
            .padding(.top, 12)
            .padding(.bottom, 18)
        }
    }

    private var weekTable: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Wk")
                    .frame(width: 28, alignment: .leading)
                Text("Range")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("Goal")
                    .frame(width: 56, alignment: .trailing)
                Text("Actual")
                    .frame(width: 56, alignment: .trailing)
                Text("Delta")
                    .frame(width: 56, alignment: .trailing)
            }
            .font(.system(size: 10, weight: .semibold, design: .rounded))
            .foregroundStyle(AppColors.textMuted)
            .textCase(.uppercase)
            .padding(.horizontal, 18)
            .padding(.vertical, 6)

            ForEach(summaries) { summary in
                weekRow(summary)
            }
        }
    }

    private func weekRow(_ summary: WeightViewModel.BlockWeekSummary) -> some View {
        HStack {
            Text("\(summary.weekIndex + 1)")
                .frame(width: 28, alignment: .leading)
            Text(summary.weekKey.rangeString)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(1)
            Text(String(format: "%.1f", summary.goal))
                .frame(width: 56, alignment: .trailing)
            if let actual = summary.actual {
                Text(String(format: "%.1f", actual))
                    .frame(width: 56, alignment: .trailing)
                let delta = actual - summary.goal
                Text(String(format: "%+.1f", delta))
                    .foregroundStyle(WeightViewModel.deltaColor(delta: delta, blockType: block.type))
                    .frame(width: 56, alignment: .trailing)
            } else {
                Text("–")
                    .foregroundStyle(AppColors.textMuted)
                    .frame(width: 56, alignment: .trailing)
                Text("–")
                    .foregroundStyle(AppColors.textMuted)
                    .frame(width: 56, alignment: .trailing)
            }
        }
        .font(.system(size: 12, design: .monospaced))
        .foregroundStyle(AppColors.textPrimary)
        .padding(.horizontal, 18)
        .padding(.vertical, 5)
        .background(summary.weekKey.monday == Date().startOfWeek ? AppColors.accentDim : Color.clear)
    }
}
