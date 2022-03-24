import Foundation

extension Date {

    /// Determine if `self` is before the specified `date`.
    /// - Parameters:
    ///   - date: The date to compare with
    ///   - inclusive: Whether to include `self` in comparison range (i.e. <=)
    /// - Returns: A boolean indicating if `self` is before specified `date`.
    public func isBefore(_ date: Date, inclusive: Bool = false) -> Bool {
        return inclusive ? self <= date : self < date
    }

    /// Determine if `self` is after the specified `date`.
    /// - Parameters:
    ///   - date: The date to compare with
    ///   - inclusive: Whether to include `self` in comparison range (i.e. >=)
    /// - Returns: A boolean indicating if `self` is after specified `date`.
    public func isAfter(_ date: Date, inclusive: Bool = false) -> Bool {
        return inclusive ? self >= date : self > date
    }
    func dateFormatWithSuffix() -> String {
            return "dd'\(self.daySuffix())' MMMM yyyy"
    }
    func daySuffix() -> String {
        let calendar = Calendar.current
        let components = (calendar as NSCalendar).components(.day, from: self)
        let dayOfMonth = components.day
        switch dayOfMonth {
        case 1, 21, 31:
            return "st"
        case 2, 22:
            return "nd"
        case 3, 23:
            return "rd"
        default:
            return "th"
        }
    }
}
