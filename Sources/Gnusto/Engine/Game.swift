import Foundation

/// Protocol for defining a game using the Gnusto engine.
public protocol Game {
    /// Welcome text displayed when the game starts.
    var welcomeText: String { get }

    /// Version and authorship information.
    var versionInfo: String { get }

    /// Creates the initial game world.
    ///
    /// - Returns: A configured World instance.
    func createWorld() throws -> World

    /// Defines custom actions for this game.
    ///
    /// - Returns: An array of custom actions.
    func defineCustomActions() -> [CustomAction]

    /// Defines event handlers for this game.
    ///
    /// - Returns: An array of event handlers.
    func defineEventHandlers() -> [EventHandler]
}

/// A custom action defined by the game.
public struct CustomAction {
    /// The verb that triggers this action.
    public let verb: String

    /// The handler function that processes this action.
    public let handler: (ActionContext) -> [Effect]

    /// Creates a new custom action.
    public init(verb: String, handler: @escaping (ActionContext) -> [Effect]) {
        self.verb = verb
        self.handler = handler
    }
}

/// An event handler defined by the game.
public struct EventHandler {
    /// The ID of the event to handle.
    public let id: Event.ID

    /// The handler function that processes this event.
    public let handler: (World) -> [Effect]

    /// Creates a new event handler.
    public init(id: Event.ID, handler: @escaping (World) -> [Effect]) {
        self.id = id
        self.handler = handler
    }
}

/// Extension providing default implementations.
extension Game {
    /// Default implementation returns an empty array.
    public func defineCustomActions() -> [CustomAction] {
        []
    }

    /// Default implementation returns an empty array.
    public func defineEventHandlers() -> [EventHandler] {
        []
    }
}
