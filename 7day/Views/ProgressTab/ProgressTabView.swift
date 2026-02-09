import SwiftUI
import SwiftData

struct ProgressTabView: View {
    @Query(sort: \WeightEntry.date) private var entries: [WeightEntry]
    @Query(sort: \Block.startDate) private var blocks: [Block]
    @State private var selectedWeek: Date?

    private var progressWeeks: [ProgressWeek] {
        WeightViewModel.progressWeeks(from: entries, blocks: blocks)
    }

    var body: some View {
        ScrollView {
            if progressWeeks.isEmpty {
                emptyState
            } else {
                VStack(spacing: 20) {
                    chartCard
                    weekByWeekList
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
        }
        .background(AppColors.background)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.xyaxis.line")
                .font(.system(size: 48))
                .foregroundStyle(AppColors.textMuted)

            Text("No data yet")
                .font(AppFonts.headline())
                .foregroundStyle(AppColors.textPrimary)

            Text("Log a few weigh-ins on the Log tab to see your weekly trends here.")
                .font(AppFonts.body())
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Chart Card

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Weekly Averages")
                .sectionLabel()

            WeightChart(
                progressWeeks: progressWeeks,
                blocks: blocks,
                selectedWeek: $selectedWeek
            )
            .frame(height: 220)
        }
        .cardStyle()
    }

    // MARK: - Week by Week List

    private var weekByWeekList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Week by Week")
                .sectionLabel()
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                let reversed = Array(progressWeeks.reversed())
                ForEach(Array(reversed.enumerated()), id: \.element.id) { index, pw in
                    WeekRowView(progressWeek: pw)

                    if index < reversed.count - 1 {
                        Divider()
                            .padding(.horizontal, 22)
                    }
                }
            }
            .background(AppColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
        }
    }
}

#Preview {
    ProgressTabView()
        .modelContainer(for: [WeightEntry.self, Block.self], inMemory: true)
}
