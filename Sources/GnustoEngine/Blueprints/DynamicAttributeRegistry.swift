import Foundation

/// A registry to hold dynamically computed logic (getters) and validation rules (setters/validators)
/// for item and location attributes.
///
/// This registry allows game developers to define custom behavior for attributes beyond simple
/// static values stored in `Item.attributes` or `Location.attributes`. It separates the
/// behavioral aspects of attributes from their direct state storage.
///
/// ### Use Cases:
///
/// *   **Computed Attributes:** Define an attribute whose value is calculated on the fly based on
///     other game state. For example:
///     *   An item's `weight` attribute could be computed by summing its base weight and the
///       weights of all items it contains (if it's a container).
///     *   A location's `lightLevel` attribute could be computed based on whether light sources
///       within it are active and undimmed.
///     *   An NPC's `mood` attribute might change based on player actions or game events.
/// *   **Validated Attributes:** Define rules that must be met when attempting to change an
///     attribute's value. For example:
///     *   Preventing a player's `strength` attribute from exceeding a maximum value.
///     *   Ensuring a `doorState` attribute can only transition between valid states
///       (e.g., `open` to `closed`, but not directly from `locked` to `open` without unlocking).
///
/// Game developers register these custom handlers (closures) with the `DynamicAttributeRegistry`,
/// typically during game setup via the `GameBlueprint`. The `GameEngine` then automatically
/// invokes these handlers when relevant attributes are accessed or modified.
public struct DynamicAttributeRegistry: Sendable {

    // MARK: - Handler Type Aliases

    /// A closure that dynamically computes the value of an item's attribute.
    ///
    /// When the `GameEngine` needs the value of an item attribute for which a compute handler
    /// is registered, it will invoke this closure.
    ///
    /// - Parameters:
    ///   - item: The specific `Item` instance whose attribute is being computed.
    ///   - gameState: The current `GameState`, providing access to the entire game world state
    ///                for complex calculations (e.g., checking other items, player status, global flags).
    /// - Returns: The computed `StateValue` for the attribute.
    /// - Throws: An error if computation fails (though typically, computation should aim to be non-failing).
    public typealias ItemComputeHandler =
        (@Sendable (Item, GameState) async throws -> StateValue)

    /// A closure that validates a proposed new value for an item's attribute before it is set.
    ///
    /// When an attempt is made to change an item attribute for which a validation handler is registered,
    /// the `GameEngine` (or the state update mechanism) invokes this closure first.
    ///
    /// - Parameters:
    ///   - item: The specific `Item` instance whose attribute is being validated.
    ///   - newValue: The proposed new `StateValue` for the attribute.
    /// - Returns: `true` if the `newValue` is valid for the attribute on this item; `false` otherwise.
    /// - Throws: An `ActionResponse` or other error if validation fails with a specific reason
    ///           that should be communicated to the player or logged (e.g., `.prerequisiteNotMet("You can't do that.")`).
    public typealias ItemValidateHandler =
        (@Sendable (Item, StateValue) async throws -> Bool)

    /// A closure that dynamically computes the value of a location's attribute.
    ///
    /// Similar to `ItemComputeHandler`, but for `Location` attributes.
    ///
    /// - Parameters:
    ///   - location: The specific `Location` instance whose attribute is being computed.
    ///   - gameState: The current `GameState`.
    /// - Returns: The computed `StateValue` for the attribute.
    /// - Throws: An error if computation fails.
    public typealias LocationComputeHandler =
        (@Sendable (Location, GameState) async throws -> StateValue)

    /// A closure that validates a proposed new value for a location's attribute.
    ///
    /// Similar to `ItemValidateHandler`, but for `Location` attributes.
    ///
    /// - Parameters:
    ///   - location: The specific `Location` instance whose attribute is being validated.
    ///   - newValue: The proposed new `StateValue` for the attribute.
    /// - Returns: `true` if the `newValue` is valid; `false` otherwise.
    /// - Throws: An `ActionResponse` or other error if validation fails with a specific reason.
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

