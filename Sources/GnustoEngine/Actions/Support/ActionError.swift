/// Enumerates errors that can occur during the execution phase of a command.
public enum ActionError: Error, Equatable, Sendable {
    case containerIsClosed(ItemID)
    case containerIsFull(ItemID)
    case containerIsOpen(ItemID)     // e.g., trying to close an already open non-openable item?
    case directionIsBlocked(String?) // Optional message from Exit
    case internalEngineError(String) // Unexpected issue within the engine/handler
    case invalidDirection
    case itemAlreadyClosed(ItemID)
    case itemAlreadyOpen(ItemID)
    case itemIsLocked(ItemID)
    case itemIsUnlocked(ItemID)
    case itemNotAccessible(ItemID) // Item exists but is not in reach
    case itemNotCloseable(ItemID)
    case itemNotDroppable(ItemID)  // e.g., fixed objects
    case itemNotEdible(ItemID)
    case itemNotHeld(ItemID)       // Player isn't holding an item (e.g., for drop, wear)
    case itemNotInContainer(item: ItemID, container: ItemID)
    case itemNotLockable(ItemID)
    case itemNotOnSurface(item: ItemID, surface: ItemID)
    case itemNotOpenable(ItemID)
    case itemNotReadable(ItemID)
    case itemNotRemovable(ItemID)  // For worn items
    case itemNotTakable(ItemID)
    case itemNotUnlockable(ItemID)
    case itemNotWearable(ItemID)
    case playerCannotCarryMore
    case prerequisiteNotMet(String) // Generic message for when a condition isn't met
    case roomIsDark                 // Action requires light, but the room is dark
    case targetIsNotAContainer(ItemID)
    case targetIsNotASurface(ItemID)
    case wrongKey(keyID: ItemID, lockID: ItemID)

    // Add more specific errors as needed...
}
