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
    public func hasPreposition(_ prepositions: Preposition...) -> Bool {
        if let preposition = command.preposition {
            prepositions.contains(preposition)
        } else {
            false
        }
    }

    /// Convenience accessor for the game engine's messenger.
    ///
    /// Provides direct access to the messenger for generating localized text responses
    /// and error messages within action handlers.
    public var msg: StandardMessenger {
        engine.messenger
    }

    /// Convenience accessor for combat messaging.
    ///
    /// Provides access to the appropriate combat messenger for the current combat context.
    /// Falls back to the default combat messenger if no enemy-specific messenger is configured.
    public var combatMsg: CombatMessenger {
        get async {
            if let combatState = await engine.combatState {
                return await engine.combatMessenger(for: combatState.enemyID)
            }
            return engine.defaultCombatMessenger
        }
    }

    public var player: PlayerProxy {
        get async {
            await engine.player
        }
    }

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
        universalMessage: ((UniversalObject) async throws -> String)? = nil,
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
    ///   - locationMessage: Custom error message when indirect object is a location.
    ///   - universalMessage: Custom error message when indirect object is universal.
    ///   - playerMessage: Custom error message when indirect object is the player.
    ///   - failureMessage: Fallback error message used when specific type messages are not provided.
    /// - Returns: An ItemProxy for the indirect object item, or nil if no indirect object exists.
    /// - Throws: ActionResponse.prerequisiteNotMet if indirect object is not an item.
    /// - Throws: ActionResponse.itemNotAccessible if the item cannot be reached by the player.
    public func itemIndirectObject(
        requiresLight: Bool = true,
        locationMessage: ((LocationProxy) async throws -> String)? = nil,
        universalMessage: ((UniversalObject) async throws -> String)? = nil,
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
