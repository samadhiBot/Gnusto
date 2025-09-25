import Foundation

/// Context object passed to action handlers containing the parsed command and game engine reference.
///
/// ActionContext provides action handlers with access to both the parsed command structure
/// and the game engine for performing state changes and queries. The engine reference is
/// marked as `nonisolated` to allow concurrent access from action handlers.
public struct ActionContext: Sendable {
    /// The parsed command containing direct and indirect object references.
    public let command: Command

    /// Reference to the game engine for state changes and queries.
    ///
    /// Marked as `nonisolated` to support concurrent access from action handlers
    /// while maintaining thread safety through the engine's internal synchronization.
    nonisolated public let engine: GameEngine

    /// Creates a new action context with the given command and engine reference.
    ///
    /// - Parameters:
    ///   - command: The parsed command to be processed
    ///   - engine: The game engine instance for state operations
    public init(
        _ command: Command,
        _ engine: GameEngine
    ) {
        self.command = command
        self.engine = engine
    }
}

extension ActionContext {
    /// Convenience accessor for combat messaging.
    ///
    /// Provides access to the appropriate combat messenger for the current combat context.
    /// This automatically selects the correct combat messenger based on the current enemy,
    /// allowing for character-specific combat descriptions and responses. Falls back to the
    /// default combat messenger if no enemy-specific messenger is configured or if not
    /// currently in combat.
    ///
    /// Example:
    /// ```swift
    /// let hitMessage = await context.combatMsg.attackHit(damage: 5)
    /// let missMessage = await context.combatMsg.attackMiss()
    /// ```
    public var combatMsg: CombatMessenger {
        get async {
            if let combatState = await engine.combatState {
                return await engine.combatMessenger(for: combatState.enemyID)
            }
            return engine.defaultCombatMessenger
        }
    }

    /// Checks if the command contains one of the specified prepositions.
    ///
    /// This method is commonly used in action handlers to branch logic based on
    /// the preposition used in the command. For example, "put book on table" vs
    /// "put book in drawer" would use different prepositions (.on vs .in).
    ///
    /// - Parameter prepositions: One or more prepositions to check for
    /// - Returns: `true` if the command's preposition matches any of the provided prepositions
    ///
    /// Example:
    /// ```swift
    /// if context.hasPreposition(.on, .onto) {
    ///     // Handle "put X on Y" or "put X onto Y"
    /// } else if context.hasPreposition(.in, .into) {
    ///     // Handle "put X in Y" or "put X into Y"
    /// }
    /// ```
    public func hasPreposition(_ prepositions: Preposition...) -> Bool {
        if let preposition = command.preposition {
            prepositions.contains(preposition)
        } else {
            false
        }
    }

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
    /// Provides direct access to the messenger for generating localized text responses
    /// and error messages within action handlers. This is the primary way action handlers
    /// should generate player-facing text to ensure proper localization and consistency.
    ///
    /// Example:
    /// ```swift
    /// return ActionResult(context.msg.cannotDoThat())
    /// return ActionResult(context.msg.itemNotInScope(noun))
    /// ```
    public var msg: StandardMessenger {
        engine.messenger
    }

    /// Convenience accessor for the player proxy.
    ///
    /// Provides direct access to the current player state through a PlayerProxy,
    /// which offers dynamic access to player properties like location, inventory,
    /// score, and other player-specific state that may change during gameplay.
    ///
    /// Example:
    /// ```swift
    /// let currentLocation = await context.player.location
    /// let inventory = await context.player.inventory
    /// let score = await context.player.score
    /// ```
    public var player: PlayerProxy {
        get async {
            await engine.player
        }
    }

    /// Convenience accessor for the command's verb.
    ///
    /// Returns the verb that was parsed from the player's command. This is useful
    /// for action handlers that handle multiple verbs or need to modify their
    /// behavior based on the specific verb used.
    ///
    /// Example:
    /// ```swift
    /// switch context.verb {
    /// case .take:
    ///     // Handle taking
    /// case .drop:
    ///     // Handle dropping
    /// default:
    ///     // Handle other verbs
    /// }
    /// ```
    public var verb: Verb {
        command.verb
    }
}

extension ActionContext {
    /// Validates and returns the direct object as an item proxy.
    ///
    /// This method ensures the command has a direct object that is an item and that
    /// the player can reach it. Provides customizable error messages for different
    /// types of invalid direct objects.
    ///
    /// - Parameters:
    ///   - requiresLight: Whether the action requires light to identify the item (defaults to true).
    ///   - locationMessage: Custom error message when direct object is a location.
    ///   - universalMessage: Custom error message when direct object is universal.
    ///   - playerMessage: Custom error message when direct object is the player.
    ///   - failureMessage: Fallback error message used when specific type messages are not provided.
    /// - Returns: An ItemProxy for the direct object item, or nil if no direct object exists.
    /// - Throws: ActionResponse.prerequisiteNotMet if direct object is not an item.
    /// - Throws: ActionResponse.itemNotAccessible if the item cannot be reached by the player.
    public func itemDirectObject(
        requiresLight: Bool = true,
        locationMessage: ((LocationProxy) async throws -> String)? = nil,
        universalMessage: ((Universal) async throws -> String)? = nil,
        playerMessage: String? = nil,
        failureMessage: String? = nil
    ) async throws -> ItemProxy? {
        guard let directObjectRef = command.directObject else { return nil }

        guard command.directObjects.count == 1, !command.isAllCommand else {
            throw ActionResponse.multipleObjectsNotSupported(self)
        }

        switch directObjectRef {
        case .item(let itemProxy):
            let reachableItems = await engine.itemsReachableByPlayer(
                requiresLight: requiresLight
            )
            guard reachableItems.contains(itemProxy) else {
                throw ActionResponse.itemNotAccessible(itemProxy)
            }
            return itemProxy

        case .location(let locationProxy):
            if let locationMessage {
                throw try await ActionResponse.feedback(
                    locationMessage(locationProxy)
                )
            }
            if let failureMessage {
                throw ActionResponse.feedback(failureMessage)
            }
            throw ActionResponse.cannotDoThat(self)

        case .universal(let universalObject):
            if let universalMessage {
                throw try await ActionResponse.feedback(
                    universalMessage(universalObject)
                )
            }
            if let failureMessage {
                throw ActionResponse.feedback(failureMessage)
            }
            throw ActionResponse.cannotDoThat(self)

        case .player:
            if let playerMessage {
                throw ActionResponse.feedback(playerMessage)
            }
            if let failureMessage {
                throw ActionResponse.feedback(failureMessage)
            }
            throw ActionResponse.cannotDoYourself(self)
        }
    }

