import Foundation

/// A type that can generate a dynamic description for an item based on game state.
public typealias DynamicDescriptionHandler = (ItemSnapshot, GameEngine) async -> String

/// A registry that manages description handlers and their dynamic logic.
public actor DescriptionHandlerRegistry {
    /// Dictionary mapping handler IDs to their dynamic logic.
    private var dynamicHandlers: [String: DynamicDescriptionHandler]

    /// Creates a new empty registry.
    public init() {
        self.dynamicHandlers = [:]
    }

    /// Registers a new dynamic description handler.
    /// - Parameters:
    ///   - id: The ID of the handler to register.
    ///   - handler: The closure that generates the dynamic description.
    public func registerHandler(id: String, handler: @escaping DynamicDescriptionHandler) {
        dynamicHandlers[id] = handler
    }

    /// Generates a description for an item using its description handler.
    /// - Parameters:
    ///   - item: The item snapshot to generate a description for.
    ///   - handler: The description handler to use.
    ///   - engine: The game engine providing context.
    /// - Returns: The generated description string.
    public func generateDescription(
        for item: ItemSnapshot,
        using handler: DescriptionHandler,
        engine: GameEngine
    ) async -> String {
        // If there's a dynamic handler, use it
        if let handlerID = handler.dynamicHandlerID,
           let dynamicHandler = dynamicHandlers[handlerID] {
            return await dynamicHandler(item, engine)
        }

        // Otherwise, use the static description or a default message
        return handler.staticDescription ?? "You see nothing special about the \(item.name)."
    }
}
