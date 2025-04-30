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
