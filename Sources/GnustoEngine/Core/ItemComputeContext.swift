/// Context object passed to item compute functions containing the property ID, item,
/// and game state.
///
/// `ItemComputeContext` provides compute functions with structured access to the property being
/// computed, the item it belongs to, and the current game state. This eliminates the need for
/// compute functions to manually retrieve the item and provides convenient access to common
/// operations like message formatting.
///
/// Example usage:
/// ```swift
/// static let magicSwordComputer = ItemComputer { context in
///     switch context.propertyID {
///     case .description:
///         let enchantment = context.item.properties[.enchantmentLevel]?.intValue ?? 0
///         let playerLevel = try await context.gameState.value(of: .playerLevel) ?? 1
///         return .string(enchantment > playerLevel ? "Blazing sword!" : "Glowing blade")
///     default:
///         return nil
///     }
/// }
/// ```
public struct ItemComputeContext: Sendable {
    /// The property being computed.
    public let propertyID: ItemPropertyID

    /// The item whose property is being computed.
    public let item: ItemProxy

    /// Reference to the game engine for accessing computed values and messaging.
    nonisolated public let engine: GameEngine

    /// Creates a new item compute context.
    ///
    /// - Parameters:
    ///   - propertyID: The property being computed
    ///   - item: The raw item whose property is being computed
    ///   - engine: The game engine for accessing computed values and messaging
    public init(
        propertyID: ItemPropertyID,
        item: Item,
        engine: GameEngine
    ) async {
        self.propertyID = propertyID
        self.item = ItemProxy(item: item, engine: engine)
        self.engine = engine
    }
}

extension ItemComputeContext {
    /// Convenience accessor for getting an item proxy by ID.
    ///
    /// Provides direct access to any item in the game through the engine,
    /// allowing event handlers to easily reference and manipulate other items.
    ///
    /// - Parameter itemID: The unique identifier of the item to retrieve
    /// - Returns: A proxy for the specified item
    public func item(_ itemID: ItemID) async -> ItemProxy {
        await engine.item(itemID)
    }

    /// Convenience accessor for getting a location proxy by ID.
    ///
    /// Provides direct access to any location in the game through the engine,
    /// allowing event handlers to easily reference and manipulate other locations.
    ///
    /// - Parameter locationID: The unique identifier of the location to retrieve
    /// - Returns: A proxy for the specified location
    public func location(_ locationID: LocationID) async -> LocationProxy {
        await engine.location(locationID)
    }

    /// Convenience accessor for the game engine's message provider.
    ///
    /// Provides direct access to the messenger for generating localized text
    /// responses within compute functions.
    public var msg: StandardMessenger {
        engine.messenger
    }
}
