import Foundation
import Markdown

/// A type that can generate a dynamic description for an item based on game state.
public typealias DynamicDescriptionHandler = @MainActor (Item, GameEngine) async -> String

/// A type that can generate a dynamic description for a location based on game state.
public typealias DynamicLocationDescriptionHandler = @MainActor (Location, GameEngine) async -> String

/// A registry that manages description handlers and their dynamic logic.
@MainActor
public class DescriptionHandlerRegistry {
    /// Dictionary mapping item handler IDs to their dynamic logic.
    private var dynamicItemHandlers: [DescriptionHandlerID: DynamicDescriptionHandler]

    /// Dictionary mapping location handler IDs to their dynamic logic.
    private var dynamicLocationHandlers: [DescriptionHandlerID: DynamicLocationDescriptionHandler]

    /// The maximum line length before soft-wrapping a description.
    private let maximumDescriptionLength: Int

    /// Creates a new empty registry.
    public init(maximumDescriptionLength: Int = .max) {
        self.dynamicItemHandlers = [:]
        self.dynamicLocationHandlers = [:]
        self.maximumDescriptionLength = maximumDescriptionLength
    }

    // --- Item Handlers ---

    /// Registers a new dynamic description handler for an item.
    ///
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
    ///   - item: The item to generate a description for.
    ///   - handler: The description handler to use.
    ///   - engine: The game engine providing context.
    /// - Returns: The generated description string.
    public func generateDescription(
        for item: Item,
        using handler: DescriptionHandler,
        engine: GameEngine
    ) async -> String {
        let raw = if let handlerID = handler.id,
                     let dynamicHandler = dynamicItemHandlers[handlerID] {
            await dynamicHandler(item, engine)
        } else if let rawStatic = handler.rawStaticDescription {
            rawStatic
        } else {
            "You see nothing special about the \(item.name)."
        }
        let document = Document(parsing: raw)
        return document.format(options: markupOptions)
            .trimmingCharacters(in: .whitespacesAndNewlines)
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
    /// Note: Assumes `Location` exists or will be created.
    /// - Parameters:
    ///   - location: The location to generate a description for.
    ///   - handler: The description handler to use.
    ///   - engine: The game engine providing context.
    /// - Returns: The generated description string.
    public func generateDescription(
        for location: Location,
        using handler: DescriptionHandler,
        engine: GameEngine
    ) async -> String {
        let raw = if let handlerID = handler.id,
                     let dynamicHandler = dynamicLocationHandlers[handlerID] {
            await dynamicHandler(location, engine)
        } else if let rawStatic = handler.rawStaticDescription {
            rawStatic
        } else {
            "You are in the \(location.name)."
        }
        let document = Document(parsing: raw)
        return document.format(
            options: .init(
                preferredLineLimit: .init(maxLength: .max, breakWith: .hardBreak),
            )
        )
        .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

extension DescriptionHandlerRegistry {
    private var markupOptions: MarkupFormatter.Options {
        MarkupFormatter.Options(
            preferredLineLimit: MarkupFormatter.Options.PreferredLineLimit(
                maxLength: maximumDescriptionLength,
                breakWith: .hardBreak
            )
        )
    }
}
