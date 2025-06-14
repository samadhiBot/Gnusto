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
public enum MessageKey: Hashable, Sendable {  // IMPORTANT: Keep cases alphabetized
    /// Item is already held by the player
    case alreadyHeld(item: String)

    /// Ambiguous input requiring clarification
    case ambiguity(text: String)

    /// Ambiguous pronoun reference
    case ambiguousPronounReference(text: String)

    /// Grammar error in input
    case badGrammar(text: String)

    /// Simple "Closed." confirmation
    case closed

    /// Detailed confirmation for closing something
    case closedItem(item: String)

    /// Container is closed (preventing access to contents)
    case containerIsClosed(item: String)

    /// Container is already open
    case containerIsOpen(item: String)

    /// Custom response message
    case custom(message: String)

    /// Movement direction is blocked
    case directionIsBlocked(reason: String?)

    /// Door is closed (blocking movement)
    case doorIsClosed(direction: String)

    /// Door is locked (blocking movement)
    case doorIsLocked(door: String)

    /// Simple "Dropped." confirmation
    case dropped

    /// Item successfully dropped with details
    case droppedItem(item: String)

    /// Input was empty or contained only noise words
    case emptyInput

    /// "Give to whom?" for missing indirect object in give command
    case giveToWhom

    /// "Give what?" for missing direct object in give command
    case giveWhat

    /// "Go where?" when direction is missing
    case goWhere

    /// "Ask about what?" when indirect object is missing in ask command
    case askAboutWhat

    /// "Ask whom?" when direct object is missing in ask command
    case askWhom

    /// "Attack what?" when direct object is missing in attack command
    case attackWhat

    /// Multiple responses for breathing (one per line for random selection)
    case breatheResponses

    /// "Burn what?" when direct object is missing in burn command
    case burnWhat

    /// Multiple responses for chomping without target (one per line for random selection)
    case chompResponses

    /// Multiple responses for chomping with target (one per line for random selection)
    case chompTargetResponses(item: String)

    /// "Climb on what?" when indirect object is missing in climb on command
    case climbOnWhat

    /// "Climb what?" when direct object is missing in climb command
    case climbWhat

    /// Multiple responses for crying (one per line for random selection)
    case cryResponses

    /// "Cut what?" when direct object is missing in cut command
    case cutWhat

    /// Multiple responses for cursing without target (one per line for random selection)
    case curseResponses

    /// Multiple responses for cursing with target (one per line for random selection)
    case curseTargetResponses(item: String)

    /// Multiple responses for dancing (one per line for random selection)
    case danceResponses

    /// "Deflate what?" when direct object is missing in deflate command
    case deflateWhat

    /// "Insert into what?" for missing indirect object in insert command
    case insertIntoWhat

    /// "Insert what?" for missing direct object in insert command
    case insertWhat

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

    /// Item successfully given to recipient
    case itemGivenTo(item: String, recipient: String)

    /// Item successfully inserted into container
    case itemInsertedInto(item: String, container: String)

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

    /// Multiple objects not supported for this action
    case multipleObjectsNotSupported(verb: String)

    /// "You see nothing special about X."
    case nothingSpecialAbout(item: String)

    /// "Nothing to take here." for TAKE ALL with no takeable items
    case nothingToTakeHere

    /// Message displayed when the player moves from light to darkness
    case nowDark

    /// Message displayed when the player moves from darkness to light
    case nowLit

    /// Simple confirmation for opening something
    case opened(item: String)

    /// Opening a container reveals its contents
    case openingRevealsContents(container: String, contents: String)

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

    /// Simple "Taken." confirmation
    case taken

    /// Target is not a container
    case targetIsNotAContainer(item: String)

    /// Target is not a surface
    case targetIsNotASurface(item: String)

    /// "There is nothing here to take." alternative phrasing
    case thereIsNothingHereToTake

    /// Tool is missing for the action
    case toolMissing(tool: String)

    /// Referenced entity does not exist
    case unknownEntity

    /// Unknown noun in input
    case unknownNoun(noun: String)

    /// Unknown verb
    case unknownVerb(verb: String)

    /// Generic "what?" response for missing direct object
    case whatQuestion(verb: String)

    /// Wrong key for lock
    case wrongKey(key: String, lock: String)

    /// "You already have that." when trying to take held item
    case youAlreadyHaveThat

    /// "You are carrying:" prefix for inventory list
    case youAreCarrying

    /// "You are empty-handed." for empty inventory
    case youAreEmptyHanded

    /// "You aren't holding that." when trying to drop unheld item
    case youArentHoldingThat

    /// "You can only X items." for type restrictions
    case youCanOnlyActOnItems(verb: String)

    /// Generic "You can't do that." response
    case youCantDoThat

    /// "You don't have that." when trying to give unheld item
    case youDontHaveThat

    /// Success message for dropping multiple items
    /// "You drop multiple items."
    case youDropMultipleItems(items: String)

    /// Success message for taking multiple items
    case youTakeMultipleItems(items: String)

    // MARK: - Action-specific messages

    /// Attack responses for different scenarios
    case attackNonCharacter(item: String)
    case attackWithBareHands(character: String)
    case attackWithNonWeapon(character: String, weapon: String)
    case attackWithWeapon

    /// Blowing responses
    case blowOnLightSource(item: String)
    case blowOnFlammable(item: String)
    case blowOnGeneric(item: String)
    case blowGeneral

    /// Burning responses
    case burnToCatchFire(item: String)
    case burnJokingResponse
    case burnCannotBurn(item: String)

    /// Chomping responses - edible item
    case chompEdible(item: String)
    case chompPerson
    case chompWearable
    case chompContainer
    case chompWeapon

    /// Climbing responses
    case climbSuccess(item: String)
    case climbFailure(item: String)
    case climbOnFailure(item: String)

    /// Cutting responses
    case cutWithTool(item: String, tool: String)
    case cutToolNotSharp(tool: String)
    case cutWithAutoTool(item: String, tool: String)
    case cutNoSuitableTool

    /// Generic validation messages
    case canOnlyActOnCharacters(verb: String)
    case canOnlyActOnItems(verb: String)
    case cannotActOnThat(verb: String)
    case cannotActWithThat(verb: String)
    case debugRequiresObject

    /// Engine error messages
    case actionHandlerMissingObjects(handler: String)
    case actionHandlerInternalError(handler: String, details: String)
}
