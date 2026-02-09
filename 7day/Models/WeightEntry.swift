import Foundation
import SwiftData

@Model
final class WeightEntry {
    #Unique<WeightEntry>([\.date])

    var date: Date
    var weight: Double
    var createdAt: Date

    init(date: Date, weight: Double) {
        self.date = date.startOfDay
        self.weight = weight
        self.createdAt = .now
    }
}

extension WeightEntry {
    var weekMonday: Date {
        date.startOfWeek
    }
}
