import Foundation

// MARK: - Item Descriptions

extension GameEngine {
    /// Fetches the boolean value of a dynamic or static attribute for a given item.
    ///
    /// This is used for item flags and properties that are represented as boolean values.
    /// Dynamic computation handlers are checked first before static properties.
    ///
    /// - Parameters:
    ///   - attributeID: The `AttributeID` of the boolean attribute.
    ///   - itemID: The `ItemID` of the item.
    /// - Returns: The boolean value of the attribute, or `nil` if the attribute doesn't exist.
    /// - Throws: `ActionResponse.invalidValue` if the attribute exists but is not a boolean,
    ///           or if the item does not exist.
    public func attribute(
        _ attributeID: AttributeID,
        of itemID: ItemID
    ) async throws -> Bool? {
        let result = await fetchStateValue(
            itemID: itemID,
            attributeID: attributeID
        )
        let value = result.value

        guard let value else {
            return nil
        }

        switch value {
        case .bool(let boolValue):
            return boolValue
        default:
            throw ActionResponse.invalidValue("""
                Cannot fetch boolean value for \(itemID.rawValue).\(attributeID.rawValue): \
                expected boolean but got \(value)
                """)
        }
    }

    /// Fetches the integer value of a dynamic or static attribute for a given item.
    ///
    /// This method is similar to the boolean fetch but for numeric attributes. It checks
    /// for dynamic computation handlers first before static properties.
    ///
    /// - Parameters:
    ///   - attributeID: The `AttributeID` of the integer attribute.
    ///   - itemID: The `ItemID` of the item.
    /// - Returns: The integer value of the attribute, or `nil` if the attribute doesn't exist.
    /// - Throws: `ActionResponse.invalidValue` if the attribute exists but is not an integer,
    ///           or if the item does not exist.
    public func attribute(
        _ attributeID: AttributeID,
        of itemID: ItemID
    ) async throws -> Int? {
        let result = await fetchStateValue(
            itemID: itemID,
            attributeID: attributeID
        )
        let value = result.value

        guard let value else {
            return nil
        }

        switch value {
        case .int(let intValue):
            return intValue
        default:
            throw ActionResponse.invalidValue("""
                Cannot fetch integer value for \(itemID.rawValue).\(attributeID.rawValue): \
                expected integer but got \(value)
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
    /// - Returns: The string value of the attribute, or `nil` if the attribute doesn't exist.
    /// - Throws: `ActionResponse.invalidValue` if the attribute exists but is not a string,
    ///           or if the item does not exist.
    public func attribute(
        _ attributeID: AttributeID,
        of itemID: ItemID
    ) async throws -> String? {
        let result = await fetchStateValue(
            itemID: itemID,
            attributeID: attributeID
        )
        let value = result.value

        guard let value else {
            return nil
        }

        switch value {
        case .string(let stringValue):
            return stringValue
        default:
            throw ActionResponse.invalidValue("""
                Cannot fetch string value for \(itemID.rawValue).\(attributeID.rawValue): \
                expected string but got \(value)
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
        attributeID: AttributeID
    ) async throws -> String {
        if let description: String = try? await attribute(attributeID, of: itemID) {
            description.trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            try await defaultItemDescription(
                for: itemID,
                attributeID: attributeID
            ).trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    /// Generates a formatted description string for a specific item attribute and indicates
    /// whether a compute handler provided the description.
    ///
    /// This is similar to `generateDescription` but also returns whether a compute handler
    /// provided the description. This allows callers to determine if additional processing
    /// should be applied (e.g., adding container state information) or if the compute handler
    /// provided a complete, final description.
    ///
    /// - Parameters:
    ///   - itemID: The `ItemID` of the item for which to generate a description.
    ///   - attributeID: The `AttributeID` indicating the type of description requested.
    ///   - engine: The `GameEngine` instance, used for fetching dynamic values.
    /// - Returns: A tuple containing the formatted description string and a boolean indicating
    ///            whether a compute handler provided the description.
    public func generateDescriptionWithComputeInfo(
        for itemID: ItemID,
        attributeID: AttributeID
    ) async throws -> (description: String, wasComputed: Bool) {
        let result = await fetchStateValue(itemID: itemID, attributeID: attributeID)

        if let value = result.value, case .string(let stringValue) = value {
            return (
                stringValue.trimmingCharacters(in: .whitespacesAndNewlines),
                result.wasComputed
            )
        } else {
            return (
                try await defaultItemDescription(
                    for: itemID,
                    attributeID: attributeID
                ).trimmingCharacters(in: .whitespacesAndNewlines),
                false
            )
        }
    }

    /// Generates a formatted description string for a specific item attribute with full
    /// source information including whether it's a default fallback.
    ///
    /// This method provides complete information about the source of a description:
    /// - Whether it came from a compute handler
    /// - Whether it's a default fallback (generic message)
    /// This allows callers to make intelligent decisions about whether to skip or modify
    /// generic descriptions in favor of more contextual information.
    ///
    /// - Parameters:
    ///   - itemID: The `ItemID` of the item for which to generate a description.
    ///   - attributeID: The `AttributeID` indicating the type of description requested.
    /// - Returns: A tuple containing:
    ///   - `description`: The formatted description string
    ///   - `wasComputed`: Whether a compute handler provided the description
    ///   - `isDefault`: Whether this is a generic fallback description
    public func generateDescriptionWithSourceInfo(
        for itemID: ItemID,
        attributeID: AttributeID
    ) async throws -> (description: String, wasComputed: Bool, isDefault: Bool) {
        let result = await fetchStateValue(itemID: itemID, attributeID: attributeID)

        if let value = result.value, case .string(let stringValue) = value {
            return (
                stringValue.trimmingCharacters(in: .whitespacesAndNewlines),
                result.wasComputed,
                false
            )
        } else {
            return (
                try await defaultItemDescription(
                    for: itemID,
                    attributeID: attributeID
                ).trimmingCharacters(in: .whitespacesAndNewlines),
                false,
                true
            )
        }
    }

    /// Checks if a boolean flag is set to true for a given item.
    ///
    /// This is a convenience method that treats `nil` values as `false`, making it ideal
    /// for checking boolean flags where the absence of the attribute means the flag is not set.
    ///
    /// - Parameters:
    ///   - attributeID: The `AttributeID` of the boolean attribute to check.
    ///   - itemID: The `ItemID` of the item.
    /// - Returns: `true` if the attribute exists and is `true`, `false` otherwise (including when `nil`).
    /// - Throws: `ActionResponse.invalidValue` if the attribute exists but is not a boolean.
    public func hasFlag(_ attributeID: AttributeID, on itemID: ItemID) async throws -> Bool {
        (try await attribute(attributeID, of: itemID)) == true
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
    /// Validates a proposed value for an item attribute.
    /// Since validation handlers have been removed, this always returns true.
    /// This method is kept for compatibility during the transition.
    ///
    /// - Parameters:
    ///   - attributeID: The `AttributeID` of the attribute being validated.
    ///   - itemID: The unique identifier of the item.
    ///   - newValue: The proposed new `StateValue`.
    /// - Returns: Always `true` since validation handlers are not implemented yet.
    func validateStateValue(
        itemID: ItemID,
        attributeID: AttributeID,
        newValue: StateValue
    ) async throws -> Bool {
        // Validation handlers removed for now, always allow changes
        true
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
        attributeID: AttributeID
    ) async throws -> String {
        let item = try item(itemID)
        return switch attributeID {
        case .description:
            "You see nothing special about \(item.withDefiniteArticle)."
        case .shortDescription:
            "\(item.withIndefiniteArticle.capitalizedFirst)."
        case .firstDescription:
            "There is \(item.withIndefiniteArticle) here."
        case .readText:
            "There is nothing written on \(item.withDefiniteArticle)."
        case .readWhileHeldText:
            "Holding \(item.withDefiniteArticle) reveals nothing special."
        default:
            "\(item.withDefiniteArticle.capitalizedFirst) seems indescribable."
        }
    }

    /// Retrieves the current value of a potentially dynamic item property.
    /// Checks for a compute handler first, then returns the stored value if no handler exists.
    ///
    /// - Parameters:
    ///   - attributeID: The `AttributeID` of the desired value.
    ///   - itemID: The unique identifier of the item.
    /// - Returns: A tuple containing the computed or stored `StateValue` (or `nil` if not found)
    ///           and a boolean indicating whether a compute handler provided the value.
    private func fetchStateValue(
        itemID: ItemID,
        attributeID: AttributeID
    ) async -> (value: StateValue?, wasComputed: Bool) {
        guard let item = gameState.items[itemID] else {
            logWarning("""
                Attempted to get dynamic value '\(attributeID.rawValue)' for non-existent item: \
                \(itemID.rawValue)
                """)
            return (nil, false)
        }

        // Try compute handler first
        if let computer = itemComputers[itemID] {
            do {
                if let computedValue = try await computer.compute(attributeID, gameState) {
                    return (computedValue, true)
                }
                // Computer returned nil, fall through to stored value
            } catch {
                logError("Error computing dynamic value '\(attributeID.rawValue)' for item \(itemID.rawValue): \(error)")
                // Fall through to stored value on error
            }
        }

        // No compute handler or handler failed, return stored value
        return (item.attributes[attributeID], false)
    }
}
