import Foundation

/// Enumerates standard reasons why a game action might fail or be disallowed.
///
/// `ActionHandler`s (especially their `validate` and `process` methods) throw `ActionResponse`
/// instances to indicate specific failure conditions. The `GameEngine` then typically
/// translates these into appropriate messages for the player.
public enum ActionResponse: Error, Equatable, Sendable {
    /// Action failed because the verb required something absent in the command.
    case cannotDo(ActionContext, ItemProxy)

    /// Action failed because the verb required something absent in the command.
    case cannotDoThat(ActionContext)

    /// Action failed because the verb required some other instrument than the one in the command.
    case cannotDoWithThat(ActionContext, ItemProxy, ItemProxy?)

    /// Action failed because the verb required something absent in the command.
    case cannotDoYourself(ActionContext)

    /// Action failed because a circular dependency was detected in property computation.
    /// This occurs when item properties depend on each other in a way that would cause
    /// infinite recursion during computation.
    case circularDependency(String)

    /// Action failed because the target container (e.g., a box, chest) is closed.
    case containerIsClosed(ItemProxy)

    /// Action failed because the target container is already open (e.g., trying to open an
    /// item that is not closable but is considered "open" by default, or trying to close an item
    /// that is already open and cannot be closed).
    case containerIsOpen(ItemProxy)

    /// Movement in a specified direction failed because the way is blocked.
    /// The optional `String` can provide a specific reason (e.g., "The door is locked.").
    case directionIsBlocked(String?)

    /// Action failed because the command did not provide enough information.
    case doWhat(ActionContext)

    /// A generic feedback message provided directly by a handler.
    ///
    /// This generally indicates that some prerequisite for the action was not met.
    case feedback(String)

    case fileManagerError(URL)

    /// An unexpected internal error occurred within the game engine or an action handler.
    /// The `String` provides details about the error, primarily for debugging.
    case internalEngineError(String)

    /// The direction specified in a movement command was invalid (e.g., "go sideways")
    /// or does not exist as an exit from the current location.
    case invalidDirection

    /// The indirect object specified in the command is unsuitable for the action or missing.
    /// The `String` might contain the name of the object if it was identified but deemed invalid.
    case invalidIndirectObject(ItemProxy?)

    /// A value intended for a state change or property update was invalid.
    /// This might occur if a dynamic property validation handler rejected a new value.
    /// The `String` provides details, often for debugging.
    case invalidValue(String)

    /// Action failed because the target item, though it may exist, is not currently reachable
    /// or perceivable by the player (e.g., it's in another room, in a closed container, or in darkness).
    case itemNotAccessible(ItemProxy)

    /// Action failed because the player is not currently holding the required item in their inventory.
    case itemNotHeld(ItemProxy)

    /// Action failed because multiple direct objects were detected for an action that only
    /// supports one object.
    case multipleObjectsNotSupported(ActionContext)

    /// Action failed because the player's inventory is full and cannot accommodate more items or weight.
    case playerCannotCarryMore

    /// Action failed because the current location is dark, and the action requires light to perform.
    case roomIsDark

    /// Action failed because the target item is not a container (e.g., trying to put something into an apple).
    case targetIsNotAContainer(ItemProxy)

    /// Action failed because the item isn't found in the game data.
    case unknownItem(ItemID)

    /// Action failed because the location isn't found in the game data.
    case unknownLocation(LocationID)
}
