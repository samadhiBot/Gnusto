import Foundation

extension GameState {
    /// Retrieves a boolean attribute value for the specified item.
    ///
    /// - Parameters:
    ///   - attributeID: The identifier of the attribute to retrieve.
    ///   - itemID: The identifier of the item whose attribute to retrieve.
    /// - Returns: The boolean value of the attribute, or `nil` if the attribute is not set.
    /// - Throws: `GameStateError.itemNotFound` if the item doesn't exist, or
    ///           `GameStateError.itemAttributeTypeMismatch` if the attribute exists but is not a boolean.
    public func attribute(
        _ attributeID: AttributeID,
        of itemID: ItemID
    ) throws -> Bool? {
        guard let value = try fetchStateValue(
            itemID: itemID,
            attributeID: attributeID
        ) else {
            return nil
        }
        guard case .bool(let bool) = value else {
            throw GameStateError.itemAttributeTypeMismatch(itemID, attributeID, actual: value)
        }
        return bool
    }

    /// Retrieves an integer attribute value for the specified item.
    ///
    /// - Parameters:
    ///   - attributeID: The identifier of the attribute to retrieve.
    ///   - itemID: The identifier of the item whose attribute to retrieve.
    /// - Returns: The integer value of the attribute, or `nil` if the attribute is not set.
    /// - Throws: `GameStateError.itemNotFound` if the item doesn't exist, or
    ///           `GameStateError.itemAttributeTypeMismatch` if the attribute exists but is not an integer.
    public func attribute(
        _ attributeID: AttributeID,
        of itemID: ItemID
    ) throws -> Int? {
        guard let value = try fetchStateValue(
            itemID: itemID,
            attributeID: attributeID
        ) else {
            return nil
        }
        guard case .int(let integer) = value else {
            throw GameStateError.itemAttributeTypeMismatch(itemID, attributeID, actual: value)
        }
        return integer
    }

    /// Retrieves a string attribute value for the specified item.
    ///
    /// - Parameters:
    ///   - attributeID: The identifier of the attribute to retrieve.
    ///   - itemID: The identifier of the item whose attribute to retrieve.
    /// - Returns: The string value of the attribute, or `nil` if the attribute is not set.
    /// - Throws: `GameStateError.itemNotFound` if the item doesn't exist, or
    ///           `GameStateError.itemAttributeTypeMismatch` if the attribute exists but is not a string.
    public func attribute(
        _ attributeID: AttributeID,
        of itemID: ItemID
    ) throws -> String? {
        guard let value = try fetchStateValue(
            itemID: itemID,
            attributeID: attributeID
        ) else {
            return nil
        }
        guard case .string(let string) = value else {
            throw GameStateError.itemAttributeTypeMismatch(itemID, attributeID, actual: value)
        }
        return string
    }

    /// Generates a description for an item using either a custom attribute or a default description.
    ///
    /// This method first attempts to retrieve a custom description from the item's attributes.
    /// If no custom description is found, it falls back to generating a default description
    /// based on the attribute type and item properties.
    ///
    /// - Parameters:
    ///   - attributeID: The identifier of the description attribute to generate.
    ///   - itemID: The identifier of the item to describe.
    /// - Returns: A trimmed description string for the item.
    /// - Throws: `GameStateError.itemNotFound` if the item doesn't exist, or
    ///           `GameStateError.itemAttributeTypeMismatch` if the attribute exists but is not a string.
    public func generateDescription(
        _ attributeID: AttributeID,
        for itemID: ItemID,
    ) throws -> String {
        if let description: String = try attribute(attributeID, of: itemID) {
            description.trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            try defaultItemDescription(
                for: itemID,
                attributeID: attributeID
            ).trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    /// Checks whether a boolean flag attribute is set to `true` on the specified item.
    ///
    /// This is a convenience method for checking boolean attributes that default to `false`
    /// when not explicitly set.
    ///
    /// - Parameters:
    ///   - attributeID: The identifier of the flag attribute to check.
    ///   - itemID: The identifier of the item to check.
    /// - Returns: `true` if the flag is explicitly set to `true`, `false` otherwise.
    /// - Throws: `GameStateError.itemNotFound` if the item doesn't exist, or
    ///           `GameStateError.itemAttributeTypeMismatch` if the attribute exists but is not a boolean.
    public func hasFlag(
        _ attributeID: AttributeID,
        on itemID: ItemID
    ) throws -> Bool {
        (try attribute(attributeID, of: itemID)) == true
    }

    /// Retrieves the item with the specified identifier.
    ///
    /// - Parameter itemID: The identifier of the item to retrieve.
    /// - Returns: The item with the specified identifier.
    /// - Throws: `GameStateError.itemNotFound` if no item exists with the given identifier.
    public func item(_ itemID: ItemID) throws -> Item {
        guard let item = items[itemID] else {
            throw GameStateError.itemNotFound(itemID)
        }
        return item
    }

    /// Retrieves all items that are currently contained within the specified parent entity.
    ///
    /// - Parameter parent: The parent entity (location, item, or player) to search within.
    /// - Returns: An array of items that have the specified parent entity as their container.
    public func items(in parent: ParentEntity) -> [Item] {
        items.values.filter { $0.parent == parent }
    }
}

// MARK: - Private helpers

extension GameState {
    /// Generates a default description for an item based on the attribute type and item properties.
    ///
    /// This method provides fallback descriptions when items don't have custom descriptions
    /// for specific attribute types like `.description`, `.shortDescription`, etc.
    ///
    /// - Parameters:
    ///   - itemID: The identifier of the item to describe.
    ///   - attributeID: The type of description attribute being requested.
    /// - Returns: A default description string appropriate for the attribute type.
    /// - Throws: `GameStateError.itemNotFound` if the item doesn't exist.
    private func defaultItemDescription(
        for itemID: ItemID,
        attributeID: AttributeID
    ) throws -> String {
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

    /// Retrieves the raw state value for a specific attribute of an item.
    ///
    /// This is a low-level helper method that fetches attribute values without type checking.
    /// The public attribute methods use this internally and provide type safety.
    ///
    /// - Parameters:
    ///   - itemID: The identifier of the item whose attribute to retrieve.
    ///   - attributeID: The identifier of the attribute to retrieve.
    /// - Returns: The raw state value of the attribute, or `nil` if not set.
    /// - Throws: `GameStateError.itemNotFound` if the item doesn't exist.
    private func fetchStateValue(
        itemID: ItemID,
        attributeID: AttributeID
    ) throws -> StateValue? {
        try item(itemID).attributes[attributeID]
    }
}
