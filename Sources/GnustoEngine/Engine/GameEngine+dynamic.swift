import Foundation

// MARK: - Dynamic Attribute Accessors

extension GameEngine {
    /// Fetches the boolean value of a dynamic or static attribute for a given item.
    ///
    /// This method first checks if a dynamic computation handler is registered for the
    /// specified `AttributeID` in the `dynamicAttributeRegistry`. If so, it executes
    /// the handler to get the value. Otherwise, it retrieves the statically stored value
    /// from the item's attributes.
    ///
    /// - Parameters:
    ///   - itemID: The `ItemID` of the item whose attribute is to be fetched.
    ///   - key: The `AttributeID` of the boolean attribute.
    /// - Returns: The boolean value of the attribute.
    /// - Throws: `ActionResponse.invalidValue` if the attribute exists but is not a boolean,
    ///           or if the item does not exist. Returns `false` if the attribute is not set.
    public func fetch(
        _ itemID: ItemID,
        _ key: AttributeID
    ) async throws -> Bool {
        let value = await fetchStateValue(
            itemID: itemID,
            key: key
        )
        switch value {
        case .bool(let boolValue):
            return boolValue
        case nil:
            return false
        default:
            throw ActionResponse.invalidValue("""
                Cannot fetch boolean value for \(itemID.rawValue).\(key.rawValue): \
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
    ///   - itemID: The `ItemID` of the item.
    ///   - key: The `AttributeID` of the integer attribute.
    /// - Returns: The integer value of the attribute.
    /// - Throws: `ActionResponse.invalidValue` if the attribute is not an integer, does not exist,
    ///           or the item does not exist.
    public func fetch(
        _ itemID: ItemID,
        _ key: AttributeID
    ) async throws -> Int {
        let value = await fetchStateValue(
            itemID: itemID,
            key: key
        )
        switch value {
        case .int(let intValue):
            return intValue
        default:
            throw ActionResponse.invalidValue("""
                Cannot fetch integer value for \(itemID.rawValue).\(key.rawValue): \
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
    ///   - itemID: The `ItemID` of the item.
    ///   - key: The `AttributeID` of the string attribute (e.g., `.description`).
    /// - Returns: The string value of the attribute.
    /// - Throws: `ActionResponse.invalidValue` if the attribute is not a string, does not exist,
    ///           or the item does not exist.
    public func fetch(
        _ itemID: ItemID,
        _ key: AttributeID
    ) async throws -> String {
        let value = await fetchStateValue(
            itemID: itemID,
            key: key
        )
        switch value {
        case .string(let stringValue):
            return stringValue
        default:
            throw ActionResponse.invalidValue("""
                Cannot fetch string value for \(itemID.rawValue).\(key.rawValue): \
                \(value ?? .undefined)
                """)
        }
    }

    /// Fetches the string value of a dynamic or static attribute for a given location.
    ///
    /// Works like the item-specific `fetch` for strings, but targets a location attribute.
    /// Useful for dynamic location descriptions.
    ///
    /// - Parameters:
    ///   - locationID: The `LocationID` of the location.
    ///   - key: The `AttributeID` of the string attribute.
    /// - Returns: The string value of the attribute.
    /// - Throws: `ActionResponse.invalidValue` if the attribute is not a string, does not exist,
    ///           or the location does not exist.
    public func fetch(
        _ locationID: LocationID,
        _ key: AttributeID
    ) async throws -> String {
        let value = await fetchStateValue(
            locationID: locationID,
            key: key
        )
        switch value {
        case .string(let stringValue):
            return stringValue
        default:
            throw ActionResponse.invalidValue("""
                Cannot fetch string value for \(locationID.rawValue).\(key.rawValue): \
                \(value ?? .undefined)
                """)
        }
    }
}

// MARK: - Dynamic Attribute Validation (Internal)

extension GameEngine {
    /// Validates a proposed value for an item attribute using the dynamic attribute registry.
    /// This is called internally when `StateChange`s are applied to ensure dynamic validation
    /// handlers are respected.
    ///
    /// - Parameters:
    ///   - itemID: The unique identifier of the item.
    ///   - key: The `AttributeID` of the attribute being validated.
    ///   - newValue: The proposed new `StateValue`.
    /// - Returns: `true` if the value is valid or no validator is registered; `false` if validation fails.
    /// - Throws: Errors from the validation handler if it throws instead of returning `false`.
    func validateStateValue(
        itemID: ItemID,
        key: AttributeID,
        newValue: StateValue
    ) async throws -> Bool {
        guard let item = gameState.items[itemID] else {
            return false // Item doesn't exist
        }

        if let validateHandler = dynamicAttributeRegistry.itemValidateHandler(for: itemID, attributeKey: key) {
            return try await validateHandler(item, newValue)
        } else {
            return true // No validator registered, allow the change
        }
    }

    /// Validates a proposed value for a location attribute using the dynamic attribute registry.
    /// This is called internally when `StateChange`s are applied to ensure dynamic validation
    /// handlers are respected.
    ///
    /// - Parameters:
    ///   - locationID: The unique identifier of the location.
    ///   - key: The `AttributeID` of the attribute being validated.
    ///   - newValue: The proposed new `StateValue`.
    /// - Returns: `true` if the value is valid or no validator is registered; `false` if validation fails.
    /// - Throws: Errors from the validation handler if it throws instead of returning `false`.
    func validateStateValue(
        locationID: LocationID,
        key: AttributeID,
        newValue: StateValue
    ) async throws -> Bool {
        guard let location = gameState.locations[locationID] else {
            return false // Location doesn't exist
        }

        if let validateHandler = dynamicAttributeRegistry.locationValidateHandler(for: locationID, attributeKey: key) {
            return try await validateHandler(location, newValue)
        } else {
            return true // No validator registered, allow the change
        }
    }
}

// MARK: - Private Dynamic Attribute Helpers

extension GameEngine {
    /// Retrieves the current value of a potentially dynamic item property.
    /// Checks the `DynamicAttributeRegistry` for a compute handler first.
    /// If no handler exists, returns the value stored in the item's `attributes`.
    ///
    /// - Parameters:
    ///   - itemID: The unique identifier of the item.
    ///   - key: The `AttributeID` of the desired value.
    /// - Returns: The computed or stored `StateValue`, or `nil` if the item or value doesn't exist.
    private func fetchStateValue(
        itemID: ItemID,
        key: AttributeID
    ) async -> StateValue? {
        guard let item = gameState.items[itemID] else {
            logger.warning("""
                💥 Attempted to get dynamic value '\(key.rawValue)' for non-existent item: \
                \(itemID.rawValue)
                """)
            return nil
        }

        // Check registry for compute handler
        if let computeHandler = dynamicAttributeRegistry.itemComputeHandler(for: itemID, attributeKey: key) {
            do {
                return try await computeHandler(item, gameState)
            } catch {
                logger.error("""
                    💥 Error computing dynamic value '\(key.rawValue)' \
                    for item \(itemID.rawValue): \(error)
                    """)
                // Fall through to return stored value or nil? Or return nil on error? Let's return nil.
                return nil
            }
        } else {
            // No compute handler, return stored value
            return item.attributes[key]
        }
    }

    /// Retrieves the current value of a potentially dynamic location property.
    /// (Implementation mirrors fetchStateValue)
    ///
    /// - Parameters:
    ///   - locationID: The unique identifier of the location.
    ///   - key: The `AttributeID` of the desired value.
    /// - Returns: The computed or stored `StateValue`, or `nil` if the location or value doesn't exist.
    private func fetchStateValue(
        locationID: LocationID,
        key: AttributeID
    ) async -> StateValue? {
        guard let location = gameState.locations[locationID] else {
            logger.warning("""
                💥 Attempted to get dynamic value '\(key.rawValue)' \
                for non-existent location: \(locationID.rawValue)
                """)
            return nil
        }

        if let computeHandler = dynamicAttributeRegistry.locationComputeHandler(
            for: locationID,
            attributeKey: key
        ) {
            do {
                return try await computeHandler(location, gameState)
            } catch {
                logger.error("""
                    💥 Error computing dynamic value '\(key.rawValue)' \
                    for location \(locationID.rawValue): \(error)
                    """)
                return nil
            }
        } else {
            return location.attributes[key]
        }
    }
}
