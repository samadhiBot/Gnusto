import Foundation

extension Item {
    /// The item's name prepended with the appropriate indefinite article ("a" or "an").
    ///
    /// Uses the simple rule: "an" if the string starts with a vowel (a, e, i, o, u), ignoring case,
    /// and "a" otherwise. Handles empty strings gracefully.
    var withIndefiniteArticle: String {
        guard !hasFlag(.suppressArticle), let firstChar = name.first?.lowercased() else {
            return name
        }
        let vowels: Set<Character> = ["a", "e", "i", "o", "u"]
        return vowels.contains(firstChar) ? "an \(name)" : "a \(name)"
    }
    
    /// The item's name prepended with a definite article ("the").
    ///
    /// This is only useful in optional item scenarios, e.g. `item?.withDefiniteArticle ?? "it"`.
    var withDefiniteArticle: String {
        "the \(name)"
    }
}
