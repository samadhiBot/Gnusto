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
    case actionHandlerInternalError(handler: String, details: String)
    case actionHandlerMissingObjects(handler: String)
    case alreadyHeld(item: String)
    case alreadyLocked(item: String)
    case ambiguity(text: String)
    case ambiguousPronounReference(text: String)
    case askAboutWhat
    case askWhom
    case attackNonCharacter(item: String)
    case attackWhat
    case attackWithBareHands(character: String)
    case attackWithNonWeapon(character: String, weapon: String)
    case attackWithWeapon
    case badGrammar(text: String)
    case blowGeneral
    case blowOnFlammable(item: String)
    case blowOnGeneric(item: String)
    case blowOnLightSource(item: String)
    case breatheResponses
    case burnCannotBurn(item: String)
    case burnToCatchFire(item: String)
    case burnWhat
    case canOnlyActOnCharacters(verb: String)
    case canOnlyActOnItems(verb: String)
    case canOnlyDrinkLiquids
    case canOnlyEatFood
    case canOnlyEmptyContainers
    case canOnlyLookAtItems
    case canOnlyLookInsideItems
    case canOnlyUseItemAsKey
    case cannotActOnThat(verb: String)
    case cannotActWithThat(verb: String)
    case cannotAskAboutThat(item: String)
    case cannotDeflate(item: String)
    case cannotDig(item: String)
    case cannotDrink(item: String)
    case cannotDrinkFromClosed(container: String)
    case cannotEat(item: String)
    case cannotEatFromClosed(container: String)
    case cannotEnter(item: String)
    case cannotFillFrom(source: String)
    case cannotInflate(item: String)
    case cannotPress(item: String)
    case cannotPull(item: String)
    case cannotSmellThat
    case cannotThrowYourself
    case chompContainer
    case chompEdible(item: String)
    case chompPerson
    case chompResponses
    case chompTargetResponses(item: String)
    case chompWeapon
    case chompWearable
    case climbFailure(item: String)
    case climbOnFailure(item: String)
    case climbOnWhat
    case climbSuccess(item: String)
    case climbWhat
    case closed
    case closedItem(item: String)
    case containerAlreadyEmpty(container: String)
    case containerIsClosed(item: String)
    case containerIsOpen(item: String)
    case cryResponses
    case currentScore(score: Int, moves: Int)
    case curseResponses
    case curseTargetResponses(item: String)
    case custom(message: String)
    case cutNoSuitableTool
    case cutToolNotSharp(tool: String)
    case cutWhat
    case cutWithAutoTool(item: String, tool: String)
    case cutWithTool(item: String, tool: String)
    case danceResponses
    case debugRequiresObject
    case deflateSuccess(item: String)
    case deflateWhat
    case digWhat
    case digWithToolNothing(tool: String)
    case diggingBareHandsIneffective
    case directionIsBlocked(reason: String?)
    case doorIsClosed(door: String)
    case doorIsLocked(door: String)
    case drinkFromContainer(liquid: String, container: String)
    case drinkSuccess(item: String)
    case drinkWhat
    case dropped
    case droppedItem(item: String)
    case eatFromContainer(food: String, container: String)
    case eatSuccess(item: String)
    case eatWhat
    case emptyInput
    case emptySuccess(container: String, items: String, count: Int)
    case emptyWhat
    case examineYourself
    case fillSuccess(container: String, source: String)
    case fillWhat
    case findWhat
    case gameRestored
    case gameSaved
    case giveToWhom
    case giveWhat
    case goWhere
    case goodbye
    case inflateSuccess(item: String)
    case inflateWhat
    case insertIntoWhat
    case insertWhat
    case internalEngineError
    case internalParseError
    case invalidDirection
    case invalidIndirectObject(object: String)
    case itemAlreadyClosed(item: String)
    case itemAlreadyInflated(item: String)
    case itemAlreadyOpen(item: String)
    case itemGivenTo(item: String, recipient: String)
    case itemInsertedInto(item: String, container: String)
    case itemIsAlreadyWorn(item: String)
    case itemIsLocked(item: String)
    case itemIsNotWorn(item: String)
    case itemIsUnlocked(item: String)
    case itemNotAccessible(item: String)
    case itemNotClosable(item: String)
    case itemNotDroppable(item: String)
    case itemNotEdible(item: String)
    case itemNotHeld(item: String)
    case itemNotInContainer(item: String, container: String)
    case itemNotInScope(noun: String)
    case itemNotInflated(item: String)
    case itemNotLockable(item: String)
    case itemNotOnSurface(item: String, surface: String)
    case itemNotOpenable(item: String)
    case itemNotReadable(item: String)
    case itemNotRemovable(item: String)
    case itemNotTakable(item: String)
    case itemNotUnlockable(item: String)
    case itemNotWearable(item: String)
    case itemTooLargeForContainer(item: String, container: String)
    case itsRightHere
    case jumpCharacter(character: String)
    case jumpLargeObject(item: String)
    case jumpResponses
    case kickCharacter(character: String)
    case kickLargeObject(item: String)
    case kickWhat
    case kissCharacter(character: String)
    case kissLargeObject(item: String)
    case kissWhat
    case knockOnClosedDoor(door: String)
    case knockOnContainer(container: String)
    case knockOnGenericObject(item: String)
    case knockOnLockedDoor(door: String)
    case knockOnOpenDoor(door: String)
    case knockOnWhat
    case listenWhat
    case lockSuccess(item: String)
    case lockWhat
    case lockWithWhat
    case lookInsideWhat
    case lookUnderWhat
    case maximumVerbosity
    case modifierMismatch(noun: String, modifiers: [String])
    case multipleObjectsNotSupported(verb: String)
    case noLiquidInSource(source: String)
    case noLiquidSourceAvailable
    case nothingHereToEnter
    case nothingHereToExamine
    case nothingHereToPush
    case nothingHereToRemove
    case nothingHereToWear
    case nothingSpecialAbout(item: String)
    case nothingToDrinkIn(container: String)
    case nothingToEatIn(container: String)
    case nothingToTakeHere
    case nowDark
    case nowLit
    case opened(item: String)
    case openingRevealsContents(container: String, contents: String)
    case parseUnknownVerb(verb: String)
    case playerCannotCarryMore
    case prerequisiteNotMet(message: String)
    case pressSuccess(item: String)
    case pressWhat
    case pronounNotSet(pronoun: String)
    case pronounRefersToOutOfScopeItem(pronoun: String)
    case pullSuccess(item: String)
    case pullWhat
    case pushSuccess(items: String)
    case pushWhat
    case removeWhat
    case restoreFailed(error: String)
    case roomIsDark
    case rubCharacter(character: String)
    case rubGenericObject(item: String)
    case rubWhat
    case saveFailed(error: String)
    case shakeCharacter(character: String)
    case shakeClosedContainer(container: String)
    case shakeFixedObject(item: String)
    case shakeOpenContainer(container: String)
    case shakeWhat
    case smellNothingUnusual
    case smellWhat
    case smellsAverage
    case squeezeCharacter(character: String)
    case squeezeHardObject(item: String)
    case squeezeWhat
    case stateValidationFailed
    case suggestUsingToolToDig
    case taken
    case targetIsNotAContainer(item: String)
    case targetIsNotASurface(item: String)
    case tastesAverage
    case thereIsNothingHereToTake
    case thinkAboutItem(item: String)
    case thinkAboutLocation
    case thinkAboutSelf
    case thinkAboutWhat
    case throwAtCharacter(item: String, character: String)
    case throwAtObject(item: String, target: String)
    case throwGeneral(item: String)
    case throwWhat
    case timePasses
    case toolMissing(tool: String)
    case toolNotSuitableForDigging(tool: String)
    case turnCharacter(character: String)
    case turnFixedObject(item: String)
    case turnWhat
    case unknownEntity
    case unknownNoun(noun: String)
    case unknownVerb(verb: String)
    case waveCharacter(character: String)
    case waveFixedObject(item: String)
    case waveWhat
    case wearWhat
    case whatQuestion(verb: String)
    case wrongKey(key: String, lock: String)
    case youAlreadyHaveThat
    case youAreCarrying
    case youAreEmptyHanded
    case youArentHoldingThat
    case youArentWearingAnything
    case youCanOnlyActOnItems(verb: String)
    case youCantDoThat
    case youDontHaveThat
    case youDropMultipleItems(items: String)
    case youHaveIt
    case youHearNothingUnusual
    case youRemoveMultipleItems(items: String)
    case youTakeMultipleItems(items: String)

    // Additional action handler messages
    case examineWhat
    case moveWhat
    case pourWhat
    case pourOn(item: String, target: String)
    case pourCannotPourThat
    case pourCannotPourOnThat
    case pourCannotPourItself(item: String)
    case pourNotLiquid(item: String)
    case pourOnCharacter(item: String, character: String)
    case pourOnDevice(item: String, device: String)
    case pourOnGeneric(item: String, target: String)
    case putWhat
    case putOnWhat(item: String)
    case putCannotPutOnSelf
    case putCannotPutCircular(item: String, container: String, preposition: String)
    case raiseWhat
    case raiseCannotLift(item: String)
    case readWhat
    case scriptAlreadyOn
    case scriptNotOn
    case smellCanOnlySmellItems
    case tasteWhat
    case tellWhom
    case tellAboutWhat
    case tellCanOnlyTellCharacters
    case tellCannotTellAbout(character: String)
    case tieWhat
    case tieCannotTieThat
    case tieCannotTieToThat
    case tieCannotTieToSelf(item: String)
    case tieCannotTieLivingBeings
    case tieNeedsSomethingToTieWith(item: String)
    case tieNeedsSomethingToTieCharacterWith(character: String)
    case touchWhat
    case turnOffWhat
    case turnOnWhat
    case alreadyOff
    case alreadyOn
    case cannotTurnOff
    case cannotTurnOn
    case unlockWhat
    case unlockWithWhat
    case unlockAlreadyUnlocked(item: String)
    case youCanOnlyMoveItems
    case youCanOnlyPutItemsOnThings
    case youCanOnlyPutThingsOnSurfaces
    case youCanOnlyRaiseItems
    case youCanOnlyReadItems
    case youCanOnlySmellItems
    case youCanOnlyTasteItems
    case youCanOnlyTellCharacters
    case youCanOnlyTouchItems
    case youCanOnlyTurnOffItems
    case youCanOnlyTurnOnItems
    case youCanOnlyUnlockItems
    case youCanOnlyUseItemAsKey
    case youCanOnlyWearItems
    case youCannotTakeFromNonContainer(container: String)
    case insertHaveNothingToPut(container: String)
}
