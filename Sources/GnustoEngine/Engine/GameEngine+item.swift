import Foundation

// MARK: - Item Descriptions

extension GameEngine {
    /// Generates a formatted description string for a specific item attribute, typically
    /// used for different kinds of textual descriptions (e.g., general description,
    /// text revealed on reading).
    ///
    /// This method attempts to fetch a dynamic or static string value for the given `itemID`
    /// and `AttributeID` (e.g., `.description`, `.readText`) using the engine's `fetch`
    /// mechanism. If a string is found, it's trimmed of whitespace. If no specific string
    /// is found for the attribute, a context-appropriate default description is provided
    /// (e.g., "You see nothing special about the {item}" for `.description`).
    ///
    /// - Parameters:
    ///   - itemID: The `ItemID` of the item for which to generate a description.
    ///   - attributeID: The `AttributeID` indicating the type of description requested (e.g.,
    ///          `.description`, `.shortDescription`, `.readText`).
    ///   - engine: The `GameEngine` instance, used for fetching dynamic values.
    ///             (Note: This parameter is often the same instance the method is called on).
    /// - Returns: A formatted description string.
    public func generateDescription(
        for itemID: ItemID,
        attributeID: AttributeID,
        engine: GameEngine
    ) async -> String {
        if let description: String = try? await engine.attribute(attributeID, of: itemID) {
            description.trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            await defaultItemDescription(
                for: itemID,
                attributeID: attributeID,
                engine: engine
            ).trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    /// Retrieves an immutable copy (snapshot) of a specific item from the current game state.
    ///
    /// - Parameter id: The `ItemID` of the item to retrieve.
    /// - Returns: An `Item` struct representing a snapshot of the specified item.
    /// - Throws: An `ActionResponse.internalEngineError` if no `id` is provided, or
    ///           `ActionResponse.itemNotAccessible` if the `ItemID` does not exist.
    public func item(_ id: ItemID?) throws -> Item {
        guard let id else {
            throw ActionResponse.internalEngineError("No item identifier provided.")
        }
        guard let item = gameState.items[id] else {
            throw ActionResponse.itemNotAccessible(id)
        }
        return item
    }

    /// Retrieves immutable copies (snapshots) of all items currently located within the
    /// specified parent entity (e.g., a location, the player, or a container item).
    ///
    /// - Parameter parent: The `ParentEntity` whose contents are to be retrieved.
    /// - Returns: An array of `Item` structs. The array will be empty if the parent
    ///            contains no items or if the parent entity itself is invalid.
    public func items(in parent: ParentEntity) -> [Item] {
        gameState.items.values
            .filter { $0.parent == parent }
    }
}

// MARK: - Private helpers

extension GameEngine {
    /// Provides a default description string for an item attribute when a specific one
    /// (dynamic or static) isn't found.
    ///
    /// This internal helper is called by `generateDescription(for:attributeID:engine:)` for items.
    /// It returns standard fallback text based on the `AttributeID` (e.g., "You see
    /// nothing special about the {item}." if `attributeID` is `.description`).
    private func defaultItemDescription(
        for itemID: ItemID,
        attributeID: AttributeID,
        engine: GameEngine
    ) async -> String {
        let item = try? await engine.item(itemID)
        return switch attributeID {
        case .description:
            "You see nothing special about \(item?.withDefiniteArticle ?? "it")."
        case .shortDescription:
            "\(item?.withIndefiniteArticle.capitalizedFirst ?? "An item")."
        case .firstDescription:
            "There is \(item?.withIndefiniteArticle ?? "something") here."
        case .readText:
            "There is nothing written on \(item?.withDefiniteArticle ?? "it")."
        case .readWhileHeldText:
            "Holding \(item?.withDefiniteArticle ?? "it") reveals nothing special."
        default:
            "\(item?.withDefiniteArticle.capitalizedFirst ?? "It") seems indescribable."
        }
    }
}
