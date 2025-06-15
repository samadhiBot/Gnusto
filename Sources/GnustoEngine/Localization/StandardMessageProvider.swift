/// Standard English message provider for the Gnusto Interactive Fiction Engine.
///
/// This implementation provides traditional interactive fiction responses in English,
/// following the style and tone established by classic games like Zork. Game developers
/// can subclass this provider to customize specific messages while inheriting sensible
/// defaults for others.
///
/// The messages aim to be:
/// - **Clear and informative**: Players understand what happened and why
/// - **Consistent in tone**: Maintains the classic IF voice
/// - **Respectful of ZIL traditions**: Uses familiar phrases when appropriate
public struct StandardMessageProvider: MessageProvider, Sendable {
    public let languageCode = "en"

    public init() {}

    // IMPORTANT: Keep cases alphabetized
    public func message(for key: MessageKey) -> String {
        switch key {
        case .actionHandlerInternalError(let handler, let details):
            "A strange buzzing sound indicates something is wrong with \(handler): \(details)"

        case .actionHandlerMissingObjects(let handler):
            "A strange buzzing sound indicates something is wrong with \(handler)."

        case .alreadyHeld(let item):
            "You already have \(item)."

        case .alreadyLocked(let item):
            "\(item.capitalizedFirst) is already locked."

        case .ambiguity(let text):
            text

        case .ambiguousPronounReference(let text):
            text

        case .askAboutWhat:
            "Ask about what?"

        case .askWhom:
            "Ask whom?"

        case .attackNonCharacter(let item):
            "I've known strange people, but fighting \(item)?"

        case .attackWhat:
            "Attack what?"

        case .attackWithBareHands(let character):
            "Trying to attack \(character) with your bare hands is suicidal."

        case .attackWithNonWeapon(let character, let weapon):
            "Trying to attack \(character) with \(weapon) is suicidal."

        case .attackWithWeapon:
            "Let's hope it doesn't come to that."

        case .badGrammar(let text):
            text

        case .blowGeneral:
            "You blow air around. Nothing happens."

        case .blowOnFlammable(let item):
            "Blowing on \(item) has no effect."

        case .blowOnGeneric(let item):
            "You blow on \(item). Nothing happens."

        case .blowOnLightSource(let item):
            "You blow on \(item), but it doesn't go out."

        case .breatheResponses:
            """
            You breathe in deeply, feeling refreshed.
            You take a slow, calming breath.
            The air fills your lungs. You're glad that you can breathe.
            You inhale deeply, then exhale slowly.
            You breathe in the love... and blow out the jive.
            """

        case .burnCannotBurn(let item):
            "You can't burn \(item)."

        case .burnToCatchFire(let item):
            "\(item.capitalizedFirst) catches fire and burns to ashes."

        case .burnWhat:
            "Burn what?"

        case .cannotActOnThat(let verb):
            "You can't \(verb) that."

        case .cannotActWithThat(let verb):
            "You can't \(verb) with that."

        case .cannotAskAboutThat(let item):
            "You can't ask \(item) about that."

        case .cannotDeflate(let item):
            "You can't deflate \(item)."

        case .cannotDig(let item):
            "You can't dig \(item)."

        case .cannotDrink(let item):
            "You can't drink \(item)."

        case .cannotDrinkFromClosed(let container):
            "You can't drink \(container)."

        case .cannotEat(let item):
            "You can't eat \(item)."

        case .cannotEatFromClosed(let container):
            "You can't eat from \(container)."

        case .cannotEnter(let item):
            "You can't enter \(item)."

        case .cannotFillFrom(_):
            "You can't fill from that."

        case .cannotInflate(let item):
            "You can't inflate \(item)."

        case .cannotPress(let item):
            "You can't press \(item)."

        case .cannotPull(let item):
            "You can't pull \(item)."

        case .cannotSmellThat:
            "You can't smell that."

        case .cannotThrowYourself:
            "You can't throw yourself."

        case .canOnlyActOnCharacters(let verb):
            "You can only \(verb) other characters."

        case .canOnlyActOnItems(let verb):
            "You can only \(verb) items."

        case .canOnlyDrinkLiquids:
            "You can only drink liquids."

        case .canOnlyEatFood:
            "You can only eat food."

        case .canOnlyEmptyContainers:
            "You can only empty containers."

        case .canOnlyLookAtItems:
            "You can only look at items this way."

        case .canOnlyLookInsideItems:
            "You can only look inside items."

        case .canOnlyUseItemAsKey:
            "You can only use an item as a key."

        case .chompContainer:
            "You'd probably break your teeth on that."

        case .chompEdible(let item):
            "You take a bite. It tastes like \(item)."

        case .chompPerson:
            "That would be rude, not to mention dangerous."

        case .chompResponses:
            """
            You chomp your teeth together menacingly.
            You clench your fists and gnash your teeth.
            You chomp at the air for everyone to see.
            Sounds of your chomping echo around you.
            You practice your chomping technique.
            It feels good to get some chomping done.
            """

        case .chompTargetResponses(let item):
            """
            You give \(item) a tentative nibble. It tastes terrible.
            You chomp on \(item) experimentally. Not very satisfying.
            You bite \(item). Your teeth don't make much of an impression.
            You gnaw on \(item) briefly before giving up.
            You take a bite of \(item). It's not very appetizing.
            """

        case .chompWeapon:
            "That seems like a good way to hurt yourself."

        case .chompWearable:
            "Chewing on clothing is not recommended for your dental health."

        case .climbFailure(let item):
            "You can't climb \(item)."

        case .climbOnFailure(let item):
            "You can't climb on \(item)."

        case .climbOnWhat:
            "Climb on what?"

        case .climbSuccess(let item):
            "You climb \(item)."

        case .climbWhat:
            "Climb what?"

        case .closed:
            "Closed."

        case .closedItem(let item):
            "You close \(item)."

        case .containerAlreadyEmpty(let container):
            "\(container.capitalizedFirst) is already empty."

        case .containerIsClosed(let item):
            "\(item.capitalizedFirst) is closed."

        case .containerIsOpen(let item):
            "\(item.capitalizedFirst) is already open."

        case .cryResponses:
            """
            You shed a tear for the futility of it all.
            You weep quietly to yourself.
            You sob dramatically, and feel a little better.
            You cry a bit. There, there now.
            You bawl your eyes out, which is somewhat cathartic.
            You weep with the passion of a thousand sorrows.
            You cry like a baby. How embarrassing.
            You shed crocodile tears. Very convincing.
            You weep bitter tears.
            You break down and cry. After a bit the world seems a little brighter.
            """

        case .currentScore(let score, let moves):
            "Your score is \(score) in \(moves) moves."

        case .curseResponses:
            """
            You curse under your breath.
            You let out a string of colorful expletives.
            You swear like a sailor. Very cathartic.
            You curse the fates that brought you here.
            You damn everything in sight. You feel better now.
            You use language that would make your mother wash your mouth out with soap.
            You curse fluently in several languages.
            You swear with the passion of a thousand frustrated adventurers.
            """

        case .curseTargetResponses(let item):
            """
            You curse \(item) roundly. You feel a bit better.
            You let loose a string of expletives at \(item).
            You damn \(item) to the seven hells.
            You swear colorfully at \(item). How therapeutic!
            You curse \(item) with words that would make a sailor blush.
            """

        case .custom(let message):
            message

        case .cutNoSuitableTool:
            "You have no suitable cutting tool."

        case .cutToolNotSharp(let tool):
            "\(tool.capitalizedFirst) isn't sharp enough to cut anything."

        case .cutWhat:
            "Cut what?"

        case .cutWithAutoTool(let item, let tool):
            "You cut \(item) with \(tool)."

        case .cutWithTool(let item, let tool):
            "You cut \(item) with \(tool)."

        case .danceResponses:
            """
            Dancing is forbidden.
            You dance an adorable little jig.
            You boogie down with surprising grace.
            You perform a modern interpretive dance.
            You dance like nobody's watching (which they aren't).
            You cut a rug with style and panache.
            You dance the dance of your people.
            You waltz around the area with imaginary partners.
            You break into spontaneous choreography.
            You dance with wild abandon. Bravo!
            Let all the children boogie.
            """

        case .debugRequiresObject:
            "DEBUG requires a direct object to examine."

        case .deflateSuccess(let item):
            "You deflate \(item)."

        case .deflateWhat:
            "Deflate what?"

        case .diggingBareHandsIneffective:
            "Digging with your bare hands is ineffective."

        case .digWhat:
            "Dig what?"

        case .digWithToolNothing(let tool):
            "You dig with \(tool), but find nothing of interest."

        case .directionIsBlocked(let reason):
            reason ?? "Something is blocking the way."

        case .doorIsClosed(let door):
            "\(door.capitalizedFirst) door is closed."

        case .doorIsLocked(let door):
            "\(door.capitalizedFirst) is locked."

        case .drinkFromContainer(let liquid, let container):
            "You drink \(liquid) from \(container). Refreshing!"

        case .drinkSuccess(let item):
            "You drink \(item). It's quite refreshing."

        case .drinkWhat:
            "Drink what?"

        case .dropped:
            "Dropped."

        case .droppedItem(let item):
            "You drop \(item)."

        case .eatFromContainer(let food, let container):
            "You eat \(food) from \(container). Delicious!"

        case .eatSuccess(let item):
            "You eat \(item). It's quite satisfying."

        case .eatWhat:
            "Eat what?"

        case .emptyInput:
            "I beg your pardon?"

        case .emptySuccess(let container, let items, let count):
            "You empty \(container), and \(items) \(count == 1 ? "falls" : "fall") to the ground."

        case .emptyWhat:
            "Empty what?"

        case .examineYourself:
            "You are your usual self."

        case .fillSuccess(let container, let source):
            "You fill \(container) from \(source)."

        case .fillWhat:
            "Fill what?"

        case .findWhat:
            "Find what?"

        case .gameRestored:
            "Game restored."

        case .gameSaved:
            "Game saved."

        case .giveToWhom:
            "Give to whom?"

        case .giveWhat:
            "Give what?"

        case .goodbye:
            "Goodbye!"

        case .goWhere:
            "Go where?"

        case .inflateSuccess(let item):
            "You inflate \(item)."

        case .inflateWhat:
            "Inflate what?"

        case .insertWhat:
            "Insert what?"

        case .internalEngineError, .internalParseError:
            "A strange buzzing sound indicates something is wrong."

        case .invalidDirection:
            "You can't go that way."

        case .invalidIndirectObject(let object):
            "You can't use \(object) for that."

        case .itemAlreadyClosed(let item):
            "\(item.capitalizedFirst) is already closed."

        case .itemAlreadyInflated(let item):
            "\(item.capitalizedFirst) is already inflated."

        case .itemAlreadyOpen(let item):
            "\(item.capitalizedFirst) is already open."

        case .itemGivenTo(let item, let recipient):
            "You give \(item) to \(recipient)."

        case .itemInsertedInto(let item, let container):
            "You put \(item) into \(container)."

        case .itemIsAlreadyWorn(let item):
            "You are already wearing \(item)."

        case .itemIsLocked(let item):
            "\(item.capitalizedFirst) is locked."

        case .itemIsNotWorn(let item):
            "You are not wearing \(item)."

        case .itemIsUnlocked(let item):
            "\(item.capitalizedFirst) is already unlocked."

        case .itemNotAccessible(let item):
            "You can't see \(item)."

        case .itemNotClosable(let item):
            "\(item.capitalizedFirst) is not something you can close."

        case .itemNotDroppable(let item):
            "You can't drop \(item)."

        case .itemNotEdible(let item):
            "You can't eat \(item)."

        case .itemNotHeld(let item):
            "You aren't holding \(item)."

        case .itemNotInContainer(let item, let container):
            "\(item.capitalizedFirst) isn't in \(container)."

        case .itemNotInflated(let item):
            "\(item.capitalizedFirst) is not inflated."

        case .itemNotInScope(let noun):
            "You can't see any '\(noun)' here."

        case .itemNotLockable(let item):
            "You can't lock \(item)."

        case .itemNotOnSurface(let item, let surface):
            "\(item.capitalizedFirst) isn't on \(surface)."

        case .itemNotOpenable(let item):
            "You can't open \(item)."

        case .itemNotReadable(let item):
            "\(item.capitalizedFirst) isn't something you can read."

        case .itemNotRemovable(let item):
            "You can't remove \(item)."

        case .itemNotTakable(let item):
            "You can't take \(item)."

        case .itemNotUnlockable(let item):
            "You can't unlock \(item)."

        case .itemNotWearable(let item):
            "You can't wear \(item)."

        case .itemTooLargeForContainer(let item, let container):
            "\(item.capitalizedFirst) won't fit in \(container)."

        case .itsRightHere:
            "It's right here!"

        case .jumpCharacter(let character):
            "You can't jump \(character)."

        case .jumpLargeObject(let item):
            "You can't jump \(item)."

        case .jumpResponses:
            """
            You jump on the spot, fruitlessly.
            You jump up and down.
            You leap into the air.
            You bounce up and down.
            """

        case .kickCharacter(let character):
            "I don't think \(character) would appreciate that."

        case .kickLargeObject(let item):
            "Ouch! You hurt your foot kicking \(item)."

        case .kickWhat:
            "Kick what?"

        case .kissCharacter(let character):
            "\(character.capitalizedFirst) doesn't seem particularly receptive to your affections."

        case .kissObject(let item):
            "You can't kiss \(item)."

        case .kissSelf:
            "You kiss yourself."

        case .kissWhat:
            "Kiss what?"

        case .knockOnClosedDoor(let door):
            "You knock on \(door), but there's no answer."

        case .knockOnContainer(let container):
            "You knock on \(container). You hear a hollow sound."

        case .knockOnGenericObject(let item):
            "You knock on \(item). Nothing happens."

        case .knockOnLockedDoor(let door):
            "You knock on \(door). There's no response from the other side."

        case .knockOnOpenDoor(let door):
            "\(door.capitalizedFirst) is already open. There's no need to knock."

        case .knockOnWhat:
            "Knock on what?"

        case .listenWhat:
            "Listen to what?"

        case .lockSuccess(let item):
            "\(item.capitalizedFirst) is now locked."

        case .lockWhat:
            "Lock what?"

        case .lockWithWhat:
            "Lock it with what?"

        case .lookInsideWhat:
            "Look inside what?"

        case .lookUnderWhat:
            "Look under what?"

        case .maximumVerbosity:
            "Maximum verbosity. Full location descriptions will be shown every time you enter a location."

        case .modifierMismatch(let noun, let modifiers):
            "I don't see any '\(modifiers.joined(separator: " ")) \(noun)' here."

        case .multipleObjectsNotSupported(let verb):
            "The \(verb.uppercased()) command doesn't support multiple objects."

        case .noLiquidInSource(let source):
            "There's no liquid in \(source) to fill from."

        case .noLiquidSourceAvailable:
            "There's no source of liquid here to fill from."

        case .nothingHereToEnter:
            "There's nothing here to enter."

        case .nothingHereToExamine:
            "There is nothing here to examine."

        case .nothingHereToPush:
            "There is nothing here to push."

        case .nothingHereToRemove:
            "There is nothing here to remove."

        case .nothingHereToWear:
            "There is nothing here to wear."

        case .nothingSpecialAbout(let item):
            "You see nothing special about \(item)."

        case .nothingToDrinkIn(let container):
            "There's nothing to drink in \(container)."

        case .nothingToEatIn(let container):
            "There's nothing to eat in \(container)."

        case .nothingToTakeHere:
            "Nothing to take here."

        case .nowDark:
            "You are plunged into darkness."

        case .nowLit:
            "You can see your surroundings now."

        case .opened(let item):
            "You open \(item)."

        case .openingRevealsContents(let container, let contents):
            "Opening \(container) reveals \(contents)."

        case .parseUnknownVerb(let verb):
            "I don't know the verb '\(verb)'."

        case .playerCannotCarryMore:
            "Your hands are full."

        case .prerequisiteNotMet(let message):
            message.isEmpty ? "You can't do that." : message

        case .pressSuccess(let item):
            "You press \(item)."

        case .pressWhat:
            "Press what?"

        case .pronounNotSet(let pronoun):
            "I don't know what '\(pronoun)' refers to."

        case .pronounRefersToOutOfScopeItem(let pronoun):
            "You can't see what '\(pronoun)' refers to right now."

        case .pullSuccess(let item):
            "You pull \(item)."

        case .pullWhat:
            "Pull what?"

        case .pushSuccess(let items):
            "You push \(items). Nothing happens."

        case .pushWhat:
            "Push what?"

        case .removeWhat:
            "Remove what?"

        case .restoreFailed(let error):
            "Restore failed: \(error)"

        case .roomIsDark:
            "It is pitch black. You can't see a thing."

        case .rubCharacter(let character):
            "I don't think \(character) would appreciate being rubbed."

        case .rubGenericObject(let item):
            "You rub \(item), but nothing interesting happens."

        case .rubWhat:
            "Rub what?"

        case .saveFailed(let error):
            "Save failed: \(error)"

        case .shakeCharacter(let character):
            "I don't think \(character) would appreciate being shaken."

        case .shakeClosedContainer(let container):
            "You shake \(container) and hear something rattling inside."

        case .shakeFixedObject(let item):
            "You can't shake \(item) - it's firmly in place."

        case .shakeOpenContainer(let container):
            "You shake \(container), but nothing falls out."

        case .shakeWhat:
            "Shake what?"

        case .smellNothingUnusual:
            "You smell nothing unusual."

        case .smellsAverage:
            "That smells about average."

        case .smellWhat:
            "Smell what?"

        case .squeezeCharacter(let character):
            "I don't think \(character) would appreciate being squeezed."

        case .squeezeHardObject(let item):
            "You squeeze \(item) as hard as you can, but it doesn't give."

        case .squeezeWhat:
            "Squeeze what?"

        case .stateValidationFailed:
            "A strange buzzing sound indicates something is wrong with the state validation."

        case .suggestUsingToolToDig:
            "You could try using a tool to dig with."

        case .taken:
            "Taken."

        case .targetIsNotAContainer(let item):
            "You can't put things in \(item)."

        case .targetIsNotASurface(let item):
            "You can't put things on \(item)."

        case .tastesAverage:
            "That tastes about average."

        case .tasteWhat:
            "Taste what?"

        case .thereIsNothingHereToTake:
            "There is nothing here to take."

        case .thinkAboutItem(let item):
            "You contemplate \(item) for a bit, but nothing fruitful comes to mind."

        case .thinkAboutLocation:
            "You ponder the location, but it remains stubbornly locational."

        case .thinkAboutSelf:
            "Yes, yes, you're very important."

        case .thinkAboutWhat:
            "Think about what?"

        case .throwAtCharacter(let item, let character):
            "You throw \(item) at \(character)."

        case .throwAtObject(let item, let target):
            "You throw \(item) at \(target). It bounces off harmlessly."

        case .throwGeneral(let item):
            "You throw \(item), and it falls to the ground."

        case .throwWhat:
            "Throw what?"

        case .timePasses:
            "Time passes."

        case .toolMissing(let tool):
            "You need \(tool) for that."

        case .toolNotSuitableForDigging(let tool):
            "\(tool.capitalizedFirst) isn't suitable for digging."

        case .turnCharacter(let character):
            "You can't turn \(character) around like an object."

        case .turnFixedObject(let item):
            "\(item.capitalizedFirst) doesn't seem to be designed to be turned."

        case .turnWhat:
            "Turn what?"

        case .unknownEntity:
            "You can't see any such thing."

        case .unknownNoun(let noun):
            "I don't see any '\(noun)' here."

        case .unknownVerb(let verb):
            "I don't know how to \"\(verb)\" something."

        case .waveCharacter(let character):
            "You wave \(character) around, but it doesn't seem to appreciate being waved."

        case .waveFixedObject(let item):
            "You can't wave \(item) around - it's not something you can pick up and wave."

        case .waveWhat:
            "Wave what?"

        case .wearWhat:
            "Wear what?"

        case .whatQuestion(let verb):
            "\(verb.capitalizedFirst) what?"

        case .wrongKey(let key, let lock):
            "\(key.capitalizedFirst) doesn't fit \(lock)."

        case .youAlreadyHaveThat:
            "You already have that."

        case .youAreCarrying:
            "You are carrying:"

        case .youAreEmptyHanded:
            "You are empty-handed."

        case .youArentHoldingThat:
            "You aren't holding that."

        case .youArentWearingAnything:
            "You aren't wearing anything."

        case .youCanOnlyActOnItems(let verb):
            "You can only \(verb) items."

        case .youCantDoThat:
            "You can't do that."

        case .youDontHaveThat:
            "You don't have that."

        case .youDropMultipleItems(let items):
            "You drop \(items)."

        case .youHaveIt:
            "You have it."

        case .youHearNothingUnusual:
            "You hear nothing unusual."

        case .youRemoveMultipleItems(let items):
            "You take off \(items)."

        case .youTakeMultipleItems(let items):
            "You take \(items)."

        // Additional action handler messages
        case .examineWhat:
            "Examine what?"

        case .moveWhat:
            "Move what?"

        case .pourWhat:
            "Pour what?"

        case .pourOn(let item, let target):
            "Pour the \(item) on what?"

        case .pourCannotPourThat:
            "You can't pour that."

        case .pourCannotPourOnThat:
            "You can't pour something on that."

        case .pourCannotPourItself(let item):
            "You can't pour the \(item) on itself."

        case .pourNotLiquid(let item):
            "You can't pour the \(item) - it's not a liquid."

        case .pourOnCharacter(let item, let character):
            "You pour the \(item) on the \(character). They are not pleased with this treatment."

        case .pourOnDevice(let item, let device):
            "You pour the \(item) on the \(device). This probably wasn't a good idea - electronic devices and liquids don't mix well."

        case .pourOnGeneric(let item, let target):
            "You pour the \(item) on the \(target). It drips off without much effect."

        case .putWhat:
            "Put what?"

        case .putOnWhat(let item):
            "Put the \(item) on what?"

        case .putCannotPutOnSelf:
            "You can't put something on itself."

        case .putCannotPutCircular(let item, let container, let preposition):
            "You can't put the \(item) on the \(container) because the \(container) is \(preposition) the \(item)."

        case .raiseWhat:
            "Raise what?"

        case .raiseCannotLift(let item):
            "You can't lift \(item)."

        case .readWhat:
            "Read what?"

        case .scriptAlreadyOn:
            "Scripting is already on."

        case .scriptNotOn:
            "Scripting is not currently on."

        case .smellCanOnlySmellItems:
            "You can only smell items directly."

        case .tellWhom:
            "Tell whom?"

        case .tellAboutWhat:
            "Tell about what?"

        case .tellCanOnlyTellCharacters:
            "You can only tell characters about things."

        case .tellCannotTellAbout(let character):
            "You can't tell the \(character) about anything."

        case .tieWhat:
            "Tie what?"

        case .tieCannotTieThat:
            "You can't tie that."

        case .tieCannotTieToThat:
            "You can't tie something to that."

        case .tieCannotTieToSelf(let item):
            "You can't tie the \(item) to itself."

        case .tieCannotTieLivingBeings:
            "You can't tie living beings together like that."

        case .tieNeedsSomethingToTieWith(let item):
            "You can't tie the \(item) without something to tie it with."

        case .tieNeedsSomethingToTieCharacterWith(let character):
            "You can't tie up the \(character) without something to tie them with."

        case .touchWhat:
            "Touch what?"

        case .turnOffWhat:
            "Turn off what?"

        case .turnOnWhat:
            "Turn on what?"

        case .alreadyOff:
            "It's already off."

        case .alreadyOn:
            "It's already on."

        case .cannotTurnOff:
            "You can't turn that off."

        case .cannotTurnOn:
            "You can't turn that on."

        case .unlockWhat:
            "Unlock what?"

        case .unlockWithWhat:
            "Unlock it with what?"

        case .unlockAlreadyUnlocked(let item):
            "The \(item) is already unlocked."

        case .youCanOnlyMoveItems:
            "You can only move items."

        case .youCanOnlyPutItemsOnThings:
            "You can only put items on things."

        case .youCanOnlyPutThingsOnSurfaces:
            "You can only put things on items (that are surfaces)."

        case .youCanOnlyRaiseItems:
            "You can only raise items."

        case .youCanOnlyReadItems:
            "You can only read items."

        case .youCanOnlySmellItems:
            "You can only smell items directly."

        case .youCanOnlyTasteItems:
            "You can only taste items."

        case .youCanOnlyTellCharacters:
            "You can only tell characters about things."

        case .youCanOnlyTouchItems:
            "You can only touch items."

        case .youCanOnlyTurnOffItems:
            "You can only turn off items."

        case .youCanOnlyTurnOnItems:
            "You can only turn on items."

        case .youCanOnlyUnlockItems:
            "You can only unlock items."

        case .youCanOnlyUseItemAsKey:
            "You can only use an item as a key."

        case .youCanOnlyWearItems:
            "You can only wear items."

        case .youCannotTakeFromNonContainer(let container):
            "You can't take things out of the \(container)."

        case .insertIntoWhat:
            "Insert into what?"
        case .insertWhere(let item):
            "Where do you want to insert \(item)?"

        case .insertHaveNothingToPut(let container):
            "You have nothing to put in the \(container)."
        }
    }
}
