import Foundation

/// A registry to hold dynamically computed logic and validation rules for properties.
///
/// This registry separates the behavioral aspects of properties (computation, validation)
/// from their state storage (which resides in `Item.attributes` or `Location.attributes`).
public struct DynamicAttributeRegistry: Sendable {

    // MARK: - Handler Type Aliases

    /// Closure type for computing an item property's value.
    /// Takes the specific Item instance and the current GameState.
    public typealias ItemComputeHandler =
        (@MainActor @Sendable (Item, GameState) async throws -> StateValue)

    /// Closure type for validating a new value for an item property.
    /// Takes the specific Item instance and the proposed new StateValue.
    /// Returns `true` if the value is valid, `false` otherwise.
    public typealias ItemValidateHandler =
        (@MainActor @Sendable (Item, StateValue) async throws -> Bool)

    /// Closure type for computing a location property's value.
    public typealias LocationComputeHandler =
        (@MainActor @Sendable (Location, GameState) async throws -> StateValue)

    /// Closure type for validating a new value for a location property.
    public typealias LocationValidateHandler =
        (@MainActor @Sendable (Location, StateValue) async throws -> Bool)

    // MARK: - Private Storage

    /// Storage for item compute handlers, keyed by AttributeID.
    private var itemComputeHandlers: [AttributeID: ItemComputeHandler] = [:]
    /// Storage for item validate handlers.
    private var itemValidateHandlers: [AttributeID: ItemValidateHandler] = [:]
    /// Storage for location compute handlers.
    private var locationComputeHandlers: [AttributeID: LocationComputeHandler] = [:]
    /// Storage for location validate handlers.
    private var locationValidateHandlers: [AttributeID: LocationValidateHandler] = [:]

    // MARK: - Initialization

    public init() { }

    // MARK: - Registration Methods (Items)

    /// Registers a compute handler for a specific item property.
    /// If a handler already exists for this key, it will be overwritten.
    /// - Parameters:
    ///   - key: The `AttributeID` of the property.
    ///   - handler: The closure to execute for computing the value.
    public mutating func registerItemCompute(
        key: AttributeID,
        handler: @escaping ItemComputeHandler
    ) {
        itemComputeHandlers[key] = handler
    }

    /// Registers a validation handler for a specific item property.
    /// If a handler already exists for this key, it will be overwritten.
    /// - Parameters:
    ///   - key: The `AttributeID` of the property.
    ///   - handler: The closure to execute for validating a new value.
    public mutating func registerItemValidate(
        key: AttributeID,
        handler: @escaping ItemValidateHandler
    ) {
        itemValidateHandlers[key] = handler
    }

    // MARK: - Registration Methods (Locations)

    /// Registers a compute handler for a specific location property.
    public mutating func registerLocationCompute(
        key: AttributeID,
        handler: @escaping LocationComputeHandler
    ) {
        locationComputeHandlers[key] = handler
    }

    /// Registers a validation handler for a specific location property.
    public mutating func registerLocationValidate(
        key: AttributeID,
        handler: @escaping LocationValidateHandler
    ) {
        locationValidateHandlers[key] = handler
    }

    // MARK: - Retrieval Methods (Internal Access)

    /// Retrieves the compute handler for a specific item property, if one exists.
    internal func itemComputeHandler(for key: AttributeID) -> ItemComputeHandler? {
        itemComputeHandlers[key]
    }

    /// Retrieves the validate handler for a specific item property, if one exists.
    internal func itemValidateHandler(for key: AttributeID) -> ItemValidateHandler? {
        itemValidateHandlers[key]
    }

    /// Retrieves the compute handler for a specific location property, if one exists.
    internal func locationComputeHandler(for key: AttributeID) -> LocationComputeHandler? {
        locationComputeHandlers[key]
    }

    /// Retrieves the validate handler for a specific location property, if one exists.
    internal func locationValidateHandler(for key: AttributeID) -> LocationValidateHandler? {
        locationValidateHandlers[key]
    }
}
