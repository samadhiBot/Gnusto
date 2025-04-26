import Foundation
import Markdown

/// A handler that can generate dynamic descriptions for items based on game state.
/// Static descriptions can be provided as Markdown strings.
public struct DescriptionHandler: Codable, Sendable, Equatable, ExpressibleByStringLiteral {
    /// The unique identifier for this description handler.
    public let id: DescriptionHandlerID

    /// The raw, unprocessed static description string (may contain Markdown).
    /// Renamed from `staticDescription` to clarify it's unprocessed.
    public let rawStaticDescription: String?

    /// Optional closure that generates a dynamic description based on game state.
    /// This is not directly Codable, so we'll use a handler ID pattern.
    public let dynamicHandlerID: DescriptionHandlerID?

    /// Creates a new description handler with a dynamic handler.
    ///
    /// - Parameters:
    ///   - handlerID: The ID of the dynamic handler to use.
    ///   - staticDescription: Optional fallback static Markdown description.
    public init(
        id: DescriptionHandlerID,
        staticDescription: String? = nil
    ) {
        self.id = id
        self.rawStaticDescription = staticDescription
        self.dynamicHandlerID = id
    }

    /// Creates a new description handler with a static description (as Markdown).
    ///
    /// - Tip: `DescriptionHandler` is `ExpressibleByStringLiteral`, so just use
    ///         a string literal when you want to create a static description.
    ///
    /// - Parameter value: The static text (Markdown allowed) to use for the description.
    public init(stringLiteral value: String) {
        self.id = DescriptionHandlerID(UUID().uuidString)
        self.rawStaticDescription = value
        self.dynamicHandlerID = nil
    }

    /// The processed, plain-text static description, if one exists.
    public var staticDescription: String? {
        guard let raw = rawStaticDescription else { return nil }
        let document = Document(parsing: raw)
        return document.format().trimmingCharacters(in: .whitespacesAndNewlines)
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
