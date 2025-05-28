/// Enumerates standard reasons why a game action might fail or be disallowed.
///
/// `ActionHandler`s (especially their `validate` and `process` methods) throw `ActionResponse`
/// instances to indicate specific failure conditions. The `GameEngine` then typically
/// translates these into appropriate messages for the player.
public enum ActionResponse: Error, Equatable, Sendable {
    /// Action failed because the target container (e.g., a box, chest) is closed.
    /// The associated `ItemID` is for the container.
    case containerIsClosed(ItemID)

    /// Action failed because the target container is already open (e.g., trying to open an
    /// item that is not closable but is considered "open" by default, or trying to close an item
    /// that is already open and cannot be closed).
    /// The associated `ItemID` is for the container.
    case containerIsOpen(ItemID)

    /// A custom message string provided directly by a handler. This can be used when
    /// none of the other predefined `ActionResponse` cases fit the situation, allowing
    /// for flexible, action-specific feedback.
    case custom(String)

    /// Movement in a specified direction failed because the way is blocked.
    /// The optional `String` can provide a specific reason (e.g., "The door is locked.").
    case directionIsBlocked(String?)

    /// An unexpected internal error occurred within the game engine or an action handler.
    /// The `String` provides details about the error, primarily for debugging.
    case internalEngineError(String)

    /// The direction specified in a movement command was invalid (e.g., "go sideways")
    /// or does not exist as an exit from the current location.
    case invalidDirection

    /// The indirect object specified in the command is unsuitable for the action or missing.
    /// The `String` might contain the name of the object if it was identified but deemed invalid.
    case invalidIndirectObject(String?)

    /// A value intended for a state change or property update was invalid.
    /// This might occur if a dynamic attribute validation handler rejected a new value.
    /// The `String` provides details, often for debugging.
    case invalidValue(String)

    /// Action failed because the target item (e.g., a door, a box) is already closed.
    /// The associated `ItemID` is for the item.
    case itemAlreadyClosed(ItemID)

    /// Action failed because the target item is already open.
    /// The associated `ItemID` is for the item.
    case itemAlreadyOpen(ItemID)

    /// Action failed because the player attempted to wear an item they are already wearing.
    /// The associated `ItemID` is for the item.
    case itemIsAlreadyWorn(ItemID)

    /// Action failed because the target item (e.g., a door, a chest) is locked.
    /// The associated `ItemID` is for the locked item.
    case itemIsLocked(ItemID)

    /// Action failed because the player attempted to remove (doff) an item they are not currently wearing.
    /// The associated `ItemID` is for the item.
    case itemIsNotWorn(ItemID)

    /// Action failed because the target item is already unlocked.
    /// The associated `ItemID` is for the item.
    case itemIsUnlocked(ItemID)

    /// Action failed because the target item, though it may exist, is not currently reachable
    /// or perceivable by the player (e.g., it's in another room, in a closed container, or in darkness).
    /// The associated `ItemID` is for the inaccessible item.
    case itemNotAccessible(ItemID)

    /// Action failed because the target item cannot be closed (e.g., it's not a container or door).
    /// The associated `ItemID` is for the item.
    case itemNotClosable(ItemID)

    /// Action failed because the target item cannot be dropped (e.g., it is fixed in place or cursed).
    /// The associated `ItemID` is for the item.
    case itemNotDroppable(ItemID)

    /// Action failed because the target item is not edible.
    /// The associated `ItemID` is for the item.
    case itemNotEdible(ItemID)

    /// Action failed because the player is not currently holding the required item in their inventory.
    /// The associated `ItemID` is for the item that is not being held.
    case itemNotHeld(ItemID)

    /// Action failed because a specified item is not inside the specified container.
    /// Useful for commands like "take X from Y" or "remove X from Y".
    case itemNotInContainer(item: ItemID, container: ItemID)

    /// Action failed because the target item cannot be locked (e.g., it has no lock mechanism).
    /// The associated `ItemID` is for the item.
    case itemNotLockable(ItemID)

    /// Action failed because a specified item is not on the specified surface.
    /// Useful for commands like "take X off Y".
    case itemNotOnSurface(item: ItemID, surface: ItemID)

    /// Action failed because the target item cannot be opened (e.g., it's not a container or door).
    /// The associated `ItemID` is for the item.
    case itemNotOpenable(ItemID)

    /// Action failed because the target item has nothing written on it or is not readable.
    /// The associated `ItemID` is for the item.
    case itemNotReadable(ItemID)

    /// Action failed because the target item cannot be removed (e.g., a cursed piece of clothing).
    /// The associated `ItemID` is for the item.
    case itemNotRemovable(ItemID)

    /// Action failed because the target item cannot be taken (e.g., it's too heavy, fixed, or not ownable).
    /// The associated `ItemID` is for the item.
    case itemNotTakable(ItemID)

    /// Action failed because the target item cannot be unlocked (e.g., it has no lock, or requires a specific key type).
    /// The associated `ItemID` is for the item.
    case itemNotUnlockable(ItemID)

    /// Action failed because the item cannot be worn (e.g., it's not clothing).
    /// The associated `ItemID` is for the item.
    case itemNotWearable(ItemID)

    /// Action failed because the specified item is too large to fit into the specified container.
    case itemTooLargeForContainer(item: ItemID, container: ItemID)

    /// Action failed because the player's inventory is full and cannot accommodate more items or weight.
    case playerCannotCarryMore

    /// A generic failure indicating that some prerequisite for the action was not met.
    /// The associated `String` should provide a player-facing message explaining the reason.
    case prerequisiteNotMet(String)

