import Foundation
import GnustoEngine

/// Context passed to custom combat event handlers.
///
/// This context provides everything a custom combat system needs to handle
/// combat events, including access to the game engine, the parsed command,
/// and the appropriate combat messenger for generating combat text.
///
/// ## Example Usage
///
/// ```swift
/// let thiefCombatSystem = StandardCombatSystem(
///     versus: .thief
/// ) { event, context in
///     switch event {
///     case .playerSlain:
///         return ActionResult(
///             context.combatMsg.oneOf(
///                 "The thief, forgetting his essentially genteel upbringing, cuts your throat.",
///                 "The thief, a pragmatist, dispatches you as a threat to his livelihood."
///             )
///         )
///     default:
///         return nil  // Use default handling
///     }
/// }
/// ```
public struct CombatEventContext: Sendable {
    /// The parsed command that triggered this combat event.
    public let command: Command

    /// Reference to the game engine for state changes and queries.
    nonisolated public let engine: GameEngine

    /// The combat messenger for generating combat-specific text.
    ///
    /// This is the appropriate messenger for the current enemy, either
    /// a custom messenger configured for this specific enemy, or the
    /// default combat messenger if no custom one is configured.
    public let combatMsg: CombatMessenger

    /// Creates a new combat event context.
    ///
    /// - Parameters:
    ///   - command: The command that triggered the combat event
    ///   - engine: The game engine instance
    ///   - combatMessenger: The combat messenger for this enemy
    public init(
        _ command: Command,
        _ engine: GameEngine,
        combatMessenger: CombatMessenger
    ) {
        self.command = command
        self.engine = engine
        self.combatMsg = combatMessenger
    }

    /// Creates a combat event context from an action context and messenger.
    ///
    /// - Parameters:
    ///   - actionContext: The action context to derive from
    ///   - combatMessenger: The combat messenger for this enemy
    public init(
        from actionContext: ActionContext,
        combatMessenger: CombatMessenger
    ) {
        self.command = actionContext.command
        self.engine = actionContext.engine
        self.combatMsg = combatMessenger
    }
}

// MARK: - Convenience Accessors

extension CombatEventContext {
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

    /// Convenience accessor for the game engine's messenger.
    ///
    /// Provides access to the standard messenger for non-combat text.
    /// For combat-specific text, use `combatMsg` instead.
    public var msg: StandardMessenger {
        get async {
            await engine.messenger
        }
    }

    /// Convenience accessor for the player proxy.
    ///
    /// Provides direct access to the current player state through a PlayerProxy,
    /// which offers dynamic access to player properties like location, inventory,
    /// score, and other player-specific state that may change during gameplay.
    public var player: PlayerProxy {
        get async {
            await engine.player
        }
    }

    /// Convenience accessor for the command's verb.
    ///
    /// Returns the verb that was parsed from the player's command.
    public var verb: Verb {
        command.verb
    }
}

extension CombatEventContext: Equatable {
    public static func == (lhs: CombatEventContext, rhs: CombatEventContext) -> Bool {
        lhs.command == rhs.command
    }
}
