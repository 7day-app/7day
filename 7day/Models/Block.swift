import Foundation
import SwiftData

enum BlockType: String, Codable, CaseIterable {
    case cut, bulk, maintain
}

@Model
final class Block {
    var type: BlockType
    var startDate: Date
    var weeks: Int
    var startWeight: Double
    var rate: Double
    var createdAt: Date

    init(type: BlockType, startDate: Date, weeks: Int, startWeight: Double, rate: Double) {
        self.type = type
        self.startDate = startDate.startOfWeek
        self.weeks = weeks
        self.startWeight = startWeight
        self.rate = rate
        self.createdAt = .now
    }
}

extension Block {
    var endDate: Date {
        Calendar.mondayBased.date(byAdding: .day, value: (weeks * 7) - 1, to: startDate)!
    }

    var multiplier: Double {
        switch type {
        case .cut: -1.0
        case .bulk: 1.0
        case .maintain: 0.0
        }
    }

    var weeklyChange: Double {
        startWeight * (rate / 100.0) * multiplier
    }

    func goalForWeek(_ weekIndex: Int) -> Double {
        startWeight + (weeklyChange * Double(weekIndex))
    }

    var goalEndWeight: Double {
        goalForWeek(weeks)
    }

    var totalChange: Double {
        goalEndWeight - startWeight
    }

    func containsDate(_ date: Date) -> Bool {
        let day = date.startOfDay
        return day >= startDate && day <= endDate
    }

    func weekIndex(for date: Date) -> Int? {
        let monday = date.startOfWeek
        guard monday >= startDate else { return nil }
        let days = Calendar.mondayBased.dateComponents([.day], from: startDate, to: monday).day ?? 0
        let index = days / 7
        guard index < weeks else { return nil }
        return index
    }

    var isActive: Bool {
        containsDate(.now)
    }
}
