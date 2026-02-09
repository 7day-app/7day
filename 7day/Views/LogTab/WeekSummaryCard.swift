import SwiftUI

struct WeekSummaryCard: View {
    let weekAverage: WeekAverage?
    let goalWeight: Double?
    let blockType: BlockType?
    let weekRangeString: String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("This Week")
                    .sectionLabel()
                Spacer()
                Text(weekRangeString)
                    .font(AppFonts.body())
                    .foregroundStyle(AppColors.textSecondary)
            }

            if let avg = weekAverage {
                HStack(alignment: .firstTextBaseline) {
                    Text(String(format: "%.1f", avg.average))
                        .font(AppFonts.weeklyAverage())
                        .foregroundStyle(AppColors.textPrimary)
                    Text("lbs")
                        .font(AppFonts.body())
                        .foregroundStyle(AppColors.textSecondary)
                }

                HStack(spacing: 16) {
                    Label("\(avg.count) weigh-in\(avg.count == 1 ? "" : "s")", systemImage: "scalemass")
                        .font(AppFonts.body())
                        .foregroundStyle(AppColors.textSecondary)

                    if avg.count > 1 {
                        Label(
                            "\(String(format: "%.1f", avg.min))–\(String(format: "%.1f", avg.max))",
                            systemImage: "arrow.up.arrow.down"
                        )
                        .font(AppFonts.monoBody())
                        .foregroundStyle(AppColors.textSecondary)
                    }
                }

                if let goal = goalWeight {
                    Divider()
                    goalRow(average: avg.average, goal: goal)
                }
            } else {
                Text("No entries this week")
                    .font(AppFonts.body())
                    .foregroundStyle(AppColors.textMuted)
            }
        }
        .cardStyle()
    }

    @ViewBuilder
    private func goalRow(average: Double, goal: Double) -> some View {
        let delta = average - goal
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Goal")
                    .font(AppFonts.body())
                    .foregroundStyle(AppColors.textSecondary)
                Text(String(format: "%.1f lbs", goal))
                    .font(AppFonts.monoBody())
                    .foregroundStyle(AppColors.textPrimary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("Delta")
                    .font(AppFonts.body())
                    .foregroundStyle(AppColors.textSecondary)
                Text(WeightViewModel.deltaString(delta))
                    .font(AppFonts.monoBody())
                    .foregroundStyle(WeightViewModel.deltaColor(delta: delta, blockType: blockType))
            }
        }
    }
}
