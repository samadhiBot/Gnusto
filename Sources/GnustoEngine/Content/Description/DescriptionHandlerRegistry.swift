import Foundation

/// A type that can generate a dynamic description for an item based on game state.
/// Runs on the MainActor.
public typealias DynamicDescriptionHandler = @MainActor (ItemSnapshot, GameEngine) async -> String

/// A type that can generate a dynamic description for a location based on game state.
/// Runs on the MainActor.
/// Note: Assumes `LocationSnapshot` exists or will be created.
public typealias DynamicLocationDescriptionHandler = @MainActor (LocationSnapshot, GameEngine) async -> String

/// A registry that manages description handlers and their dynamic logic.
/// The registry itself is an actor, but the handlers it calls run on the MainActor.
@MainActor // Make registry MainActor to simplify handler registration/calling
public class DescriptionHandlerRegistry { // Changed from actor to class
    /// Dictionary mapping item handler IDs to their dynamic logic.
    private var dynamicItemHandlers: [DescriptionHandlerID: DynamicDescriptionHandler]

    /// Dictionary mapping location handler IDs to their dynamic logic.
    private var dynamicLocationHandlers: [DescriptionHandlerID: DynamicLocationDescriptionHandler]

    /// Creates a new empty registry.
    public init() {
        self.dynamicItemHandlers = [:]
        self.dynamicLocationHandlers = [:]
    }

    // --- Item Handlers ---

    /// Registers a new dynamic description handler for an item.
    /// Must be called from the MainActor.
    /// - Parameters:
    ///   - id: The ID of the handler to register.
    ///   - handler: The closure that generates the dynamic description.
    public func registerItemHandler(
        id: DescriptionHandlerID,
        handler: @escaping DynamicDescriptionHandler
    ) {
        // No need for await as we are @MainActor
        dynamicItemHandlers[id] = handler
    }

    /// Generates a description for an item using its description handler.
    /// Must be called from the MainActor.
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
        // No need for await as we are @MainActor
        // If there's a dynamic handler, use it
        if let handlerID = handler.dynamicHandlerID,
           let dynamicHandler = dynamicItemHandlers[handlerID] {
            // Handler itself is @MainActor, await is fine
            return await dynamicHandler(item, engine)
        }

        // Otherwise, use the static description or a default message
        return handler.staticDescription ?? "You see nothing special about the \(item.name)."
    }

    // --- Location Handlers ---

    /// Registers a new dynamic description handler for a location.
    /// Must be called from the MainActor.
    /// - Parameters:
    ///   - id: The ID of the handler to register.
    ///   - handler: The closure that generates the dynamic description.
    public func registerLocationHandler(
        id: DescriptionHandlerID,
        handler: @escaping DynamicLocationDescriptionHandler
    ) {
        // No need for await
        dynamicLocationHandlers[id] = handler
    }

    /// Generates a description for a location using its description handler.
    /// Must be called from the MainActor.
    /// Note: Assumes `LocationSnapshot` exists or will be created.
    /// - Parameters:
    ///   - location: The location snapshot to generate a description for.
    ///   - handler: The description handler to use.
    ///   - engine: The game engine providing context.
    /// - Returns: The generated description string.
    public func generateDescription(
        for location: LocationSnapshot,
        using handler: DescriptionHandler,
        engine: GameEngine
    ) async -> String {
        // No need for await
        // If there's a dynamic handler, use it
        if let handlerID = handler.dynamicHandlerID,
           let dynamicHandler = dynamicLocationHandlers[handlerID] {
            // Handler itself is @MainActor, await is fine
            return await dynamicHandler(location, engine)
        }

        // Otherwise, use the static description or a default message
        // Consider a more appropriate default message for locations.
        return handler.staticDescription ?? "You are in the \(location.name)."
    }
}
