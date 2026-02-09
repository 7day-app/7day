import SwiftUI
import Charts

struct WeightChart: View {
    let progressWeeks: [ProgressWeek]
    let blocks: [Block]
    @Binding var selectedWeek: Date?

    private var yDomain: ClosedRange<Double> {
        var allValues: [Double] = progressWeeks.map(\.weekAverage.average)
        allValues.append(contentsOf: progressWeeks.compactMap(\.goal))
        // Also include goal line endpoints from blocks
        for block in blocks {
            for i in 0...block.weeks {
                allValues.append(block.goalForWeek(i))
            }
        }
        guard let lo = allValues.min(), let hi = allValues.max() else {
            return 100...200
        }
        let padding = max((hi - lo) * 0.1, 1.0)
        return (lo - padding)...(hi + padding)
    }

    private var weekCount: Int { progressWeeks.count }

    private var xAxisByMonth: Bool { weekCount > 16 }
    private var xStrideCount: Int {
        if weekCount <= 8 { return 1 }
        if weekCount <= 16 { return 2 }
        // month-based: 1 label per month for ≤6 months, per 2 months beyond that
        if weekCount <= 26 { return 1 }
        return 2
    }

    private var selectedProgressWeek: ProgressWeek? {
        guard let selected = selectedWeek else { return nil }
        let selectedMonday = selected.startOfWeek
        return progressWeeks.first { $0.weekAverage.weekKey.monday == selectedMonday }
    }

    var body: some View {
        Chart {
            // Layer 1: Block background shading
            ForEach(blocks, id: \.persistentModelID) { block in
                RectangleMark(
                    xStart: .value("Start", block.startDate),
                    xEnd: .value("End", block.endDate),
                    yStart: .value("Lo", yDomain.lowerBound),
                    yEnd: .value("Hi", yDomain.upperBound)
                )
                .foregroundStyle(WeightViewModel.blockColor(for: block.type).opacity(0.06))
            }

            // Layer 2: Goal lines (dashed) — one series per block
            ForEach(blocks, id: \.persistentModelID) { block in
                let goalPoints = goalLinePoints(for: block)
                ForEach(goalPoints, id: \.date) { point in
                    LineMark(
                        x: .value("Week", point.date),
                        y: .value("Goal", point.weight),
                        series: .value("Goal", "goal-\(block.startDate.timeIntervalSince1970)")
                    )
                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                    .foregroundStyle(WeightViewModel.blockColor(for: block.type).opacity(0.5))
                }
            }

            // Layer 3: Area fill under average line
            ForEach(progressWeeks) { pw in
                AreaMark(
                    x: .value("Week", pw.weekAverage.weekKey.monday),
                    y: .value("Weight", pw.weekAverage.average)
                )
                .foregroundStyle(
                    .linearGradient(
                        colors: [AppColors.accent.opacity(0.15), AppColors.accent.opacity(0.02)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)
            }

            // Layer 4: Average weight line + points
            ForEach(progressWeeks) { pw in
                LineMark(
                    x: .value("Week", pw.weekAverage.weekKey.monday),
                    y: .value("Weight", pw.weekAverage.average),
                    series: .value("Average", "average")
                )
                .foregroundStyle(AppColors.accent)
                .lineStyle(StrokeStyle(lineWidth: 2.5))
                .interpolationMethod(.catmullRom)
            }

            if weekCount <= 20 {
                ForEach(progressWeeks) { pw in
                    PointMark(
                        x: .value("Week", pw.weekAverage.weekKey.monday),
                        y: .value("Weight", pw.weekAverage.average)
                    )
                    .foregroundStyle(AppColors.accent)
                    .symbolSize(30)
                }
            }

            // Layer 5: Selection indicator
            if let selected = selectedWeek {
                RuleMark(x: .value("Selected", selected.startOfWeek))
                    .foregroundStyle(AppColors.textMuted.opacity(0.4))
                    .lineStyle(StrokeStyle(lineWidth: 1))
            }
        }
        .chartYScale(domain: yDomain)
        .chartPlotStyle { plotArea in
            plotArea.clipped()
        }
        .chartXSelection(value: $selectedWeek)
        .chartXAxis {
            AxisMarks(values: .stride(by: xAxisByMonth ? .month : .weekOfYear, count: xStrideCount)) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(AppColors.border)
                AxisValueLabel {
                    if let date = value.as(Date.self) {
                        if xAxisByMonth {
                            Text(date, format: .dateTime.month(.abbreviated))
                                .font(.system(size: 10, design: .rounded))
                                .foregroundStyle(AppColors.textMuted)
                        } else {
                            Text(date, format: .dateTime.month(.abbreviated).day())
                                .font(.system(size: 10, design: .rounded))
                                .foregroundStyle(AppColors.textMuted)
                        }
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(AppColors.border)
                AxisValueLabel {
                    if let weight = value.as(Double.self) {
                        Text(String(format: "%.0f", weight))
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(AppColors.textMuted)
                    }
                }
            }
        }
        .chartBackground { _ in Color.clear }
        .overlay(alignment: .top) {
            if let pw = selectedProgressWeek {
                selectionTooltip(pw)
                    .transition(.opacity)
            }
        }
    }

    // MARK: - Goal Line Points

    private struct GoalPoint: Identifiable {
        let date: Date
        let weight: Double
        var id: Date { date }
    }

    private func goalLinePoints(for block: Block) -> [GoalPoint] {
        (0..<block.weeks).map { i in
            let monday = Calendar.mondayBased.date(byAdding: .day, value: i * 7, to: block.startDate)!
            return GoalPoint(date: monday, weight: block.goalForWeek(i))
        }
    }

    // MARK: - Selection Tooltip

    private func selectionTooltip(_ pw: ProgressWeek) -> some View {
        VStack(spacing: 4) {
            Text(pw.weekAverage.weekKey.rangeString)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(AppColors.textSecondary)

            Text(String(format: "%.1f lbs", pw.weekAverage.average))
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                .foregroundStyle(AppColors.textPrimary)

            if let goal = pw.goal {
                let delta = pw.weekAverage.average - goal
                Text("Goal: \(String(format: "%.1f", goal)) (\(WeightViewModel.deltaString(delta)))")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(WeightViewModel.deltaColor(delta: delta, blockType: pw.blockType))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
        .padding(.top, 4)
    }
}
