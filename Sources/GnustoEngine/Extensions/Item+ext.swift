import Foundation

extension Item {
    /// The item's name prepended with a definite article ("the").
    ///
    /// This is only useful in optional item scenarios, e.g. `item?.withDefiniteArticle ?? "it"`.
    var withDefiniteArticle: String {
        hasFlag(.omitArticle) || name.isEmpty ? name : "the \(name)"
    }

    /// The item's name prepended with the appropriate indefinite article ("a" or "an").
    ///
    /// Uses the simple rule: "an" if the string starts with a vowel (a, e, i, o, u), ignoring case,
    /// and "a" otherwise. Handles empty strings gracefully.
    var withIndefiniteArticle: String {
        hasFlag(.omitArticle) || name.isEmpty ? name : name.withIndefiniteArticle
    }
}

extension Array where Element == Item {
    /// Returns the first item in the array with the specified ID.
    /// - Parameter id: The ItemID to search for.
    /// - Returns: The first item with the matching ID, or nil if not found.
    func find(_ id: ItemID) -> Item? {
        first { $0.id == id }
    }

    /// Returns a grammatically correct string listing the elements, sorted alphabetically,
    /// with appropriate definite articles prepended.
    ///
    /// Example: `["pear", "apple", "banana"]` becomes `"the apple, the banana, and the pear"`.
    /// Returns "nothing" for an empty array.
    var listWithDefiniteArticles: String {
        switch count {
        case 0:
            return "nothing"
        case 1:
            return self[0].withDefiniteArticle
        default:
            var items = sorted().map(\.withDefiniteArticle)
            let lastItem = items.removeLast()
            let oxfordComma = count == 2 ? "" : ","
            return "\(items.joined(separator: ", "))\(oxfordComma) and \(lastItem)"
        }
    }

    /// Returns a grammatically correct string listing the elements, sorted alphabetically,
    /// with appropriate indefinite articles prepended.
    ///
    /// Example: `["pear", "apple", "banana"]` becomes `"an apple, a banana, and a pear"`.
    /// Returns "nothing" for an empty array.
    var listWithIndefiniteArticles: String {
        switch count {
        case 0:
            return "nothing"
        case 1:
            return self[0].withIndefiniteArticle
        default:
            var items = sorted().map(\.withIndefiniteArticle)
            let lastItem = items.removeLast()
            let oxfordComma = count == 2 ? "" : ","
            return "\(items.joined(separator: ", "))\(oxfordComma) and \(lastItem)"
        }
    }
}
