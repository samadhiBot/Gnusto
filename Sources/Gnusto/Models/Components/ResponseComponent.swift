import Foundation
// No longer needs Nitfol

/// A function type for handling object-specific responses to parsed commands.
public typealias ResponseHandler = @Sendable (World, UserInput) -> ResponseResult

/// A component that holds command-specific responses for an object.
/// Responses are keyed by the lowercase string representation of the command verb.
public struct ResponseComponent: Component, Sendable {
    public static let type: ComponentType = .response

    /// List of responses for this object, keyed by lowercase verb string.
    private var responses: [VerbID: ResponseHandler]

    /// Creates a new response component.
    public init(_ responses: [VerbID: ResponseHandler] = [:]) {
        self.responses = responses
    }

    /// Adds a response handler for a specific command verb.
    /// - Parameters:
    ///   - verb: The command verb string (e.g., "look", "push"). Case-insensitive.
    ///   - handler: The handler function to call when this command verb is used on the object.
    public mutating func addResponse(
        for verb: VerbID,
        handler: @escaping ResponseHandler
    ) {
        responses[verb] = handler
    }

    /// Gets a response handler for a specific user input, if one exists for its verb.
    ///
    /// - Parameter command: The parsed command.
    /// - Returns: A response handler, or `nil` if none exists for the command's verb.
    public func getResponse(for command: UserInput) -> ResponseHandler? {
        guard let verb = command.verb else { return nil } // verb is String?
        return responses[verb]
    }

    /// Checks if this component has a response for a specific user input's verb.
    ///
    /// - Parameter command: The parsed command.
    /// - Returns: True if a response exists for the command's verb.
    public func hasResponse(for command: UserInput) -> Bool {
        guard let verb = command.verb else { return false }
        return responses.keys.contains(verb)
    }

    /// Removes a response for a specific verb string.
    ///
    /// - Parameter verb: The verb string to remove the response for. Case-insensitive.
    public mutating func removeResponse(for verb: VerbID) {
        responses[verb] = nil
    }
}

// MARK: - Object extensions

extension Object {
    /// Adds a response for a specific command verb to this object.
    ///
    /// - Parameters:
    ///   - verb: The command verb string (e.g., "examine"). Case-insensitive.
    ///   - handler: The handler function (taking `World` and `UserInput`) to call.
    /// - Returns: The updated object, for chaining.
    @discardableResult
    public func withResponse(
        for verb: VerbID,
        handler: @escaping ResponseHandler
    ) -> Self {
        var component = find(ResponseComponent.self) ?? ResponseComponent()
        component.addResponse(for: verb, handler: handler)
        add(component)
        return self
    }

    /// Adds responses for specific command verbs to this object.
    ///
    /// - Parameter handlers: A dictionary mapping lowercase verb strings to response handlers.
    /// - Returns: The updated object, for chaining.
    @discardableResult
    public func withResponses(
        _ handlers: [VerbID: ResponseHandler]
    ) -> Self {
        for (verb, handler) in handlers {
            withResponse(for: verb, handler: handler)
        }
        return self
    }
}
