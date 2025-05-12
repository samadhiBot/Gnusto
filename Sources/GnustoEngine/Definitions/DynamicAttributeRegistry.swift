import Foundation

/// A registry to hold dynamically computed logic and validation rules for properties.
///
/// This registry separates the behavioral aspects of properties (computation, validation)
/// from their state storage (which resides in `Item.attributes` or `Location.attributes`).
/// It provides a centralized way to manage dynamic property behavior across the game engine.
public struct DynamicAttributeRegistry: Sendable {

    // MARK: - Handler Type Aliases

    /// Closure type for computing an item property's value.
    /// Takes the specific Item instance and the current GameState.
    /// Returns a `StateValue` representing the computed property value.
    public typealias ItemComputeHandler =
        (@Sendable (Item, GameState) async throws -> StateValue)

    /// Closure type for validating a new value for an item property.
    /// Takes the specific Item instance and the proposed new StateValue.
    /// Returns `true` if the value is valid, `false` otherwise.
    /// Throws an error if validation fails with a specific reason.
    public typealias ItemValidateHandler =
        (@Sendable (Item, StateValue) async throws -> Bool)

    /// Closure type for computing a location property's value.
    /// Takes the specific Location instance and the current GameState.
    /// Returns a `StateValue` representing the computed property value.
    public typealias LocationComputeHandler =
        (@Sendable (Location, GameState) async throws -> StateValue)

    /// Closure type for validating a new value for a location property.
    /// Takes the specific Location instance and the proposed new StateValue.
    /// Returns `true` if the value is valid, `false` otherwise.
    /// Throws an error if validation fails with a specific reason.
    public typealias LocationValidateHandler =
        (@Sendable (Location, StateValue) async throws -> Bool)

    // MARK: - Private Storage

    /// Storage for item compute handlers, keyed by AttributeID.
    /// These handlers are responsible for dynamically computing property values for items.
    private var itemComputeHandlers: [AttributeID: ItemComputeHandler] = [:]

    /// Storage for item validate handlers.
    /// These handlers are responsible for validating new values for item properties.
    private var itemValidateHandlers: [AttributeID: ItemValidateHandler] = [:]

    /// Storage for location compute handlers.
    /// These handlers are responsible for dynamically computing property values for locations.
    private var locationComputeHandlers: [AttributeID: LocationComputeHandler] = [:]

    /// Storage for location validate handlers.
    /// These handlers are responsible for validating new values for location properties.
    private var locationValidateHandlers: [AttributeID: LocationValidateHandler] = [:]

    // MARK: - Initialization

    /// Creates a new empty DynamicAttributeRegistry.
    public init() {}

    // MARK: - Registration Methods (Items)

    /// Registers a compute handler for a specific item property.
    ///
    /// If a handler already exists for this key, it will be overwritten.
    /// - Parameters:
    ///   - key: The `AttributeID` of the property to register the handler for.
    ///   - handler: The closure to execute for computing the property's value.
    public mutating func registerItemCompute(
        key: AttributeID,
        handler: @escaping ItemComputeHandler
    ) {
        itemComputeHandlers[key] = handler
    }

    /// Registers a validation handler for a specific item property.
    ///
    /// If a handler already exists for this key, it will be overwritten.
    /// - Parameters:
    ///   - key: The `AttributeID` of the property to register the handler for.
    ///   - handler: The closure to execute for validating new values for the property.
    public mutating func registerItemValidate(
        key: AttributeID,
        handler: @escaping ItemValidateHandler
    ) {
        itemValidateHandlers[key] = handler
    }

    // MARK: - Registration Methods (Locations)

    /// Registers a compute handler for a specific location property.
    ///
    /// If a handler already exists for this key, it will be overwritten.
    /// - Parameters:
    ///   - key: The `AttributeID` of the property to register the handler for.
    ///   - handler: The closure to execute for computing the property's value.
    public mutating func registerLocationCompute(
        key: AttributeID,
        handler: @escaping LocationComputeHandler
    ) {
        locationComputeHandlers[key] = handler
    }

    /// Registers a validation handler for a specific location property.
    ///
    /// If a handler already exists for this key, it will be overwritten.
    /// - Parameters:
    ///   - key: The `AttributeID` of the property to register the handler for.
    ///   - handler: The closure to execute for validating new values for the property.
    public mutating func registerLocationValidate(
        key: AttributeID,
        handler: @escaping LocationValidateHandler
    ) {
        locationValidateHandlers[key] = handler
    }

    // MARK: - Retrieval Methods (Internal Access)

    /// Retrieves the compute handler for a specific item property, if one exists.
    /// - Parameter key: The `AttributeID` of the property to look up.
    /// - Returns: The registered compute handler, or `nil` if none exists.
    func itemComputeHandler(for key: AttributeID) -> ItemComputeHandler? {
        itemComputeHandlers[key]
    }

    /// Retrieves the validate handler for a specific item property, if one exists.
    /// - Parameter key: The `AttributeID` of the property to look up.
    /// - Returns: The registered validate handler, or `nil` if none exists.
    func itemValidateHandler(for key: AttributeID) -> ItemValidateHandler? {
        itemValidateHandlers[key]
    }

    /// Retrieves the compute handler for a specific location property, if one exists.
    /// - Parameter key: The `AttributeID` of the property to look up.
    /// - Returns: The registered compute handler, or `nil` if none exists.
    func locationComputeHandler(for key: AttributeID) -> LocationComputeHandler? {
        locationComputeHandlers[key]
    }

    /// Retrieves the validate handler for a specific location property, if one exists.
    /// - Parameter key: The `AttributeID` of the property to look up.
    /// - Returns: The registered validate handler, or `nil` if none exists.
    func locationValidateHandler(for key: AttributeID) -> LocationValidateHandler? {
        locationValidateHandlers[key]
    }
}
