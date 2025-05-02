import Foundation

/// A handler that can generate dynamic descriptions for items based on game state.
/// Static descriptions can be provided as Markdown strings.
public struct DescriptionHandler: Codable, Sendable, Equatable {
    /// The unique identifier for this description handler.
    public let id: DescriptionHandlerID?

    /// The raw Markdown static description string.
    public let rawStaticDescription: String?
}

extension DescriptionHandler {
    /// Creates a dynamic description handler.
    ///
    /// - Parameters:
    ///   - id: The ID of the dynamic handler to use.
    ///   - staticDescription: Optional fallback static Markdown description.
    public static func id(
        _ id: DescriptionHandlerID,
        fallback staticDescription: String? = nil
    ) -> Self {
        DescriptionHandler(id: id, rawStaticDescription: staticDescription)
    }
}

extension DescriptionHandler: ExpressibleByStringLiteral {
    /// Creates a new description handler with a static Markdown description.
    ///
    /// - Tip: `DescriptionHandler` is `ExpressibleByStringLiteral`, so just use
    ///         a string literal when you want to create a static description.
    ///
    /// - Parameter value: The static text (Markdown allowed) to use for the description.
    public init(stringLiteral value: String) {
        self.id = nil
        self.rawStaticDescription = value
    }
}

/// A unique identifier for a description handler.
public struct DescriptionHandlerID: Hashable, Comparable, Codable, ExpressibleByStringLiteral, Sendable {
    public let rawValue: String

    public init(stringLiteral value: String) {
        self.rawValue = value
    }

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    public static func < (lhs: DescriptionHandlerID, rhs: DescriptionHandlerID) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
