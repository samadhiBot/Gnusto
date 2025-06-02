// MARK: - Registration Methods (Items)

extension GameEngine {
    /// Registers a dynamic computation handler for a specific item's attribute.
    ///
    /// When the engine needs the value of this attribute for the specified item, it will execute
    /// the provided `handler` closure instead of just reading a stored value.
    /// The handler receives the `Item` instance and the current `GameState`, and should
    /// return the computed `StateValue`.
    ///
    /// This approach provides better separation of concerns than attribute-centric registration,
    /// as each item can have its own specific logic without requiring large switch statements.
    ///
    /// If a compute handler already exists for this item and attribute combination, it will be overwritten.
    /// This method forwards the registration to the `dynamicAttributeRegistry`.
    ///
    /// - Parameters:
    ///   - itemID: The `ItemID` of the specific item whose attribute will be computed.
    ///   - attributeID: The `AttributeID` of the attribute whose value will be computed.
    ///   - handler: The closure that computes the attribute's value.
    public func registerItemCompute(
        itemID: ItemID,
        attributeID: AttributeID,
        handler: @escaping DynamicAttributeRegistry.ItemComputeHandler
    ) {
        dynamicAttributeRegistry.registerItemCompute(itemID: itemID, attributeID: attributeID, handler: handler)
    }

    /// Registers a validation handler for a specific item's attribute.
    ///
    /// Before the engine applies a `StateChange` to modify this attribute for the specified item,
    /// it will first execute the provided `handler` closure. The handler receives the
    /// `Item` instance and the proposed new `StateValue`. It should return `true` if the
    /// new value is valid, or `false` (or throw an error) if it's invalid.
    ///
    /// This approach provides better separation of concerns than attribute-centric registration,
    /// as each item can have its own specific validation logic.
    ///
    /// If a validation handler already exists for this item and attribute combination, it will be overwritten.
    /// This method forwards the registration to the `dynamicAttributeRegistry`.
    ///
    /// - Parameters:
    ///   - itemID: The `ItemID` of the specific item whose attribute changes will be validated.
    ///   - attributeID: The `AttributeID` of the attribute whose changes will be validated.
    ///   - handler: The closure that validates a proposed new value for the attribute.
    public func registerItemValidate(
        itemID: ItemID,
        attributeID: AttributeID,
        handler: @escaping DynamicAttributeRegistry.ItemValidateHandler
    ) {
        dynamicAttributeRegistry.registerItemValidate(itemID: itemID, attributeID: attributeID, handler: handler)
    }

    // MARK: - Registration Methods (Locations)

    /// Registers a dynamic computation handler for a specific location's attribute.
    ///
    /// When the engine needs the value of this attribute for the specified location, it will execute
    /// the provided `handler` closure instead of just reading a stored value.
    /// The handler receives the `Location` instance and the current `GameState`, and should
    /// return the computed `StateValue`.
    ///
    /// This approach provides better separation of concerns than attribute-centric registration,
    /// as each location can have its own specific logic without requiring large switch statements.
    ///
    /// If a compute handler already exists for this location and attribute combination, it will be overwritten.
    /// This method forwards the registration to the `dynamicAttributeRegistry`.
    ///
    /// - Parameters:
    ///   - locationID: The `LocationID` of the specific location whose attribute will be computed.
    ///   - attributeID: The `AttributeID` of the attribute whose value will be computed.
    ///   - handler: The closure that computes the attribute's value.
    public func registerLocationCompute(
        locationID: LocationID,
        attributeID: AttributeID,
        handler: @escaping DynamicAttributeRegistry.LocationComputeHandler
    ) {
        dynamicAttributeRegistry.registerLocationCompute(locationID: locationID, attributeID: attributeID, handler: handler)
    }

    /// Registers a validation handler for a specific location's attribute.
    ///
    /// Before the engine applies a `StateChange` to modify this attribute for the specified location,
    /// it will first execute the provided `handler` closure. The handler receives the
    /// `Location` instance and the proposed new `StateValue`. It should return `true` if the
    /// new value is valid, or `false` (or throw an error) if it's invalid.
    ///
    /// This approach provides better separation of concerns than attribute-centric registration,
    /// as each location can have its own specific validation logic.
    ///
    /// If a validation handler already exists for this location and attribute combination, it will be overwritten.
    /// This method forwards the registration to the `dynamicAttributeRegistry`.
    ///
    /// - Parameters:
    ///   - locationID: The `LocationID` of the specific location whose attribute changes will be validated.
    ///   - attributeID: The `AttributeID` of the attribute whose changes will be validated.
    ///   - handler: The closure that validates a proposed new value for the attribute.
    public func registerLocationValidate(
        locationID: LocationID,
        attributeID: AttributeID,
        handler: @escaping DynamicAttributeRegistry.LocationValidateHandler
    ) {
        dynamicAttributeRegistry.registerLocationValidate(locationID: locationID, attributeID: attributeID, handler: handler)
    }
}
