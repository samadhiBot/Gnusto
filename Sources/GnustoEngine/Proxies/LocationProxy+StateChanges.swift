import Foundation

// MARK: - Location StateChange factories

extension LocationProxy {
    /// Builds a `StateChange` to clear a boolean property (flag) on a location, effectively
    /// setting its value to `false`.
    ///
    /// If the flag is not currently set to `true` on the location (i.e., it's already `false`
    /// or not set), this method returns `nil` as no change is needed.
    ///
    /// - Parameters:
    ///   - propertyID: The `LocationPropertyID` of the flag to clear.
    /// - Returns: A `StateChange` to set the flag to `false`, or `nil` if the flag is not currently
    ///            `true`.
    public func clearFlag(_ propertyID: LocationPropertyID) async throws -> StateChange? {
        if try await property(propertyID)?.toBool == true {
            try await setProperty(propertyID, to: false)
        } else {
            nil
        }
    }

    /// Creates a `StateChange` to set a dynamic property on a location.
    ///
    /// This method creates a `StateChange` that respects the action pipeline and will trigger
    /// dynamic validation handlers when applied. It only creates a change if the new value
    /// differs from the current value.
    ///
    /// - Parameters:
    ///   - propertyID: The `PropertyID` of the property to set.
    ///   - stateValue: The new `StateValue` for the property.
    /// - Returns: A `StateChange` to set the property, or `nil` if the value wouldn't change.
    public func setProperty(
        _ propertyID: LocationPropertyID,
        to stateValue: StateValue
    ) async throws -> StateChange? {
        let currentValue = try await property(propertyID)
        guard currentValue != stateValue else { return nil }

        return StateChange.setLocationProperty(id: id, property: propertyID, value: stateValue)
    }

    /// Builds a `StateChange` to set a boolean property (flag) on a location to `true`.
    ///
    /// If the flag is already set to `true` on the location, this method returns `nil`
    /// as no change is needed.
    ///
    /// - Parameters:
    ///   - propertyID: The `LocationPropertyID` of the flag to set.
    /// - Returns: A `StateChange` to set the flag to `true`, or `nil` if the flag is already
    ///            `true`.
    public func setFlag(_ propertyID: LocationPropertyID) async throws -> StateChange? {
        if try await property(propertyID)?.toBool == true {
            nil
        } else {
            try await setProperty(propertyID, to: true)
        }
    }
}

// MARK: - Convenience builders for common dynamic properties

extension LocationProxy {
    /// Creates a `StateChange` to set a location's description.
    ///
    /// This is a convenience method for the common pattern of dynamically changing
    /// location descriptions based on game state, similar to ZIL's `PUTP` operations.
    ///
    /// - Parameters:
    ///   - description: The new description text.
    /// - Returns: A `StateChange` to set the description, or `nil` if it wouldn't change.
    public func setDescription(to description: String) async throws -> StateChange? {
        try await setProperty(.description, to: .string(description))
    }

    /// Creates a `StateChange` to set a boolean flag property on a location.
    ///
    /// This is a convenience method for the common pattern of setting boolean flags on locations,
    /// similar to ZIL's `FSET` and `FCLEAR` operations, but for dynamic properties.
    ///
    /// - Parameters:
    ///   - flag: The name of the flag property to set.
    ///   - value: The boolean value to set (`true` to set the flag, `false` to clear it).
    /// - Returns: A `StateChange` to set the flag, or `nil` if it wouldn't change.
    public func setProperty(
        _ flag: LocationPropertyID,
        to value: Bool
    ) async throws -> StateChange? {
        try await setProperty(flag, to: .bool(value))
    }

    /// Creates a `StateChange` to set an integer property on a location.
    ///
    /// This is a convenience method for setting numeric properties on locations.
    ///
    /// - Parameters:
    ///   - propertyID: The `PropertyID` of the property to set.
    ///   - value: The integer value to set.
    /// - Returns: A `StateChange` to set the property, or `nil` if it wouldn't change.
    public func setProperty(
        _ propertyID: LocationPropertyID,
        to value: Int
    ) async throws -> StateChange? {
        try await setProperty(propertyID, to: .int(value))
    }

    /// Creates a `StateChange` to set a string property on a location.
    ///
    /// This is a convenience method for setting string properties on locations.
    ///
    /// - Parameters:
    ///   - propertyID: The `PropertyID` of the property to set.
    ///   - value: The string value to set.
    /// - Returns: A `StateChange` to set the property, or `nil` if it wouldn't change.
    public func setProperty(
        _ propertyID: LocationPropertyID,
        to value: String
    ) async throws -> StateChange? {
        try await setProperty(propertyID, to: .string(value))
    }
}
