import Foundation

// MARK: - Monday-based Calendar

extension Calendar {
    static let mondayBased: Calendar = {
        var cal = Calendar(identifier: .iso8601)
        cal.firstWeekday = 2 // Monday
        return cal
    }()
}

// MARK: - Date Extensions

extension Date {
    var startOfDay: Date {
        Calendar.mondayBased.startOfDay(for: self)
    }

    /// The Monday of the week containing this date.
    var startOfWeek: Date {
        let cal = Calendar.mondayBased
        let components = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        return cal.date(from: components)!
    }

    /// The Sunday ending the week containing this date.
    var endOfWeek: Date {
        Calendar.mondayBased.date(byAdding: .day, value: 6, to: startOfWeek)!
    }

    /// Format as "Mon, Feb 3"
    var shortDisplay: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        return formatter.string(from: self)
    }

    /// Format as "Feb 3 – Feb 9"
    static func weekRangeString(monday: Date) -> String {
        let sunday = Calendar.mondayBased.date(byAdding: .day, value: 6, to: monday)!
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM d"
        return "\(fmt.string(from: monday)) – \(fmt.string(from: sunday))"
    }

    /// Number of complete weeks between two Mondays.
    static func weeksBetween(_ start: Date, _ end: Date) -> Int {
        let days = Calendar.mondayBased.dateComponents([.day], from: start.startOfWeek, to: end.startOfWeek).day ?? 0
        return days / 7
    }
}

// MARK: - WeekKey

/// A value type identifying a specific Monday-to-Sunday week.
struct WeekKey: Hashable, Comparable, Identifiable {
    let monday: Date

    var id: Date { monday }

    init(_ date: Date) {
        self.monday = date.startOfWeek
    }

    var sunday: Date {
        Calendar.mondayBased.date(byAdding: .day, value: 6, to: monday)!
    }

    var rangeString: String {
        Date.weekRangeString(monday: monday)
    }

    static func < (lhs: WeekKey, rhs: WeekKey) -> Bool {
        lhs.monday < rhs.monday
    }
}
