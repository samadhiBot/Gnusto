import Foundation

/// A structure representing a preposition in natural language.
///
/// Prepositions are words that show relationships between other words in a sentence,
/// typically indicating location, direction, time, or manner. This type provides
/// a type-safe way to work with prepositions in Swift code.
///
/// The `Preposition` type conforms to `ExpressibleByStringLiteral`, allowing
/// you to create instances using string literals:
///
/// ```swift
/// let preposition: Preposition = "under"
/// ```
///
/// Common prepositions are available as static properties on the type.
public struct Preposition: Codable, Sendable, Hashable, ExpressibleByStringLiteral {
    /// The string value of the preposition.
    var rawValue: String

    public init(stringLiteral value: StringLiteralType) {
        rawValue = value
    }
}

extension Preposition {
    /// The preposition `about`.
    public static let about: Preposition = "about"

    /// The preposition `above`.
    public static let above: Preposition = "above"

    /// The preposition `across`.
    public static let across: Preposition = "across"

    /// The preposition `after`.
    public static let after: Preposition = "after"

    /// The preposition `against`.
    public static let against: Preposition = "against"

    /// The preposition `along`.
    public static let along: Preposition = "along"

    /// The preposition `among`.
    public static let among: Preposition = "among"

    /// The preposition `around`.
    public static let around: Preposition = "around"

    /// The preposition `at`.
    public static let at: Preposition = "at"

    /// The preposition `before`.
    public static let before: Preposition = "before"

    /// The preposition `behind`.
    public static let behind: Preposition = "behind"

    /// The preposition `below`.
    public static let below: Preposition = "below"

    /// The preposition `beneath`.
    public static let beneath: Preposition = "beneath"

    /// The preposition `beside`.
    public static let beside: Preposition = "beside"

    /// The preposition `between`.
    public static let between: Preposition = "between"

    /// The preposition `beyond`.
    public static let beyond: Preposition = "beyond"

    /// The preposition `by`.
    public static let by: Preposition = "by"

    /// The preposition `down`.
    public static let down: Preposition = "down"

    /// The preposition `during`.
    public static let during: Preposition = "during"

    /// The preposition `for`.
    public static let `for`: Preposition = "for"

    /// The preposition `from`.
    public static let from: Preposition = "from"

    /// The preposition `in`.
    public static let `in`: Preposition = "in"

    /// The preposition `inside`.
    public static let inside: Preposition = "inside"

    /// The preposition `into`.
    public static let into: Preposition = "into"

    /// The preposition `near`.
    public static let near: Preposition = "near"

    /// The preposition `of`.
    public static let of: Preposition = "of"

    /// The preposition `off`.
    public static let off: Preposition = "off"

    /// The preposition `on`.
    public static let on: Preposition = "on"

    /// The preposition `onto`.
    public static let onto: Preposition = "onto"

    /// The preposition `out`.
    public static let out: Preposition = "out"

    /// The preposition `outside`.
    public static let outside: Preposition = "outside"

    /// The preposition `over`.
    public static let over: Preposition = "over"

    /// The preposition `through`.
    public static let through: Preposition = "through"

    /// The preposition `to`.
    public static let to: Preposition = "to"

    /// The preposition `toward`.
    public static let toward: Preposition = "toward"

    /// The preposition `under`.
    public static let under: Preposition = "under"

    /// The preposition `up`.
    public static let up: Preposition = "up"

    /// The preposition `upon`.
    public static let upon: Preposition = "upon"

    /// The preposition `with`.
    public static let with: Preposition = "with"

    /// The preposition `within`.
    public static let within: Preposition = "within"

    /// The preposition `without`.
    public static let without: Preposition = "without"
}

// MARK: - Conformances

extension Preposition: CustomStringConvertible {
    public var description: String {
        rawValue
    }
}

extension Set where Element == Preposition {
    func contains(_ prepositionString: String) -> Bool {
        firstIndex(of: Preposition(stringLiteral: prepositionString)) != nil
    }
}
