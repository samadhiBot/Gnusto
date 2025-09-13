/// Context object passed to item compute functions containing the property ID, item, and game state.
///
/// `ItemComputeContext` provides compute functions with structured access to the property being
/// computed, the item it belongs to, and the current game state. This eliminates the need for
/// compute functions to manually retrieve the item and provides convenient access to common
/// operations like message formatting.
///
/// The context uses the raw `Item` struct rather than `ItemProxy` to avoid circular dependencies
/// during property resolution.
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

    /// The raw item whose property is being computed.
    ///
    /// This is the underlying `Item` struct rather than an `ItemProxy` to avoid
    /// circular dependencies during property resolution. Use this to access
    /// static properties directly via `item.properties[propertyID]`.
    public let item: Item

    /// Reference to the game state for accessing other values.
    ///
    /// Use this to access other items, locations, global flags, or any other
    /// game state needed for computing the property value.
    nonisolated public let gameState: GameState

    /// Reference to the game engine for accessing computed values and messaging.
    nonisolated public let engine: GameEngine

    /// Convenience accessor for the game engine's message provider.
    ///
    /// Provides direct access to the messenger for generating localized text
    /// responses within compute functions.
    public var msg: StandardMessenger {
        engine.messenger
    }

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
        self.item = item
        self.gameState = await engine.gameState
        self.engine = engine
    }
}