    /// Action failed because the current location is dark, and the action requires light to perform.
    case roomIsDark

    /// Action failed during `GameState.apply` because a `StateChange`'s `oldValue` did not match
    /// the actual current value in the game state. This indicates a consistency issue, often
    /// due to a race condition or an incorrect assumption in the handler logic.
    case stateValidationFailed(change: StateChange, actualOldValue: StateValue?)

    /// Action failed because the target item is not a container (e.g., trying to put something into an apple).
    /// The associated `ItemID` is for the non-container item.
    case targetIsNotAContainer(ItemID)

    /// Action failed because the target item is not a surface (e.g., trying to put something on a ghost).
    /// The associated `ItemID` is for the non-surface item.
    case targetIsNotASurface(ItemID)

    /// Action failed because a required tool for the action is missing from the player's possession or the environment.
    /// The `String` should name the missing tool (e.g., "a key", "the crowbar").
    case toolMissing(String)

    /// Action failed because the specified entity (item, location) could not be resolved or is unknown.
    /// The `EntityReference` indicates what the parser thought the player was referring to.
    case unknownEntity(EntityReference)

    /// The verb used in the command is not recognized or is not applicable in the current context.
    /// The `String` is the verb word that was not understood.
    case unknownVerb(String)

    /// Action failed because the key used does not fit or work with the lock on the target item.
    /// Includes `ItemID`s for both the key and the lock.
    case wrongKey(keyID: ItemID, lockID: ItemID)
}

extension ActionResponse: CustomStringConvertible {
    public var description: String {
        switch self {
        case .containerIsClosed(let itemID):
            ".containerIsClosed(\(itemID))"
        case .containerIsOpen(let itemID):
            ".containerIsOpen(\(itemID))"
        case .custom(let string):
            ".custom(\(string))"
        case .directionIsBlocked(let string):
            ".directionIsBlocked(\(string ?? ""))"
        case .internalEngineError(let string):
            ".internalEngineError(\(string))"
        case .invalidDirection:
            ".invalidDirection"
        case .invalidIndirectObject(let string):
            ".invalidIndirectObject(\(string ?? ""))"
        case .invalidValue(let string):
            ".invalidValue(\(string))"
        case .itemAlreadyClosed(let itemID):
            ".itemAlreadyClosed(\(itemID))"
        case .itemAlreadyOpen(let itemID):
            ".itemAlreadyOpen(\(itemID))"
        case .itemIsAlreadyWorn(let itemID):
            ".itemIsAlreadyWorn(\(itemID))"
        case .itemIsLocked(let itemID):
            ".itemIsLocked(\(itemID))"
        case .itemIsNotWorn(let itemID):
            ".itemIsNotWorn(\(itemID))"
        case .itemIsUnlocked(let itemID):
            ".itemIsUnlocked(\(itemID))"
        case .itemNotAccessible(let itemID):
            ".itemNotAccessible(\(itemID))"
        case .itemNotClosable(let itemID):
            ".itemNotClosable(\(itemID))"
        case .itemNotDroppable(let itemID):
            ".itemNotDroppable(\(itemID))"
        case .itemNotEdible(let itemID):
            ".itemNotEdible(\(itemID))"
        case .itemNotHeld(let itemID):
            ".itemNotHeld(\(itemID))"
        case .itemNotInContainer(let item, let container):
            """
            .itemNotInContainer(
               item: \(item),
               container: \(container)
            )
            """
        case .itemNotLockable(let itemID):
            ".itemNotLockable(\(itemID))"
        case .itemNotOnSurface(let item, let surface):
            """
            .itemNotOnSurface(
               item: \(item),
               surface: \(surface)
            )
            """
        case .itemNotOpenable(let itemID):
            ".itemNotOpenable(\(itemID))"
        case .itemNotReadable(let itemID):
            ".itemNotReadable(\(itemID))"
        case .itemNotRemovable(let itemID):
            ".itemNotRemovable(\(itemID))"
        case .itemNotTakable(let itemID):
            ".itemNotTakable(\(itemID))"
        case .itemNotUnlockable(let itemID):
            ".itemNotUnlockable(\(itemID))"
        case .itemNotWearable(let itemID):
            ".itemNotWearable(\(itemID))"
        case .itemTooLargeForContainer(let item, let container):
            """
            .itemTooLargeForContainer(
               item: \(item),
               container: \(container)
            )
            """
        case .playerCannotCarryMore:
            ".playerCannotCarryMore"
        case .prerequisiteNotMet(let string):
            ".prerequisiteNotMet(\(string))"
        case .roomIsDark:
            ".roomIsDark"
        case .stateValidationFailed(let change, let actualOldValue):
            if let actualOldValue {
                """
                .stateValidationFailed(
                   change: \(change.description.multiline(2)),
                   actualOldValue: \(actualOldValue)
                )
                """
            } else {
                """
                .stateValidationFailed(
                   change: \(change.description.multiline(2)),
                   actualOldValue: nil
                )
                """
            }
        case .targetIsNotAContainer(let itemID):
            ".targetIsNotAContainer(\(itemID))"
        case .targetIsNotASurface(let itemID):
            ".targetIsNotASurface(\(itemID))"
        case .toolMissing(let string):
            ".toolMissing(\(string))"
        case .unknownEntity(let entityReference):
            ".unknownEntity(\(entityReference))"
        case .unknownVerb(let string):
            ".unknownVerb(\(string))"
        case .wrongKey(let keyID, let lockID):
            """
            .wrongKey(
               key: \(keyID),
               lock: \(lockID)
            )
            """
        }
    }
}
