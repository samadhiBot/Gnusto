import Foundation

/// A type-safe key for accessing game-specific global variables or flags stored in
/// `GameState.globalState`.
///
/// `GlobalID`s provide a structured way to manage global state that isn't directly tied to
/// specific items or locations. This can include:
/// - Boolean flags indicating story progression (e.g., `GlobalID("metTheKing")`).
/// - Numeric counters for game-wide events (e.g., `GlobalID("dragonsSlain")`).
/// - Configuration settings or miscellaneous state values.
///
/// Using `GlobalID` instead of raw strings helps prevent typos and improves code clarity.
/// It is `Codable` for game state persistence and `ExpressibleByStringLiteral` for ease of use.
public struct GlobalID: GnustoID {
    public let rawValue: String

    /// Creates a new game state key with the specified string value.
    /// - Parameter rawValue: The string representation of the key.
    public init(rawValue: String) {
        assert(rawValue.isNotEmpty, "Global ID cannot be empty")
        self.rawValue = rawValue
    }
}

// MARK: - Standard Global IDs

extension GlobalID {
    /// Flag indicating brief mode is enabled (show location descriptions only on first visit)
    public static let isBriefMode = GlobalID("isBriefMode")

    /// Flag indicating transcript recording is currently active
    public static let isScripting = GlobalID("isScripting")

    /// Flag indicating verbose mode is enabled (show full location descriptions every time)
    public static let isVerboseMode = GlobalID("isVerboseMode")

    // MARK: - Conversation System

    /// The type of question currently being asked (e.g., "topic", "yesno", "choice")
    public static let pendingQuestionType = GlobalID("pendingQuestionType")

    /// The prompt message for the current question
    public static let pendingQuestionPrompt = GlobalID("pendingQuestionPrompt")

    /// The character or item ID that initiated the question
    public static let pendingQuestionSource = GlobalID("pendingQuestionSource")

    /// Additional context data for the current question (e.g., verb, topic context)
    public static let pendingQuestionContext = GlobalID("pendingQuestionContext")
}
