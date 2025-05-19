// MARK: - Registration Methods (Items)

extension GameEngine {
    /// Registers a dynamic computation handler for a specific item attribute.
    ///
    /// When the engine needs the value of this attribute for an item, it will execute
    /// the provided `handler` closure instead of just reading a stored value.
    /// The handler receives the `Item` instance and the current `GameState`, and should
    /// return the computed `StateValue`.
    ///
    /// If a compute handler already exists for this `AttributeID`, it will be overwritten.
    /// This method forwards the registration to the `dynamicAttributeRegistry`.
    ///
    /// - Parameters:
    ///   - key: The `AttributeID` of the attribute whose value will be computed.
    ///   - handler: The closure that computes the attribute's value.
    public func registerItemCompute(
        key: AttributeID,
        handler: @escaping DynamicAttributeRegistry.ItemComputeHandler
    ) {
        dynamicAttributeRegistry.registerItemCompute(key: key, handler: handler)
    }

    /// Registers a validation handler for a specific item attribute.
    ///
    /// Before the engine applies a `StateChange` to modify this attribute for an item,
    /// it will first execute the provided `handler` closure. The handler receives the
    /// `Item` instance and the proposed new `StateValue`. It should return `true` if the
    /// new value is valid, or `false` (or throw an error) if it's invalid.
    ///
    /// If a validation handler already exists for this `AttributeID`, it will be overwritten.
    /// This method forwards the registration to the `dynamicAttributeRegistry`.
    ///
    /// - Parameters:
    ///   - key: The `AttributeID` of the attribute whose changes will be validated.
    ///   - handler: The closure that validates a proposed new value for the attribute.
    public func registerItemValidate(
        key: AttributeID,
        handler: @escaping DynamicAttributeRegistry.ItemValidateHandler
    ) {
        dynamicAttributeRegistry.registerItemValidate(key: key, handler: handler)
    }

    // MARK: - Registration Methods (Locations)

    /// Registers a dynamic computation handler for a specific location attribute.
    ///
    /// Similar to `registerItemCompute`, but for location attributes. When the engine needs
    /// the value of this attribute for a location, it will execute the provided `handler`.
    ///
    /// If a compute handler already exists, it's overwritten.
    /// Forwards to `dynamicAttributeRegistry`.
    ///
    /// - Parameters:
    ///   - key: The `AttributeID` of the location attribute.
    ///   - handler: The closure to compute the attribute's value.
    public func registerLocationCompute(
        key: AttributeID,
        handler: @escaping DynamicAttributeRegistry.LocationComputeHandler
    ) {
        dynamicAttributeRegistry.registerLocationCompute(key: key, handler: handler)
    }

    /// Registers a validation handler for a specific location attribute.
    ///
    /// Similar to `registerItemValidate`, but for location attributes. Before the engine
    /// applies a `StateChange` to this attribute for a location, it executes the `handler`.
    ///
    /// If a validation handler already exists, it's overwritten.
    /// Forwards to `dynamicAttributeRegistry`.
    ///
    /// - Parameters:
    ///   - key: The `AttributeID` of the location attribute.
    ///   - handler: The closure to validate a new value.
    public func registerLocationValidate(
        key: AttributeID,
        handler: @escaping DynamicAttributeRegistry.LocationValidateHandler
    ) {
        dynamicAttributeRegistry.registerLocationValidate(key: key, handler: handler)
    }
}
