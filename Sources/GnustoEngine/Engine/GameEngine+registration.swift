// MARK: - Registration Methods (Items)

extension GameEngine {
    /// Registers a compute handler for a specific item property.
    /// If a handler already exists for this key, it will be overwritten.
    /// - Parameters:
    ///   - key: The `AttributeID` of the property.
    ///   - handler: The closure to execute for computing the value.
    public func registerItemCompute(
        key: AttributeID,
        handler: @escaping DynamicAttributeRegistry.ItemComputeHandler
    ) {
        dynamicAttributeRegistry.registerItemCompute(key: key, handler: handler)
    }

    /// Registers a validation handler for a specific item property.
    /// If a handler already exists for this key, it will be overwritten.
    /// - Parameters:
    ///   - key: The `AttributeID` of the property.
    ///   - handler: The closure to execute for validating a new value.
    public func registerItemValidate(
        key: AttributeID,
        handler: @escaping DynamicAttributeRegistry.ItemValidateHandler
    ) {
        dynamicAttributeRegistry.registerItemValidate(key: key, handler: handler)
    }

    // MARK: - Registration Methods (Locations)

    /// Registers a compute handler for a specific location property.
    public func registerLocationCompute(
        key: AttributeID,
        handler: @escaping DynamicAttributeRegistry.LocationComputeHandler
    ) {
        dynamicAttributeRegistry.registerLocationCompute(key: key, handler: handler)
    }

    /// Registers a validation handler for a specific location property.
    public func registerLocationValidate(
        key: AttributeID,
        handler: @escaping DynamicAttributeRegistry.LocationValidateHandler
    ) {
        dynamicAttributeRegistry.registerLocationValidate(key: key, handler: handler)
    }
}
