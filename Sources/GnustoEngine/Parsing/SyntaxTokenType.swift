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

extension SyntaxTokenType: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self = .particle(value)
    }
}

extension SyntaxTokenType {
    static let about: SyntaxTokenType = .particle("about")

    static let at: SyntaxTokenType = .particle("at")

    static let behind: SyntaxTokenType = .particle("behind")

    static let down: SyntaxTokenType = .particle("down")

    static let `for`: SyntaxTokenType = .particle("for")

    static let from: SyntaxTokenType = .particle("from")

    static let `in`: SyntaxTokenType = .particle("in")

    static let inside: SyntaxTokenType = .particle("inside")

    static let into: SyntaxTokenType = .particle("into")

    static let on: SyntaxTokenType = .particle("on")

    static let onto: SyntaxTokenType = .particle("onto")

    static let over: SyntaxTokenType = .particle("over")

    static let through: SyntaxTokenType = .particle("through")

    static let to: SyntaxTokenType = .particle("to")

    static let under: SyntaxTokenType = .particle("under")

    static let up: SyntaxTokenType = .particle("up")

    static let with: SyntaxTokenType = .particle("with")
}
