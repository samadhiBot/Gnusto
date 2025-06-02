import Foundation

// MARK: - Item Descriptions

extension GameEngine {
    /// Fetches the boolean value of a dynamic or static attribute for a given item.
    ///
    /// This method first checks if a dynamic computation handler is registered for the
    /// specified `AttributeID` in the `dynamicAttributeRegistry`. If so, it executes
    /// the handler to get the value. Otherwise, it retrieves the statically stored value
    /// from the item's attributes.
    ///
    /// - Parameters:
    ///   - attributeID: The `AttributeID` of the boolean attribute.
    ///   - itemID: The `ItemID` of the item whose attribute is to be fetched.
    /// - Returns: The boolean value of the attribute.
    /// - Throws: `ActionResponse.invalidValue` if the attribute exists but is not a boolean,
    ///           or if the item does not exist. Returns `false` if the attribute is not set.
    public func attribute(
        _ attributeID: AttributeID,
        of itemID: ItemID
    ) async throws -> Bool {
        let value = await fetchStateValue(
            itemID: itemID,
            attributeID: attributeID
        )
        switch value {
        case .bool(let boolValue):
            return boolValue
        case nil:
            return false
        default:
            throw ActionResponse.invalidValue("""
                Cannot fetch boolean value for \(itemID.rawValue).\(attributeID.rawValue): \
                \(value ?? .undefined)
                """)
        }
    }

    /// Fetches the integer value of a dynamic or static attribute for a given item.
    ///
    /// Similar to the boolean `fetch`, this retrieves an integer value, checking for
    /// dynamic computation handlers first.
    ///
    /// - Parameters:
    ///   - attributeID: The `AttributeID` of the integer attribute.
    ///   - itemID: The `ItemID` of the item.
    /// - Returns: The integer value of the attribute.
    /// - Throws: `ActionResponse.invalidValue` if the attribute is not an integer, does not exist,
    ///           or the item does not exist.
    public func attribute(
        _ attributeID: AttributeID,
        of itemID: ItemID
    ) async throws -> Int {
        let value = await fetchStateValue(
            itemID: itemID,
            attributeID: attributeID
        )
        switch value {
        case .int(let intValue):
            return intValue
        default:
            throw ActionResponse.invalidValue("""
                Cannot fetch integer value for \(itemID.rawValue).\(attributeID.rawValue): \
                \(value ?? .undefined)
                """)
        }
    }

    /// Fetches the string value of a dynamic or static attribute for a given item.
    ///
    /// Similar to other `fetch` methods, this retrieves a string value, checking for
    /// dynamic computation handlers first. This is often used for dynamic descriptions.
    ///
    /// - Parameters:
    ///   - attributeID: The `AttributeID` of the string attribute (e.g., `.description`).
    ///   - itemID: The `ItemID` of the item.
    /// - Returns: The string value of the attribute.
    /// - Throws: `ActionResponse.invalidValue` if the attribute is not a string, does not exist,
    ///           or the item does not exist.
    public func attribute(
        _ attributeID: AttributeID,
        of itemID: ItemID
    ) async throws -> String {
        let value = await fetchStateValue(
            itemID: itemID,
            attributeID: attributeID
        )
        switch value {
        case .string(let stringValue):
            return stringValue
        default:
            throw ActionResponse.invalidValue("""
                Cannot fetch string value for \(itemID.rawValue).\(attributeID.rawValue): \
                \(value ?? .undefined)
                """)
        }
    }

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

// MARK: - Internal helpers

extension GameEngine {
    /// Validates a proposed value for an item attribute using the dynamic attribute registry.
    /// This is called internally when `StateChange`s are applied to ensure dynamic validation
    /// handlers are respected.
    ///
    /// - Parameters:
    ///   - attributeID: The `AttributeID` of the attribute being validated.
    ///   - itemID: The unique identifier of the item.
    ///   - newValue: The proposed new `StateValue`.
    /// - Returns: `true` if the value is valid or no validator is registered; `false` if validation fails.
    /// - Throws: Errors from the validation handler if it throws instead of returning `false`.
    func validateStateValue(
        itemID: ItemID,
        attributeID: AttributeID,
        newValue: StateValue
    ) async throws -> Bool {
        guard let item = gameState.items[itemID] else {
            return false // Item doesn't exist
        }

        return if let validateHandler = dynamicAttributeRegistry.itemValidateHandler(
            for: itemID,
            attributeID: attributeID
        ) {
            try await validateHandler(item, newValue)
        } else {
            true // No validator registered, allow the change
        }
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

    /// Retrieves the current value of a potentially dynamic item property.
    /// Checks the `DynamicAttributeRegistry` for a compute handler first.
    /// If no handler exists, returns the value stored in the item's `attributes`.
    ///
    /// - Parameters:
    ///   - attributeID: The `AttributeID` of the desired value.
    ///   - itemID: The unique identifier of the item.
    /// - Returns: The computed or stored `StateValue`, or `nil` if the item or value doesn't exist.
    private func fetchStateValue(
        itemID: ItemID,
        attributeID: AttributeID
    ) async -> StateValue? {
        guard let item = gameState.items[itemID] else {
            logWarning("""
                Attempted to get dynamic value '\(attributeID.rawValue)' for non-existent item: \
                \(itemID.rawValue)
                """)
            return nil
        }

        // Check registry for compute handler
        if let computeHandler = dynamicAttributeRegistry.itemComputeHandler(
            for: itemID,
            attributeID: attributeID
        ) {
            do {
                return try await computeHandler(item, gameState)
            } catch {
                logError("""
                    Error computing dynamic value '\(attributeID.rawValue)' \
                    for item \(itemID.rawValue): \(error)
                    """)
                // Fall through to return stored value or nil? Or return nil on error? Let's return nil.
                return nil
            }
        } else {
            // No compute handler, return stored value
            return item.attributes[attributeID]
        }
    }
}
