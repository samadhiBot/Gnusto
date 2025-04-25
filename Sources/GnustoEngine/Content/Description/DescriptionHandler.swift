import Foundation

/// A handler that can generate dynamic descriptions for items based on game state.
public struct DescriptionHandler: Codable, Sendable, Equatable {
    /// The unique identifier for this description handler.
    public let id: DescriptionHandlerID

    /// The static description to use if no dynamic logic is provided.
    public let staticDescription: String?

    /// Optional closure that generates a dynamic description based on game state.
    /// This is not directly Codable, so we'll use a handler ID pattern.
    public let dynamicHandlerID: String?

    /// Creates a new description handler with a static description.
    /// - Parameter staticDescription: The static text to use for the description.
    public init(staticDescription: String?) {
        self.id = DescriptionHandlerID(UUID().uuidString)
        self.staticDescription = staticDescription
        self.dynamicHandlerID = nil
    }

    /// Creates a new description handler with a dynamic handler.
    /// - Parameters:
    ///   - handlerID: The ID of the dynamic handler to use.
    ///   - staticDescription: Optional fallback static description.
    public init(handlerID: String, staticDescription: String? = nil) {
        self.id = DescriptionHandlerID(UUID().uuidString)
        self.staticDescription = staticDescription
        self.dynamicHandlerID = handlerID
    }

    public static func == (lhs: DescriptionHandler, rhs: DescriptionHandler) -> Bool {
        lhs.id == rhs.id &&
        lhs.staticDescription == rhs.staticDescription &&
        lhs.dynamicHandlerID == rhs.dynamicHandlerID
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
