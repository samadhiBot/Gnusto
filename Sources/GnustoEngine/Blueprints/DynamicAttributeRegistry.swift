import Foundation

/// A registry to hold dynamically computed logic (getters) and validation rules (setters/validators)
/// for item and location attributes.
///
/// This registry allows game developers to define custom behavior for specific items and locations
/// beyond simple static values stored in `Item.attributes` or `Location.attributes`. It separates
/// the behavioral aspects of attributes from their direct state storage.
///
/// ### Use Cases:
///
/// *   **Computed Attributes:** Define attributes whose values are calculated on the fly based on
///     other game state. For example:
///     *   A magic sword's `description` that changes based on its enchantment level.
///     *   A weather vane's `direction` that reflects current wind conditions.
///     *   An NPC's `mood` attribute that changes based on player actions or game events.
/// *   **Validated Attributes:** Define rules that must be met when attempting to change an
///     attribute's value. For example:
///     *   Preventing a player's `strength` attribute from exceeding a maximum value.
///     *   Ensuring a `doorState` attribute can only transition between valid states.
///
/// Game developers register these custom handlers (closures) with the `DynamicAttributeRegistry`,
/// typically during game setup via the `GameBlueprint`. The `GameEngine` then automatically
/// invokes these handlers when relevant attributes are accessed or modified.
///
/// ### Registration Pattern:
///
/// Instead of registering by attribute type (which leads to large switch statements), this registry
/// uses **item-specific** and **location-specific** registration for better separation of concerns:
///
/// ```swift
/// // Register dynamic description for a specific magic sword
/// registry.registerItemCompute(itemID: "magicSword", attributeID: "description") { item, gameState in
///     let enchantmentLevel = item.attributes["enchantmentLevel"]?.toInt ?? 0
///     return .string("A \(enchantmentLevel > 5 ? "brilliantly glowing" : "faintly shimmering") sword.")
/// }
///
/// // Register dynamic mood for a specific NPC
/// registry.registerItemCompute(itemID: "villageElder", attributeID: "mood") { item, gameState in
///     let playerReputation = gameState.globalState["playerReputation"]?.toInt ?? 0
///     return .string(playerReputation > 50 ? "friendly" : "suspicious")
/// }
/// ```
public struct DynamicAttributeRegistry: Sendable {

    // MARK: - Handler Type Aliases

    /// A closure that dynamically computes the value of a specific item's attribute.
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

    /// A closure that validates a proposed new value for a specific item's attribute before it is set.
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

    /// A closure that dynamically computes the value of a specific location's attribute.
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

    /// A closure that validates a proposed new value for a specific location's attribute.
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

    /// Storage for item compute handlers, keyed by (ItemID, AttributeID).
    /// This allows each item to have its own specific handlers for different attributes.
    private var itemComputeHandlers: [ItemID: [AttributeID: ItemComputeHandler]] = [:]

    /// Storage for item validate handlers, keyed by (ItemID, AttributeID).
    /// This allows each item to have its own specific validation rules for different attributes.
    private var itemValidateHandlers: [ItemID: [AttributeID: ItemValidateHandler]] = [:]

    /// Storage for location compute handlers, keyed by (LocationID, AttributeID).
    /// This allows each location to have its own specific handlers for different attributes.
    private var locationComputeHandlers: [LocationID: [AttributeID: LocationComputeHandler]] = [:]

    /// Storage for location validate handlers, keyed by (LocationID, AttributeID).
    /// This allows each location to have its own specific validation rules for different attributes.
    private var locationValidateHandlers: [LocationID: [AttributeID: LocationValidateHandler]] = [:]

    // MARK: - Initialization

    /// Creates a new empty DynamicAttributeRegistry.
    public init() {}

    // MARK: - Registration Methods (Items)

    /// Registers a compute handler (a dynamic getter) for a specific item's attribute.
    ///
    /// When this attribute is accessed on the specified item, the provided `handler` closure will be
    /// executed to determine its value, instead of reading a static value from `Item.attributes`.
    /// If a handler was already registered for this item and attribute combination, it will be replaced.
    ///
    /// - Parameters:
    ///   - itemID: The `ItemID` of the specific item to register the compute handler for.
    ///   - attributeID: The `AttributeID` of the attribute to register the compute handler for.
    ///   - handler: The `ItemComputeHandler` closure to execute for computing the attribute's value.
    public mutating func registerItemCompute(
        itemID: ItemID,
        attributeID: AttributeID,
        handler: @escaping ItemComputeHandler
    ) {
        if itemComputeHandlers[itemID] == nil {
            itemComputeHandlers[itemID] = [:]
        }
        itemComputeHandlers[itemID]![attributeID] = handler
    }

