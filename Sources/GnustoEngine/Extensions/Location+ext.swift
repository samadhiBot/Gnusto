import Foundation

extension Location {
    /// The location's name prepended with a definite article ("the").
    ///
    /// This is only useful in optional location scenarios,
    /// e.g. `location?.withDefiniteArticle ?? "it"`.
    var withDefiniteArticle: String {
        hasFlag(.omitArticle) || name.isEmpty ? name : "the \(name)"
    }

    /// The location's name prepended with the appropriate indefinite article ("a" or "an").
    ///
    /// Uses the simple rule: "an" if the string starts with a vowel (a, e, i, o, u), ignoring case,
    /// and "a" otherwise. Handles empty strings gracefully.
    var withIndefiniteArticle: String {
        hasFlag(.omitArticle) || name.isEmpty ? name : name.withIndefiniteArticle
    }
}

extension Array where Element == Location {
    /// Finds a location in the array by its unique identifier.
    ///
    /// - Parameter id: The unique identifier of the location to find.
    /// - Returns: The location with the matching ID, or nil if not found.
    func find(_ id: LocationID) -> Location? {
        first { $0.id == id }
    }
}
