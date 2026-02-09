import SwiftUI
import SwiftData

struct WeekAverage: Identifiable {
    let weekKey: WeekKey
    let average: Double
    let count: Int
    let min: Double
    let max: Double

    var id: Date { weekKey.monday }
}

struct ProgressWeek: Identifiable {
    let weekAverage: WeekAverage
    let goal: Double?
    let blockType: BlockType?

    var id: Date { weekAverage.weekKey.monday }
}

@Observable
final class WeightViewModel {
    // MARK: - Input State

    var weightText: String = ""
    var selectedDate: Date = Date().startOfDay

    // MARK: - Edit State

    var editingEntry: WeightEntry?
    var editWeightText: String = ""

    // MARK: - Computed Input

    var parsedWeight: Double? {
        guard let value = Double(weightText), value > 0, value < 1000 else { return nil }
        return value
    }

    var canLog: Bool {
        parsedWeight != nil
    }

    var parsedEditWeight: Double? {
        guard let value = Double(editWeightText), value > 0, value < 1000 else { return nil }
        return value
    }

    // MARK: - Actions

    func logWeight(context: ModelContext, existingEntries: [WeightEntry]) {
        guard let weight = parsedWeight else { return }
        let targetDate = selectedDate.startOfDay

        if let existing = existingEntries.first(where: { $0.date == targetDate }) {
            existing.weight = weight
        } else {
            let entry = WeightEntry(date: targetDate, weight: weight)
            context.insert(entry)
        }

        weightText = ""
    }

    func deleteEntry(_ entry: WeightEntry, context: ModelContext) {
        context.delete(entry)
    }

    func updateEntry(_ entry: WeightEntry, newWeight: Double, context: ModelContext) {
        entry.weight = newWeight
    }

    func beginEditing(_ entry: WeightEntry) {
        editingEntry = entry
        editWeightText = String(format: "%.1f", entry.weight)
    }

    // MARK: - Static Helpers

    static func weekAverage(for weekKey: WeekKey, from entries: [WeightEntry]) -> WeekAverage? {
        let weekEntries = entries.filter { $0.weekMonday == weekKey.monday }
        guard !weekEntries.isEmpty else { return nil }
        let weights = weekEntries.map(\.weight)
        let sum = weights.reduce(0, +)
        return WeekAverage(
            weekKey: weekKey,
            average: sum / Double(weights.count),
            count: weights.count,
            min: weights.min()!,
            max: weights.max()!
        )
    }

    static func thisWeekAverage(from entries: [WeightEntry]) -> WeekAverage? {
        weekAverage(for: WeekKey(Date()), from: entries)
    }

    static func lastWeekAverage(from entries: [WeightEntry]) -> WeekAverage? {
        let lastMonday = Calendar.mondayBased.date(byAdding: .day, value: -7, to: Date().startOfWeek)!
        return weekAverage(for: WeekKey(lastMonday), from: entries)
    }

    static func activeBlock(from blocks: [Block]) -> Block? {
        blocks.first(where: \.isActive)
    }

    static func currentGoal(block: Block?) -> Double? {
        guard let block else { return nil }
        guard let weekIndex = block.weekIndex(for: Date()) else { return nil }
        return block.goalForWeek(weekIndex)
    }

    static func deltaColor(delta: Double, blockType: BlockType?) -> Color {
        guard let blockType else { return AppColors.textSecondary }
        switch blockType {
        case .cut:
            return delta > 0 ? AppColors.negative : AppColors.positive
        case .bulk:
            return delta > 0 ? AppColors.positive : AppColors.negative
        case .maintain:
            return abs(delta) > 1.0 ? AppColors.negative : AppColors.textSecondary
        }
    }

    static func deltaString(_ delta: Double) -> String {
        let sign = delta >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f", delta)) lbs"
    }

    // MARK: - Progress Tab Helpers

    static func allWeeklyAverages(from entries: [WeightEntry]) -> [WeekAverage] {
        let grouped = Dictionary(grouping: entries) { $0.weekMonday }
        return grouped.compactMap { (monday, weekEntries) -> WeekAverage? in
            guard !weekEntries.isEmpty else { return nil }
            let weights = weekEntries.map(\.weight)
            let sum = weights.reduce(0, +)
            return WeekAverage(
                weekKey: WeekKey(monday),
                average: sum / Double(weights.count),
                count: weights.count,
                min: weights.min()!,
                max: weights.max()!
            )
        }
        .sorted { $0.weekKey < $1.weekKey }
    }

    static func progressWeeks(from entries: [WeightEntry], blocks: [Block]) -> [ProgressWeek] {
        let averages = allWeeklyAverages(from: entries)
        return averages.map { avg in
            let monday = avg.weekKey.monday
            if let block = blocks.first(where: { $0.containsDate(monday) }),
               let weekIdx = block.weekIndex(for: monday) {
                return ProgressWeek(
                    weekAverage: avg,
                    goal: block.goalForWeek(weekIdx),
                    blockType: block.type
                )
            }
            return ProgressWeek(weekAverage: avg, goal: nil, blockType: nil)
        }
    }

    static func blockColor(for type: BlockType) -> Color {
        switch type {
        case .cut: AppColors.cut
        case .bulk: AppColors.bulk
        case .maintain: AppColors.maintain
        }
    }

    // MARK: - Plan Tab Helpers

    static func blockOverlaps(startDate: Date, weeks: Int, existingBlocks: [Block], excluding: Block? = nil) -> Bool {
        let endDate = Calendar.mondayBased.date(byAdding: .day, value: (weeks * 7) - 1, to: startDate.startOfWeek)!
        return existingBlocks.contains { block in
            if let excluding, block.persistentModelID == excluding.persistentModelID { return false }
            return startDate.startOfWeek <= block.endDate && endDate >= block.startDate
        }
    }

    static func blockPreviewString(type: BlockType, startWeight: Double, rate: Double, weeks: Int) -> String {
        let multiplier: Double = switch type {
        case .cut: -1.0
        case .bulk: 1.0
        case .maintain: 0.0
        }
        let weeklyChange = startWeight * (rate / 100.0) * multiplier
        let endWeight = startWeight + (weeklyChange * Double(weeks))
        let totalChange = endWeight - startWeight
        let sign = totalChange >= 0 ? "+" : ""
        return "\(String(format: "%.1f", startWeight)) → \(String(format: "%.1f", endWeight)) lbs (\(sign)\(String(format: "%.1f", totalChange)) over \(weeks)wk)"
    }

    struct BlockWeekSummary: Identifiable {
        let weekIndex: Int
        let weekKey: WeekKey
        let goal: Double
        let actual: Double?
        let entryCount: Int

        var id: Int { weekIndex }
    }

    static func blockWeekSummaries(for block: Block, entries: [WeightEntry]) -> [BlockWeekSummary] {
        (0..<block.weeks).map { i in
            let monday = Calendar.mondayBased.date(byAdding: .day, value: i * 7, to: block.startDate)!
            let weekKey = WeekKey(monday)
            let avg = weekAverage(for: weekKey, from: entries)
            return BlockWeekSummary(
                weekIndex: i,
                weekKey: weekKey,
                goal: block.goalForWeek(i),
                actual: avg?.average,
                entryCount: avg?.count ?? 0
            )
        }
    }
}
