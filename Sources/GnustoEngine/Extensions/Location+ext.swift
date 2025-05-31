import Foundation

extension Array where Element == Location {
    /// <#Description#>
    /// - Parameter id: <#id description#>
    /// - Returns: <#description#>
    func find(_ id: LocationID) -> Location? {
        first { $0.id == id }
    }
}