    /// Validates and returns all direct objects as item proxies.
    ///
    /// This method processes commands that may have multiple direct objects (such as
    /// "take all" or "take book and lamp"). It validates that each direct object is
    /// an item that the player can reach, filtering out inaccessible items for bulk
    /// commands while throwing errors for specific item commands.
    ///
    /// For "all" commands, items with the `.omitDescription` flag are automatically
    /// excluded from the results, as these are typically scenery or background items
    /// that shouldn't be included in bulk operations.
    ///
    /// - Parameter requiresLight: Whether the action requires light to see the objects
    /// - Returns: Array of ItemProxy objects for all valid direct object items
    /// - Throws: ActionResponse.cannotDoThat if any direct object is not an item (for specific commands)
    /// - Throws: ActionResponse.itemNotAccessible if any item cannot be reached (for specific commands)
    ///
    /// Example:
    /// ```swift
    /// let items = try await context.itemDirectObjects()
    /// for item in items {
    ///     // Process each item
    /// }
    /// ```
    public func itemDirectObjects(requiresLight: Bool = true) async throws -> [ItemProxy] {
        var items = [ItemProxy]()

        for directObjectRef in command.directObjects {
            do {
                guard case .item(let item) = directObjectRef else {
                    throw ActionResponse.cannotDoThat(self)
                }

                let reachableItems = await engine.itemsReachableByPlayer(
                    requiresLight: requiresLight
                )
                guard reachableItems.contains(item) else {
                    throw ActionResponse.itemNotAccessible(item)
                }

                let shouldOmitFromAllCommands = await item.hasFlag(.omitDescription)
                if command.isAllCommand && shouldOmitFromAllCommands {
                    continue
                }

                items.append(item)

            } catch {
                if !command.isAllCommand {
                    throw error
                }
            }
        }

        return items
    }

    /// Validates and returns the indirect object as an item proxy.
    ///
    /// This method ensures the command has an indirect object that is an item and that
    /// the player can reach it. Provides customizable error messages for different
    /// types of invalid indirect objects.
    ///
    /// - Parameters:
    ///   - requiresLight: Whether the action requires light to identify the item (defaults to true).
    ///   - locationMessage: Custom error message when direct object is a location.
    ///   - universalMessage: Custom error message when direct object is universal.
    ///   - playerMessage: Custom error message when direct object is the player.
    ///   - failureMessage: Fallback error message used when specific type messages are not provided.
    /// - Returns: An ItemProxy for the indirect object item, or nil if no indirect object exists.
    /// - Throws: ActionResponse.prerequisiteNotMet if indirect object is not an item.
    /// - Throws: ActionResponse.itemNotAccessible if the item cannot be reached by the player.
    public func itemIndirectObject(
        requiresLight: Bool = true,
        locationMessage: ((LocationProxy) async throws -> String)? = nil,
        universalMessage: ((Universal) async throws -> String)? = nil,
        playerMessage: String? = nil,
        failureMessage: String? = nil
    ) async throws -> ItemProxy? {
        guard let indirectObjectRef = command.indirectObject else { return nil }

        switch indirectObjectRef {
        case .item(let itemProxy):
            let reachableItems = await engine.itemsReachableByPlayer(
                requiresLight: requiresLight
            )
            guard reachableItems.contains(itemProxy) else {
                throw ActionResponse.itemNotAccessible(itemProxy)
            }
            return itemProxy

        case .location(let locationProxy):
            if let locationMessage {
                throw try await ActionResponse.feedback(
                    locationMessage(locationProxy)
                )
            }
            if let failureMessage {
                throw ActionResponse.feedback(failureMessage)
            }
            throw ActionResponse.cannotDoThat(self)

        case .universal(let universalObject):
            if let universalMessage {
                throw try await ActionResponse.feedback(
                    universalMessage(universalObject)
                )
            }
            if let failureMessage {
                throw ActionResponse.feedback(failureMessage)
            }
            throw ActionResponse.cannotDoThat(self)

        case .player:
            if let playerMessage {
                throw ActionResponse.feedback(playerMessage)
            }
            if let failureMessage {
                throw ActionResponse.feedback(failureMessage)
            }
            throw ActionResponse.cannotDoThat(self)
        }
    }
}

extension ActionContext: Equatable {
    public static func == (lhs: ActionContext, rhs: ActionContext) -> Bool {
        lhs.command == rhs.command
    }
}
