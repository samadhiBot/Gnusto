/// Identifies specific messages used throughout the Gnusto Interactive Fiction Engine.
///
/// Each kase corresponds to a distinct scenario where the engine needs to communicate
/// with the player. Cases may include associated values for dynamic content like
/// item names, directions, or custom text.
///
/// The enum is designed to be comprehensive, covering:
/// - **Action Response Messages**: Feedback for player actions
/// - **Parse Error Messages**: Communication when input cannot be understood
/// - **System Messages**: Core engine communications (darkness, game state, etc.)
/// - **Status Messages**: Game progress and meta-information
public enum MessageKey: Hashable, Sendable {
    /// Ambiguous input requiring clarification
    case ambiguity(text: String)

    /// Ambiguous pronoun reference
    case ambiguousPronounReference(text: String)

    /// Grammar error in input
    case badGrammar(text: String)

    /// Container is closed (preventing access to contents)
    case containerIsClosed(item: String)

    /// Container is already open
    case containerIsOpen(item: String)

    /// Custom response message
    case custom(message: String)

    /// Movement direction is blocked
    case directionIsBlocked(reason: String?)

    /// Input was empty or contained only noise words
    case emptyInput

    /// Generic internal engine error message
    case internalEngineError

    /// Internal parser error
    case internalParseError

    /// Movement direction is invalid
    case invalidDirection

    /// Invalid indirect object for the action
    case invalidIndirectObject(object: String)

    /// Item is already closed
    case itemAlreadyClosed(item: String)

    /// Item is already open
    case itemAlreadyOpen(item: String)

    /// Item is already being worn
    case itemIsAlreadyWorn(item: String)

    /// Item is already locked
    case itemIsLocked(item: String)

    /// Item is not currently worn
    case itemIsNotWorn(item: String)

    /// Item is already unlocked
    case itemIsUnlocked(item: String)

    /// Item is not accessible to the player
    case itemNotAccessible(item: String)

    /// Item cannot be closed
    case itemNotClosable(item: String)

    /// Item cannot be dropped
    case itemNotDroppable(item: String)

    /// Item cannot be eaten
    case itemNotEdible(item: String)

    /// Item is not held by the player
    case itemNotHeld(item: String)

    /// Item is not in the specified container
    case itemNotInContainer(item: String, container: String)

    /// Item not in scope
    case itemNotInScope(noun: String)

    /// Item cannot be locked
    case itemNotLockable(item: String)

    /// Item is not on the specified surface
    case itemNotOnSurface(item: String, surface: String)

    /// Item cannot be opened
    case itemNotOpenable(item: String)

    /// Item cannot be read
    case itemNotReadable(item: String)

    /// Item cannot be removed
    case itemNotRemovable(item: String)

    /// Item cannot be taken
    case itemNotTakable(item: String)

    /// Item cannot be unlocked
    case itemNotUnlockable(item: String)

    /// Item cannot be worn
    case itemNotWearable(item: String)

    /// Item is too large for container
    case itemTooLargeForContainer(item: String, container: String)

    /// Modifier mismatch (adjective + noun combination not found)
    case modifierMismatch(noun: String, modifiers: [String])

    /// Message displayed when the player moves from light to darkness
    case nowDark

    /// Message displayed when the player moves from darkness to light
    case nowLit

    /// Unknown verb in input
    case parseUnknownVerb(verb: String)

    /// Player's hands are full (cannot carry more items)
    case playerCannotCarryMore

    /// Action prerequisite not met
    case prerequisiteNotMet(message: String)

    /// Pronoun not set
    case pronounNotSet(pronoun: String)

    /// Pronoun refers to out-of-scope item
    case pronounRefersToOutOfScopeItem(pronoun: String)

    /// Message displayed when the player is in a dark location
    case roomIsDark

    /// State validation failure message
    case stateValidationFailed

    /// Target is not a container
    case targetIsNotAContainer(item: String)

    /// Target is not a surface
    case targetIsNotASurface(item: String)

    /// Tool is missing for the action
    case toolMissing(tool: String)

    /// Referenced entity does not exist
    case unknownEntity

    /// Unknown noun in input
    case unknownNoun(noun: String)

    /// Unknown verb
    case unknownVerb(verb: String)

    /// Wrong key for lock
    case wrongKey(key: String, lock: String)
}