    /// Registers a validation handler for a specific item's attribute.
    ///
    /// Before a change to this attribute on the specified item is applied, the provided `handler` closure
    /// will be executed to check if the new value is permissible. If the handler returns `false`
    /// or throws an error, the attribute change is typically prevented.
    /// If a handler was already registered for this item and attribute combination, it will be replaced.
    ///
    /// - Parameters:
    ///   - itemID: The `ItemID` of the specific item to register the validation handler for.
    ///   - attributeID: The `AttributeID` of the attribute to register the validation handler for.
    ///   - handler: The `ItemValidateHandler` closure to execute for validating new values.
    public mutating func registerItemValidate(
        itemID: ItemID,
        attributeID: AttributeID,
        handler: @escaping ItemValidateHandler
    ) {
        if itemValidateHandlers[itemID] == nil {
            itemValidateHandlers[itemID] = [:]
        }
        itemValidateHandlers[itemID]![attributeID] = handler
    }

    // MARK: - Registration Methods (Locations)

    /// Registers a compute handler (a dynamic getter) for a specific location's attribute.
    ///
    /// When this attribute is accessed on the specified location, the provided `handler` closure will be
    /// executed to determine its value, instead of reading a static value from `Location.attributes`.
    /// If a handler was already registered for this location and attribute combination, it will be replaced.
    ///
    /// - Parameters:
    ///   - locationID: The `LocationID` of the specific location to register the compute handler for.
    ///   - attributeID: The `AttributeID` of the attribute to register the compute handler for.
    ///   - handler: The `LocationComputeHandler` closure to execute for computing the attribute's value.
    public mutating func registerLocationCompute(
        locationID: LocationID,
        attributeID: AttributeID,
        handler: @escaping LocationComputeHandler
    ) {
        if locationComputeHandlers[locationID] == nil {
            locationComputeHandlers[locationID] = [:]
        }
        locationComputeHandlers[locationID]![attributeID] = handler
    }

    /// Registers a validation handler for a specific location's attribute.
    ///
    /// Before a change to this attribute on the specified location is applied, the provided `handler` closure
    /// will be executed to check if the new value is permissible. If the handler returns `false`
    /// or throws an error, the attribute change is typically prevented.
    /// If a handler was already registered for this location and attribute combination, it will be replaced.
    ///
    /// - Parameters:
    ///   - locationID: The `LocationID` of the specific location to register the validation handler for.
    ///   - attributeID: The `AttributeID` of the attribute to register the validation handler for.
    ///   - handler: The `LocationValidateHandler` closure to execute for validating new values.
    public mutating func registerLocationValidate(
        locationID: LocationID,
        attributeID: AttributeID,
        handler: @escaping LocationValidateHandler
    ) {
        if locationValidateHandlers[locationID] == nil {
            locationValidateHandlers[locationID] = [:]
        }
        locationValidateHandlers[locationID]![attributeID] = handler
    }

    // MARK: - Retrieval Methods (Internal Access)

    /// Retrieves the compute handler for a specific item's attribute, if one exists.
    /// - Parameters:
    ///   - itemID: The `ItemID` of the item to look up.
    ///   - attributeID: The `AttributeID` of the attribute to look up.
    /// - Returns: The registered compute handler, or `nil` if none exists.
    func itemComputeHandler(for itemID: ItemID, attributeID: AttributeID) -> ItemComputeHandler? {
        itemComputeHandlers[itemID]?[attributeID]
    }

    /// Retrieves the validate handler for a specific item's attribute, if one exists.
    /// - Parameters:
    ///   - itemID: The `ItemID` of the item to look up.
    ///   - attributeID: The `AttributeID` of the attribute to look up.
    /// - Returns: The registered validate handler, or `nil` if none exists.
    func itemValidateHandler(for itemID: ItemID, attributeID: AttributeID) -> ItemValidateHandler? {
        itemValidateHandlers[itemID]?[attributeID]
    }

    /// Retrieves the compute handler for a specific location's attribute, if one exists.
    /// - Parameters:
    ///   - locationID: The `LocationID` of the location to look up.
    ///   - attributeID: The `AttributeID` of the attribute to look up.
    /// - Returns: The registered compute handler, or `nil` if none exists.
    func locationComputeHandler(for locationID: LocationID, attributeID: AttributeID) -> LocationComputeHandler? {
        locationComputeHandlers[locationID]?[attributeID]
    }

    /// Retrieves the validate handler for a specific location's attribute, if one exists.
    /// - Parameters:
    ///   - locationID: The `LocationID` of the location to look up.
    ///   - attributeID: The `AttributeID` of the attribute to look up.
    /// - Returns: The registered validate handler, or `nil` if none exists.
    func locationValidateHandler(for locationID: LocationID, attributeID: AttributeID) -> LocationValidateHandler? {
        locationValidateHandlers[locationID]?[attributeID]
    }
}
