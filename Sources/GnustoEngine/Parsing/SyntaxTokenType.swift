import Foundation

/// Represents the type of a token expected at a specific position within a `SyntaxRule`'s pattern.
///
/// Each case defines a category of word or phrase the parser looks for when trying to match
/// player input against a known grammatical structure.
public enum SyntaxTokenType: Sendable, Equatable, Codable {
    /// Expects the main verb of the command (e.g., "TAKE", "GO", "LOOK").
    /// This is typically the first significant token matched by the parser.
    case verb

    /// Expects a noun phrase that will be identified as the direct object of the
    /// verb (e.g., the "APPLE" in "TAKE APPLE") _or_ the object of a preposition
    /// (e.g. the "ANT" in "YELL AT THE ANT").
    case directObject

    /// Expects a noun phrase that will be identified as the indirect object of the
    /// verb (e.g., the "BAG" in "PUT APPLE IN BAG").
    case indirectObject

    /// Expects a word indicating a direction of movement (e.g., "NORTH", "UP", "WEST").
    case direction  // Matches a known direction word (e.g., "north", "n")

    /// Expects a specific particle word that is part of a phrasal verb or special command
    /// syntax (e.g., the "ON" in "TURN LIGHT ON", or "ABOUT" in "THINK ABOUT TOPIC").
    /// The associated `String` value is the exact particle word expected.
    case particle(String)  // Matches a specific particle word (e.g., "on", "off")
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
    static let about: SyntaxTokenType = .particle("about")

    /// Expects the particle "at" (e.g., "LOOK AT PAINTING").
    static let at: SyntaxTokenType = .particle("at")

    /// Expects the particle "behind" (e.g., "LOOK BEHIND DOOR").
    static let behind: SyntaxTokenType = .particle("behind")

    /// Expects the particle "down" (e.g., "CLIMB DOWN LADDER").
    static let down: SyntaxTokenType = .particle("down")

    /// Expects the particle "for" (e.g., "SEARCH FOR TREASURE").
    static let `for`: SyntaxTokenType = .particle("for")

    /// Expects the particle "from" (e.g., "TAKE COIN FROM POCKET").
    static let from: SyntaxTokenType = .particle("from")

    /// Expects the particle "in" (e.g., "PUT APPLE IN BAG").
    static let `in`: SyntaxTokenType = .particle("in")

    /// Expects the particle "inside" (e.g., "LOOK INSIDE BOX").
    static let inside: SyntaxTokenType = .particle("inside")

    /// Expects the particle "into" (e.g., "GO INTO CAVE").
    static let into: SyntaxTokenType = .particle("into")

    /// Expects the particle "on" (e.g., "PUT BOOK ON TABLE").
    static let on: SyntaxTokenType = .particle("on")

    /// Expects the particle "onto" (e.g., "CLIMB ONTO CHAIR").
    static let onto: SyntaxTokenType = .particle("onto")

    /// Expects the particle "over" (e.g., "JUMP OVER FENCE").
    static let over: SyntaxTokenType = .particle("over")

    /// Expects the particle "through" (e.g., "GO THROUGH DOOR").
    static let through: SyntaxTokenType = .particle("through")

    /// Expects the particle "to" (e.g., "GIVE COIN TO MERCHANT").
    static let to: SyntaxTokenType = .particle("to")

    /// Expects the particle "under" (e.g., "LOOK UNDER RUG").
    static let under: SyntaxTokenType = .particle("under")

    /// Expects the particle "up" (e.g., "CLIMB UP TREE").
    static let up: SyntaxTokenType = .particle("up")

    /// Expects the particle "with" (e.g., "UNLOCK DOOR WITH KEY").
    static let with: SyntaxTokenType = .particle("with")
}