    /// Registers a compute handler (a dynamic getter) for a specific item attribute.
    ///
    /// When this attribute is accessed on an item, the provided `handler` closure will be
    /// executed to determine its value, instead of reading a static value from `Item.attributes`.
    /// If a handler was already registered for this `AttributeID`, it will be replaced.
    ///
    /// - Parameters:
    ///   - key: The `AttributeID` of the item attribute to register the compute handler for.
    ///   - handler: The `ItemComputeHandler` closure to execute for computing the attribute's value.
    public mutating func registerItemCompute(
        key: AttributeID,
        handler: @escaping ItemComputeHandler
    ) {
        itemComputeHandlers[key] = handler
    }

    /// Registers a validation handler for a specific item attribute.
    ///
    /// Before a change to this attribute on an item is applied, the provided `handler` closure
    /// will be executed to check if the new value is permissible. If the handler returns `false`
    /// or throws an error, the attribute change is typically prevented.
    /// If a handler was already registered for this `AttributeID`, it will be replaced.
    ///
    /// - Parameters:
    ///   - key: The `AttributeID` of the item attribute to register the validation handler for.
    ///   - handler: The `ItemValidateHandler` closure to execute for validating new values.
    public mutating func registerItemValidate(
        key: AttributeID,
        handler: @escaping ItemValidateHandler
    ) {
        itemValidateHandlers[key] = handler
    }

    // MARK: - Registration Methods (Locations)

    /// Registers a compute handler (a dynamic getter) for a specific location attribute.
    ///
    /// Similar to `registerItemCompute`, but for location attributes.
    /// If a handler was already registered for this `AttributeID`, it will be replaced.
    ///
    /// - Parameters:
    ///   - key: The `AttributeID` of the location attribute.
    ///   - handler: The `LocationComputeHandler` closure.
    public mutating func registerLocationCompute(
        key: AttributeID,
        handler: @escaping LocationComputeHandler
    ) {
        locationComputeHandlers[key] = handler
    }

    /// Registers a validation handler for a specific location attribute.
    ///
    /// Similar to `registerItemValidate`, but for location attributes.
    /// If a handler was already registered for this `AttributeID`, it will be replaced.
    ///
    /// - Parameters:
    ///   - key: The `AttributeID` of the location attribute.
    ///   - handler: The `LocationValidateHandler` closure.
    public mutating func registerLocationValidate(
        key: AttributeID,
        handler: @escaping LocationValidateHandler
    ) {
        locationValidateHandlers[key] = handler
    }

    // MARK: - Retrieval Methods (Internal Access)

    /// Retrieves the compute handler for a specific item attribute, if one exists.
    /// - Parameter key: The `AttributeID` of the attribute to look up.
    /// - Returns: The registered compute handler, or `nil` if none exists.
    func itemComputeHandler(for key: AttributeID) -> ItemComputeHandler? {
        itemComputeHandlers[key]
    }

    /// Retrieves the validate handler for a specific item attribute, if one exists.
    /// - Parameter key: The `AttributeID` of the attribute to look up.
    /// - Returns: The registered validate handler, or `nil` if none exists.
    func itemValidateHandler(for key: AttributeID) -> ItemValidateHandler? {
        itemValidateHandlers[key]
    }

    /// Retrieves the compute handler for a specific location attribute, if one exists.
    /// - Parameter key: The `AttributeID` of the attribute to look up.
    /// - Returns: The registered compute handler, or `nil` if none exists.
    func locationComputeHandler(for key: AttributeID) -> LocationComputeHandler? {
        locationComputeHandlers[key]
    }

    /// Retrieves the validate handler for a specific location attribute, if one exists.
    /// - Parameter key: The `AttributeID` of the attribute to look up.
    /// - Returns: The registered validate handler, or `nil` if none exists.
    func locationValidateHandler(for key: AttributeID) -> LocationValidateHandler? {
        locationValidateHandlers[key]
    }
}
