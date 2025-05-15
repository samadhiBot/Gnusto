import Foundation

extension String {
    /// The string with the first letter capitalized.
    var capitalizedFirst: String {
        guard let firstCharacter = first else {
            return self
        }
        return String(firstCharacter).uppercased() + dropFirst()
    }

    /// The string prepended with the appropriate indefinite article ("a" or "an").
    ///
    /// Uses the simple rule: "an" if the string starts with a vowel (a, e, i, o, u), ignoring case,
    /// and "a" otherwise. Handles empty strings gracefully.
    var withIndefiniteArticle: String {
        guard let firstChar = first?.lowercased() else {
            return self
        }
        let vowels: Set<Character> = ["a", "e", "i", "o", "u"]
        return vowels.contains(firstChar) ? "an \(self)" : "a \(self)"
    }
}

extension Array where Element == String {
    /// Returns a grammatically correct string listing the elements, sorted alphabetically,
    /// comma-separated with the specified conjunction.
    ///
    /// - Parameter conjunction: The list's conjunction, i.e. "and" or "or".
    /// - Returns: The string listing the sorted elements.
    func commaListing(_ conjunction: String) -> String {
        switch count {
        case 0:
            return ""
        case 1:
            return self[0]
        default:
            var items = sorted()
            let lastItem = items.removeLast()
            return items.joined(separator: ", ") +
                   (count == 2 ? "" : ",") +
                   " \(conjunction) \(lastItem)"
        }
    }

    /// Returns a grammatically correct string listing the elements, sorted alphabetically,
    /// with appropriate indefinite articles prepended, or "nothing" for an empty array.
    ///
    /// Example: `["pear", "apple", "banana"]` becomes `"an apple, a banana and a pear"`.
    var listWithDefiniteArticles: String {
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
