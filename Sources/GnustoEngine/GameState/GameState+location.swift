import Foundation

extension GameState {
    /// Retrieves a boolean attribute value for the specified location.
    ///
    /// - Parameters:
    ///   - attributeID: The identifier of the attribute to retrieve.
    ///   - locationID: The identifier of the location whose attribute to retrieve.
    /// - Returns: The boolean value of the attribute, or `nil` if the attribute is not set.
    /// - Throws: `GameStateError.locationNotFound` if the location doesn't exist, or
    ///           `GameStateError.locationAttributeTypeMismatch` if the attribute exists but is not a boolean.
    public func attribute(
        _ attributeID: LocationAttributeID,
        of locationID: LocationID
    ) throws -> Bool? {
        guard let value = try fetchStateValue(
            locationID: locationID,
            attributeID: attributeID
        ) else {
            return nil
        }
        guard case .bool(let bool) = value else {
            throw GameStateError.locationAttributeTypeMismatch(locationID, attributeID, actual: value)
        }
        return bool
    }

    /// Retrieves an integer attribute value for the specified location.
    ///
    /// - Parameters:
    ///   - attributeID: The identifier of the attribute to retrieve.
    ///   - locationID: The identifier of the location whose attribute to retrieve.
    /// - Returns: The integer value of the attribute, or `nil` if the attribute is not set.
    /// - Throws: `GameStateError.locationNotFound` if the location doesn't exist, or
    ///           `GameStateError.locationAttributeTypeMismatch` if the attribute exists but is not an integer.
    public func attribute(
        _ attributeID: LocationAttributeID,
        of locationID: LocationID
    ) throws -> Int? {
        guard let value = try fetchStateValue(
            locationID: locationID,
            attributeID: attributeID
        ) else {
            return nil
        }
        guard case .int(let integer) = value else {
            throw GameStateError.locationAttributeTypeMismatch(locationID, attributeID, actual: value)
        }
        return integer
    }

    /// Retrieves a string attribute value for the specified location.
    ///
    /// - Parameters:
    ///   - attributeID: The identifier of the attribute to retrieve.
    ///   - locationID: The identifier of the location whose attribute to retrieve.
    /// - Returns: The string value of the attribute, or `nil` if the attribute is not set.
    /// - Throws: `GameStateError.locationNotFound` if the location doesn't exist, or
    ///           `GameStateError.locationAttributeTypeMismatch` if the attribute exists but is not a string.
    public func attribute(
        _ attributeID: LocationAttributeID,
        of locationID: LocationID
    ) throws -> String? {
        guard let value = try fetchStateValue(
            locationID: locationID,
            attributeID: attributeID
        ) else {
            return nil
        }
        guard case .string(let string) = value else {
            throw GameStateError.locationAttributeTypeMismatch(locationID, attributeID, actual: value)
        }
        return string
    }

    /// Generates a description for an location using either a custom attribute or a default description.
    ///
    /// This method first attempts to retrieve a custom description from the location's attributes.
    /// If no custom description is found, it falls back to generating a default description
    /// based on the attribute type and location properties.
    ///
    /// - Parameters:
    ///   - attributeID: The identifier of the description attribute to generate.
    ///   - locationID: The identifier of the location to describe.
    /// - Returns: A trimmed description string for the location.
    /// - Throws: `GameStateError.locationNotFound` if the location doesn't exist, or
    ///           `GameStateError.locationAttributeTypeMismatch` if the attribute exists but is not a string.
    public func generateDescription(
        _ attributeID: LocationAttributeID,
        for locationID: LocationID,
    ) throws -> String {
        if let description: String = try attribute(attributeID, of: locationID) {
            description.trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            try defaultLocationDescription(
                for: locationID,
                attributeID: attributeID
            ).trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    /// Checks whether a boolean flag attribute is set to `true` on the specified location.
    ///
    /// This is a convenience method for checking boolean attributes that default to `false`
    /// when not explicitly set.
    ///
    /// - Parameters:
    ///   - attributeID: The identifier of the flag attribute to check.
    ///   - locationID: The identifier of the location to check.
    /// - Returns: `true` if the flag is explicitly set to `true`, `false` otherwise.
    /// - Throws: `GameStateError.locationNotFound` if the location doesn't exist, or
    ///           `GameStateError.locationAttributeTypeMismatch` if the attribute exists but is not a boolean.
    public func hasFlag(
        _ attributeID: LocationAttributeID,
        on locationID: LocationID
    ) throws -> Bool {
        (try attribute(attributeID, of: locationID)) == true
    }

    /// Retrieves the location with the specified identifier.
    ///
    /// - Parameter locationID: The identifier of the location to retrieve.
    /// - Returns: The location with the specified identifier.
    /// - Throws: `GameStateError.locationNotFound` if no location exists with the given identifier.
    public func location(_ locationID: LocationID) throws -> Location {
        guard let location = locations[locationID] else {
            throw GameStateError.locationNotFound(locationID)
        }
        return location
    }
}

// MARK: - Private helpers

extension GameState {
    /// Generates a default description for an location based on the attribute type and location properties.
    ///
    /// This method provides fallback descriptions when locations don't have custom descriptions
    /// for specific attribute types like `.description`, `.shortDescription`, etc.
    ///
    /// - Parameters:
    ///   - locationID: The identifier of the location to describe.
    ///   - attributeID: The type of description attribute being requested.
    /// - Returns: A default description string appropriate for the attribute type.
    /// - Throws: `GameStateError.locationNotFound` if the location doesn't exist.
    private func defaultLocationDescription(
        for locationID: LocationID,
        attributeID: LocationAttributeID
    ) throws -> String {
        let location = try location(locationID)
        return switch attributeID {
        case .description:
            "You see nothing special about \(location.name)."
        case .shortDescription:
            "The \(location.name)."
        case .firstDescription:
            "There is \(location.name) here."
        default:
            "\(location.name.capitalizedFirst) seems indescribable."
        }
    }

    /// Retrieves the raw state value for a specific attribute of an location.
    ///
    /// This is a low-level helper method that fetches attribute values without type checking.
    /// The public attribute methods use this internally and provide type safety.
    ///
    /// - Parameters:
    ///   - locationID: The identifier of the location whose attribute to retrieve.
    ///   - attributeID: The identifier of the attribute to retrieve.
    /// - Returns: The raw state value of the attribute, or `nil` if not set.
    /// - Throws: `GameStateError.locationNotFound` if the location doesn't exist.
    private func fetchStateValue(
        locationID: LocationID,
        attributeID: LocationAttributeID
    ) throws -> StateValue? {
        try location(locationID).attributes[attributeID]
    }
}
