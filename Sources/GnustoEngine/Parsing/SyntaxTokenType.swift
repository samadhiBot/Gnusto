import Foundation

/// Represents the type of a token expected at a specific position within a `SyntaxRule`'s pattern.
///
/// Each case defines a category of word or phrase the parser looks for when trying to match
/// player input against a known grammatical structure.
public enum SyntaxTokenType: Sendable, Equatable, Codable {
    /// Expects a word indicating a direction of movement (e.g., "NORTH", "UP", "WEST").
    case direction  // Matches a known direction word (e.g., "north", "n")

    /// Expects a noun phrase that will be identified as the direct object of the
    /// verb (e.g., the "APPLE" in "TAKE APPLE") _or_ the object of a preposition
    /// (e.g. the "ANT" in "YELL AT THE ANT"). Expects a single object.
    case directObject

    /// Expects one or more noun phrases that will be identified as direct objects
    /// of the verb (e.g., "TAKE ALL" or "TAKE APPLE AND ORANGE"). Allows multiple objects.
    case directObjects

    /// Expects a noun phrase that will be identified as the indirect object of the
    /// verb (e.g., the "BAG" in "PUT APPLE IN BAG"). Expects a single object.
    case indirectObject

    /// Expects one or more noun phrases that will be identified as indirect objects
    /// of the verb. Allows multiple objects.
    case indirectObjects

    /// Expects a specific particle word that is part of a phrasal verb or special command
    /// syntax (e.g., the "ON" in "TURN LIGHT ON", or "ABOUT" in "THINK ABOUT TOPIC").
    /// The associated `String` value is the exact particle word expected.
    case particle(String)  // Matches a specific particle word (e.g., "on", "off")

    /// Expects a specific verb word (e.g., "CHARGE" in "CHARGE UP CAR").
    /// This allows syntax rules to be specific to particular verb synonyms.
    /// The associated `Verb` value is the specific verb that must be used.
    case specificVerb(Verb)

    /// Expects the main verb of the command (e.g., "TAKE", "GO", "LOOK").
    /// This is typically the first significant token matched by the parser.
    case verb
}

// MARK: - Conformances

extension SyntaxTokenType: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self = .particle(value)
    }
}

// MARK: - Default English Prepositions

extension SyntaxTokenType {
    /// Expects the particle "about" (e.g., "THINK ABOUT PUZZLE").
    public static let about: SyntaxTokenType = .particle("about")

    /// Expects the particle "at" (e.g., "LOOK AT PAINTING").
    public static let at: SyntaxTokenType = .particle("at")

    /// Expects the particle "behind" (e.g., "LOOK BEHIND DOOR").
    public static let behind: SyntaxTokenType = .particle("behind")

    /// Expects the particle "below" (e.g., "LOOK BELOW STAIRS").
    public static let below: SyntaxTokenType = .particle("below")

    /// Expects the particle "beneath" (e.g., "LOOK BENEATH THE DOORMAT").
    public static let beneath: SyntaxTokenType = .particle("beneath")

    /// Expects the particle "down" (e.g., "CLIMB DOWN LADDER").
    public static let down: SyntaxTokenType = .particle("down")

    /// Expects the particle "for" (e.g., "SEARCH FOR TREASURE").
    public static let `for`: SyntaxTokenType = .particle("for")

    /// Expects the particle "from" (e.g., "TAKE COIN FROM POCKET").
    public static let from: SyntaxTokenType = .particle("from")

    /// Expects the particle "in" (e.g., "PUT APPLE IN BAG").
    public static let `in`: SyntaxTokenType = .particle("in")

    /// Expects the particle "inside" (e.g., "LOOK INSIDE BOX").
    public static let inside: SyntaxTokenType = .particle("inside")

    /// Expects the particle "into" (e.g., "GO INTO CAVE").
    public static let into: SyntaxTokenType = .particle("into")

    /// Expects the particle "off" (e.g., "TAKE OFF HAT").
    public static let off: SyntaxTokenType = .particle("off")

    /// Expects the particle "on" (e.g., "PUT BOOK ON TABLE").
    public static let on: SyntaxTokenType = .particle("on")

    /// Expects the particle "onto" (e.g., "CLIMB ONTO CHAIR").
    public static let onto: SyntaxTokenType = .particle("onto")

    /// Expects the particle "out" (e.g., "POUR OUT WATER").
    public static let out: SyntaxTokenType = .particle("out")

    /// Expects the particle "over" (e.g., "JUMP OVER FENCE").
    public static let over: SyntaxTokenType = .particle("over")

    /// Expects the particle "through" (e.g., "GO THROUGH DOOR").
    public static let through: SyntaxTokenType = .particle("through")

    /// Expects the particle "to" (e.g., "GIVE COIN TO MERCHANT").
    public static let to: SyntaxTokenType = .particle("to")

    /// Expects the particle "under" (e.g., "LOOK UNDER RUG").
    public static let under: SyntaxTokenType = .particle("under")

    /// Expects the particle "up" (e.g., "CLIMB UP TREE").
    public static let up: SyntaxTokenType = .particle("up")

    /// Expects the particle "with" (e.g., "UNLOCK DOOR WITH KEY").
    public static let with: SyntaxTokenType = .particle("with")
}

// MARK: - Verb-Specific Matching

extension SyntaxTokenType {
    /// Creates a syntax token that expects a specific verb word.
    ///
    /// This allows syntax rules to be specific to particular verb synonyms.
    /// For example, `.verb(.charge)` would only match if the player used "charge"
    /// specifically, not other synonyms for the same verb.
    ///
    /// - Parameter verbID: The specific verb ID that must be used
    /// - Returns: A syntax token that matches only the specified verb
    public static func verb(_ verbID: Verb) -> SyntaxTokenType {
        .specificVerb(verbID)
    }
}
