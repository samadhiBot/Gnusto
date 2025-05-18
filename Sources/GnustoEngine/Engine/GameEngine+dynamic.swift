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
    public func fetch(_ itemID: ItemID, _ key: AttributeID) async throws -> Bool {
        let value = await getDynamicItemValue(itemID: itemID, key: key)
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
    public func fetch(_ itemID: ItemID, _ key: AttributeID) async throws -> Int {
        let value = await getDynamicItemValue(itemID: itemID, key: key)
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
    public func fetch(_ itemID: ItemID, _ key: AttributeID) async throws -> String {
        let value = await getDynamicItemValue(itemID: itemID, key: key)
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
    public func fetch(_ locationID: LocationID, _ key: AttributeID) async throws -> String {
        let value = await getDynamicLocationValue(locationID: locationID, key: key)
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

extension GameEngine {
    /// Retrieves the current value of a potentially dynamic item property.
    /// Checks the `DynamicAttributeRegistry` for a compute handler first.
    /// If no handler exists, returns the value stored in the item's `attributes`.
    ///
    /// - Parameters:
    ///   - itemID: The unique identifier of the item.
    ///   - key: The `AttributeID` of the desired value.
    /// - Returns: The computed or stored `StateValue`, or `nil` if the item or value doesn't exist.
    private func getDynamicItemValue(itemID: ItemID, key: AttributeID) async -> StateValue? {
        guard let item = gameState.items[itemID] else {
            logger.warning("""
                💥 Attempted to get dynamic value '\(key.rawValue)' for non-existent item: \
                \(itemID.rawValue)
                """)
            return nil
        }

        // Check registry for compute handler
        if let computeHandler = dynamicAttributeRegistry.itemComputeHandler(for: key) {
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
    /// (Implementation mirrors getDynamicItemValue)
    ///
    /// - Parameters:
    ///   - locationID: The unique identifier of the location.
    ///   - key: The `AttributeID` of the desired value.
    /// - Returns: The computed or stored `StateValue`, or `nil` if the location or value doesn't exist.
    private func getDynamicLocationValue(locationID: LocationID, key: AttributeID) async -> StateValue? {
        guard let location = gameState.locations[locationID] else {
            logger.warning("""
                💥 Attempted to get dynamic value '\(key.rawValue)' \
                for non-existent location: \(locationID.rawValue)
                """)
            return nil
        }

        if let computeHandler = dynamicAttributeRegistry.locationComputeHandler(for: key) {
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

    /// Sets the value of an item property, performing validation via the `DynamicAttributeRegistry` if applicable.
    /// Creates and applies the appropriate `StateChange` if validation passes.
    ///
    /// - Parameters:
    ///   - itemID: The unique identifier of the item to modify.
    ///   - key: The `AttributeID` of the value to set.
    ///   - newValue: The new `StateValue`.
    /// - Throws: An `ActionResponse` if the item doesn't exist, validation fails, or state application fails.
    private func setDynamicItemValue(itemID: ItemID, key: AttributeID, newValue: StateValue) async throws {
        guard let item = gameState.items[itemID] else {
            throw ActionResponse.internalEngineError("Attempted to set dynamic value '\(key.rawValue)' for non-existent item: \(itemID.rawValue)")
        }

        // Check registry for validate handler
        if let validateHandler = dynamicAttributeRegistry.itemValidateHandler(for: key) {
            do {
                let isValid = try await validateHandler(item, newValue)
                if !isValid {
                    // Use a generic invalid value error, or could the handler throw a more specific one?
                    // For now, use invalidValue.
                    throw ActionResponse.invalidValue("Validation failed for dynamic item value '\(key.rawValue)' on \(itemID.rawValue): \(newValue)")
                }
            } catch {
                // If validator throws, propagate the error
                logger.error("""
                    💥 Error validating dynamic value '\(key.rawValue)' \
                    for item \(itemID.rawValue): \(error)
                    """)
                throw error
            }
        }

        // Validation passed (or no validator), proceed with StateChange
        let oldValue = item.attributes[key]

        // Only apply if value is actually changing
        if oldValue != newValue {
            try gameState.apply(
                StateChange(
                    entityID: .item(itemID),
                    attributeKey: .itemAttribute(key),
                    oldValue: oldValue,
                    newValue: newValue
                )
            )
        }
    }

    /// Sets the value of a location property, performing validation.
    /// (Implementation mirrors setDynamicItemValue)
    ///
    /// - Parameters:
    ///   - locationID: The unique identifier of the location to modify.
    ///   - key: The `AttributeID` of the value to set.
    ///   - newValue: The new `StateValue`.
    /// - Throws: An `ActionResponse` if the location doesn't exist, validation fails, or state application fails.
    private func setDynamicLocationValue(locationID: LocationID, key: AttributeID, newValue: StateValue) async throws {
        guard let location = gameState.locations[locationID] else {
            throw ActionResponse.internalEngineError("Attempted to set dynamic value '\(key.rawValue)' for non-existent location: \(locationID.rawValue)")
        }

        if let validateHandler = dynamicAttributeRegistry.locationValidateHandler(for: key) {
            do {
                let isValid = try await validateHandler(location, newValue)
                if !isValid {
                    throw ActionResponse.invalidValue("Validation failed for dynamic location value '\(key.rawValue)' on \(locationID.rawValue): \(newValue)")
                }
            } catch {
                logger.error("""
                    💥 Error validating dynamic value '\(key.rawValue)' \
                    for location \(locationID.rawValue): \(error)
                    """)
                throw error
            }
        }

        let oldValue = location.attributes[key]

        if oldValue != newValue {
            try gameState.apply(
                StateChange(
                    entityID: .location(locationID),
                    attributeKey: .locationAttribute(key), // Use the new key
                    oldValue: oldValue,
                    newValue: newValue
                )
            )
        }
    }
}
