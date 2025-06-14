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

    /// "Dig what?" when direct object is missing in dig command
    case digWhat

    /// "Drink what?" when direct object is missing in drink command
    case drinkWhat

    /// "Eat what?" when direct object is missing in eat command
    case eatWhat

    /// "Empty what?" when direct object is missing in empty command
    case emptyWhat

    /// "Fill what?" when direct object is missing in fill command
    case fillWhat

    /// "Find what?" when direct object is missing in find command
    case findWhat

    /// "Inflate what?" when direct object is missing in inflate command
    case inflateWhat

    /// "Kick what?" when direct object is missing in kick command
    case kickWhat

    /// "Kiss what?" when direct object is missing in kiss command
    case kissWhat

    /// "Knock on what?" when direct object is missing in knock command
    case knockOnWhat

    /// "Lock what?" when direct object is missing in lock command
    case lockWhat

    /// "Lock it with what?" when indirect object is missing in lock command
    case lockWithWhat

    /// "Look inside what?" when direct object is missing in look inside command
    case lookInsideWhat

    /// "Look under what?" when indirect object is missing in look under command
    case lookUnderWhat

    /// Multiple responses for jumping without target (one per line for random selection)
    case jumpResponses

    /// "Push what?" when direct object is missing in push command
    case pushWhat

    /// "Remove what?" when direct object is missing in remove command
    case removeWhat

    /// "Listen to what?" when direct object is missing in listen command
    case listenWhat

    /// "Wear what?" when direct object is missing in wear command
    case wearWhat

    /// "Taste what?" when direct object is missing in taste command
    case tasteWhat

    /// "Smell what?" when direct object is missing in smell command
    case smellWhat

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

    /// "You aren't wearing anything." for remove all with no worn items
    case youArentWearingAnything

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

    /// Success message for removing multiple items
    case youRemoveMultipleItems(items: String)

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

    // MARK: - Specific validation messages

    /// Cannot deflate this item
    case cannotDeflate(item: String)

    /// Cannot inflate this item
    case cannotInflate(item: String)

    /// Cannot enter this item
    case cannotEnter(item: String)

    /// Nothing drinkable in this container
    case nothingToDrinkIn(container: String)

    /// Cannot drink this item
    case cannotDrink(item: String)

    /// Nothing edible in this container
    case nothingToEatIn(container: String)

    /// Cannot eat this item
    case cannotEat(item: String)

    /// Nothing here to enter
    case nothingHereToEnter

    /// Cannot fill from this source
    case cannotFillFrom(source: String)

    /// Can only use item as key
    case canOnlyUseItemAsKey

    /// Can only look at items this way
    case canOnlyLookAtItems

    /// Can only look inside items
    case canOnlyLookInsideItems

    /// Can only drink liquids
    case canOnlyDrinkLiquids

    /// Can only eat food
    case canOnlyEatFood

    /// Can only empty containers
    case canOnlyEmptyContainers

    /// Cannot jump across dangerous gaps
    case jumpDangerous

    /// Cannot jump across water
    case jumpWater(water: String)

    /// Cannot jump characters
    case jumpCharacter(character: String)

    /// Cannot jump small objects
    case jumpSmallObject(item: String)

    /// Cannot jump large immovable objects
    case jumpLargeObject(item: String)

    /// "You have it." for find command when item is in inventory
    case youHaveIt

    /// "It's right here!" for find command when item is visible
    case itsRightHere

    /// "You hear nothing unusual." for listen command
    case youHearNothingUnusual

    /// "Goodbye!" for quit command
    case goodbye

    /// "Game saved." for save command
    case gameSaved

    /// "Game restored." for restore command
    case gameRestored

    /// Item is already locked
    case alreadyLocked(item: String)

    /// "Time passes." for wait command
    case timePasses

    /// "That tastes about average." for taste command
    case tastesAverage

    /// "You smell nothing unusual." for smell command with no object
    case smellNothingUnusual

    /// "That smells about average." for smell command with object
    case smellsAverage

    /// "You can't smell that." for invalid smell target
    case cannotSmellThat

    /// "You can't throw yourself." for throw command with player as object
    case cannotThrowYourself

    /// Current score display message
    case currentScore(score: Int, moves: Int)

    /// Save/restore error messages
    case saveFailed(error: String)
    case restoreFailed(error: String)

    /// "There is nothing here to push." for push all with no pushable items
    case nothingHereToPush

    /// "There is nothing here to remove." for remove all with no removable items
    case nothingHereToRemove

    /// "There is nothing here to wear." for wear all with no wearable items
    case nothingHereToWear

    /// Generic push success message
    case pushSuccess(items: String)
}
