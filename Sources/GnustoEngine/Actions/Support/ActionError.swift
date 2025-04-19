/// Enumerates errors that can occur during the execution phase of a command.
public enum ActionError: Error, Equatable, Sendable {
    // General Failures
    case prerequisiteNotMet(String) // Generic message for when a condition isn't met
    case internalEngineError(String) // Unexpected issue within the engine/handler

    // Movement Errors
    case invalidDirection
    case directionIsBlocked(String?) // Optional message from Exit

    // Object Interaction Errors
    case itemNotTakable(ItemID)
    case itemNotDroppable(ItemID) // e.g., fixed objects
    case itemNotOpenable(ItemID)
    case itemNotCloseable(ItemID)
    case itemNotLockable(ItemID)
    case itemNotUnlockable(ItemID)
    case itemNotEdible(ItemID)
    case itemNotReadable(ItemID)
    case itemNotWearable(ItemID)
    case itemNotRemovable(ItemID) // For worn items
    case itemAlreadyOpen(ItemID)
    case itemAlreadyClosed(ItemID)
    case itemIsLocked(ItemID)
    case itemIsUnlocked(ItemID)
    case wrongKey(keyID: ItemID, lockID: ItemID)

    // Container/Surface Errors
    case targetIsNotAContainer(ItemID)
    case targetIsNotASurface(ItemID)
    case containerIsClosed(ItemID)
    case containerIsOpen(ItemID) // e.g., trying to close an already open non-openable item?
    case containerIsFull(ItemID)
    case itemNotInContainer(item: ItemID, container: ItemID)
    case itemNotOnSurface(item: ItemID, surface: ItemID)

    // Player State Errors
    case playerCannotCarryMore
    case itemNotHeld(ItemID)       // Player isn't holding an item they need to be (e.g., for drop, wear)
    case itemNotAccessible(ItemID) // Item exists but is not in reach (not in inv, not visible in loc)
    case roomIsDark                // Action requires light, but the room is dark

    // Add more specific errors as needed...
}
