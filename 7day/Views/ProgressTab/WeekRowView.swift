import SwiftUI

struct WeekRowView: View {
    let progressWeek: ProgressWeek

    private var avg: WeekAverage { progressWeek.weekAverage }

    var body: some View {
        VStack(spacing: 6) {
            // Row 1: week range + average weight
            HStack(alignment: .firstTextBaseline) {
                Text(avg.weekKey.rangeString)
                    .font(AppFonts.body())
                    .foregroundStyle(AppColors.textPrimary)
                Spacer()
                Text(String(format: "%.1f", avg.average))
                    .font(AppFonts.monoBody())
                    .foregroundStyle(AppColors.textPrimary)
                Text("lbs")
                    .font(AppFonts.body())
                    .foregroundStyle(AppColors.textMuted)
            }

            // Row 2: entry count + range (left), delta + badge (right)
            HStack(alignment: .center) {
                HStack(spacing: 8) {
                    Text("\(avg.count) entr\(avg.count == 1 ? "y" : "ies")")
                        .font(AppFonts.body())
                        .foregroundStyle(AppColors.textSecondary)

                    if avg.count > 1 {
                        Text("\(String(format: "%.1f", avg.min))–\(String(format: "%.1f", avg.max))")
                            .font(AppFonts.monoBody())
                            .foregroundStyle(AppColors.textMuted)
                    }
                }

                Spacer()

                HStack(spacing: 8) {
                    if let goal = progressWeek.goal {
                        let delta = avg.average - goal
                        Text(WeightViewModel.deltaString(delta))
                            .font(AppFonts.monoBody())
                            .foregroundStyle(WeightViewModel.deltaColor(delta: delta, blockType: progressWeek.blockType))
                    }

                    if let blockType = progressWeek.blockType {
                        blockBadge(blockType)
                    }
                }
            }
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 14)
    }

    private func blockBadge(_ type: BlockType) -> some View {
        Text(type.rawValue.uppercased())
            .font(.system(size: 10, weight: .bold, design: .rounded))
            .foregroundStyle(WeightViewModel.blockColor(for: type))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(WeightViewModel.blockColor(for: type).opacity(0.12))
            .clipShape(Capsule())
    }
}
