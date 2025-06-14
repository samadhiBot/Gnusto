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

    public func message(for key: MessageKey) -> String {
        switch key {  // IMPORTANT: Keep cases alphabetized
        case .alreadyHeld(let item):
            "You already have \(item)."

        case .ambiguity(let text):
            text

        case .ambiguousPronounReference(let text):
            text

        case .badGrammar(let text):
            text

        case .closed:
            "Closed."

        case .closedItem(let item):
            "You close \(item)."

        case .containerIsClosed(let item):
            "\(item.capitalizedFirst) is closed."

        case .containerIsOpen(let item):
            "\(item.capitalizedFirst) is already open."

        case .custom(let message):
            message

        case .directionIsBlocked(let reason):
            reason ?? "Something is blocking the way."

        case .doorIsClosed(let direction):
            "The \(direction) door is closed."

        case .doorIsLocked(let door):
            "The \(door) is locked."

        case .dropped:
            "Dropped."

        case .droppedItem(let item):
            "You drop \(item)."

        case .emptyInput:
            "I beg your pardon?"

        case .giveToWhom:
            "Give to whom?"

        case .giveWhat:
            "Give what?"

        case .goWhere:
            "Go where?"

        case .insertIntoWhat:
            "Insert into what?"

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

        case .modifierMismatch(let noun, let modifiers):
            "I don't see any '\(modifiers.joined(separator: " ")) \(noun)' here."

        case .multipleObjectsNotSupported(let verb):
            "The \(verb.uppercased()) command doesn't support multiple objects."

        case .nothingSpecialAbout(let item):
            "You see nothing special about \(item)."

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

        case .pronounNotSet(let pronoun):
            "I don't know what '\(pronoun)' refers to."

        case .pronounRefersToOutOfScopeItem(let pronoun):
            "You can't see what '\(pronoun)' refers to right now."

        case .roomIsDark:
            "It is pitch black. You can't see a thing."

        case .stateValidationFailed:
            "A strange buzzing sound indicates something is wrong with the state validation."

        case .taken:
            "Taken."

        case .targetIsNotAContainer(let item):
            "You can't put things in \(item)."

        case .targetIsNotASurface(let item):
            "You can't put things on \(item)."

        case .thereIsNothingHereToTake:
            "There is nothing here to take."

        case .toolMissing(let tool):
            "You need \(tool) for that."

        case .unknownEntity:
            "You can't see any such thing."

        case .unknownNoun(let noun):
            "I don't see any '\(noun)' here."

        case .unknownVerb(let verb):
            "I don't know how to \"\(verb)\" something."

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

        case .youTakeMultipleItems(let items):
            "You take \(items)."

        case .youRemoveMultipleItems(let items):
            "You take off \(items)."

        // MARK: - Question prompts for missing objects

        case .askAboutWhat:
            "Ask about what?"

        case .askWhom:
            "Ask whom?"

        case .attackWhat:
            "Attack what?"

        case .burnWhat:
            "Burn what?"

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

        case .climbOnWhat:
            "Climb on what?"

        case .climbWhat:
            "Climb what?"

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

        case .cutWhat:
            "Cut what?"

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

        case .deflateWhat:
            "Deflate what?"

        case .breatheResponses:
            """
            You breathe in deeply, feeling refreshed.
            You take a slow, calming breath.
            The air fills your lungs. You're glad that you can breathe.
            You inhale deeply, then exhale slowly.
            You breathe in the love... and blow out the jive.
            """

        // MARK: - Action-specific responses

        case .attackNonCharacter(let item):
            "I've known strange people, but fighting a \(item)?"

        case .attackWithBareHands(let character):
            "Trying to attack a \(character) with your bare hands is suicidal."

        case .attackWithNonWeapon(let character, let weapon):
            "Trying to attack the \(character) with a \(weapon) is suicidal."

        case .attackWithWeapon:
            "Let's hope it doesn't come to that."

        case .blowOnLightSource(let item):
            "You blow on the \(item), but it doesn't go out."

        case .blowOnFlammable(let item):
            "Blowing on the \(item) has no effect."

        case .blowOnGeneric(let item):
            "You blow on the \(item). Nothing happens."

        case .blowGeneral:
            "You blow air around. Nothing happens."

        case .burnToCatchFire(let item):
            "The \(item) catches fire and burns to ashes."

        case .burnJokingResponse:
            "You must be joking."

        case .burnCannotBurn(let item):
            "You can't burn the \(item)."

        case .chompEdible(let item):
            "You take a bite. It tastes like \(item)."

        case .chompPerson:
            "That would be rude, not to mention dangerous."

        case .chompWearable:
            "Chewing on clothing is not recommended for your dental health."

        case .chompContainer:
            "You'd probably break your teeth on that."

        case .chompWeapon:
            "That seems like a good way to hurt yourself."

        case .climbSuccess(let item):
            "You climb \(item)."

        case .climbFailure(let item):
            "You can't climb \(item)."

        case .climbOnFailure(let item):
            "You can't climb on \(item)."

        case .cutWithTool(let item, let tool):
            "You cut the \(item) with the \(tool)."

        case .cutToolNotSharp(let tool):
            "The \(tool) isn't sharp enough to cut anything."

        case .cutWithAutoTool(let item, let tool):
            "You cut the \(item) with the \(tool)."

        case .cutNoSuitableTool:
            "You have no suitable cutting tool."

        // MARK: - Generic validation messages

        case .canOnlyActOnCharacters(let verb):
            "You can only \(verb) other characters."

        case .canOnlyActOnItems(let verb):
            "You can only \(verb) items."

        case .cannotActOnThat(let verb):
            "You can't \(verb) that."

        case .cannotActWithThat(let verb):
            "You can't \(verb) with that."

        case .debugRequiresObject:
            "DEBUG requires a direct object to examine."

        // MARK: - Engine error messages

        case .actionHandlerMissingObjects(let handler):
            "A strange buzzing sound indicates something is wrong with \(handler)."

        case .actionHandlerInternalError(let handler, let details):
            "A strange buzzing sound indicates something is wrong with \(handler): \(details)"

        // MARK: - Additional question prompts

        case .digWhat:
            "Dig what?"

        case .drinkWhat:
            "Drink what?"

        case .eatWhat:
            "Eat what?"

        case .emptyWhat:
            "Empty what?"

        case .fillWhat:
            "Fill what?"

        case .findWhat:
            "Find what?"

        case .inflateWhat:
            "Inflate what?"

        case .kickWhat:
            "Kick what?"

        case .kissWhat:
            "Kiss what?"

        case .knockOnWhat:
            "Knock on what?"

        case .lockWhat:
            "Lock what?"

        case .lockWithWhat:
            "Lock it with what?"

        case .lookInsideWhat:
            "Look inside what?"

        case .lookUnderWhat:
            "Look under what?"

        // MARK: - Specific validation messages

        case .cannotDeflate(let item):
            "You can't deflate the \(item)."

        case .itemNotInflated(let item):
            "The \(item) is not inflated."

        case .deflateSuccess(let item):
            "You deflate the \(item)."

        case .cannotInflate(let item):
            "You can't inflate the \(item)."

        case .itemAlreadyInflated(let item):
            "The \(item) is already inflated."

        case .inflateSuccess(let item):
            "You inflate the \(item)."

        case .cannotEnter(let item):
            "You can't enter the \(item)."

        case .cannotDig(let item):
            "You can't dig the \(item)."

        case .digWithToolNothing(let tool):
            "You dig with the \(tool), but find nothing of interest."

        case .toolNotSuitableForDigging(let tool):
            "The \(tool) isn't suitable for digging."

        case .suggestUsingToolToDig:
            "You could try using a tool to dig with."

        case .diggingBareHandsIneffective:
            "Digging with your bare hands is ineffective."

        case .containerAlreadyEmpty(let container):
            "The \(container) is already empty."

        case .emptySuccess(let container, let items, let count):
            "You empty the \(container). \(items.capitalizedFirst) \(count == 1 ? "falls" : "fall") to the ground."

        case .lockSuccess(let item):
            "The \(item) is now locked."

        case .pressWhat:
            "Press what?"

        case .pressSuccess(let item):
            "You press the \(item)."

        case .cannotPress(let item):
            "You can't press the \(item)."

        case .pullWhat:
            "Pull what?"

        case .pullSuccess(let item):
            "You pull the \(item)."

        case .cannotPull(let item):
            "You can't pull the \(item)."

        case .fillSuccess(let container, let source):
            "You fill the \(container) from the \(source)."

        case .noLiquidInSource(let source):
            "There's no liquid in the \(source) to fill from."

        case .noLiquidSourceAvailable:
            "There's no source of liquid here to fill from."

        case .nothingHereToExamine:
            "There is nothing here to examine."

        case .examineYourself:
            "You are your usual self."

        case .nothingToDrinkIn(let container):
            "There's nothing to drink in the \(container)."

        case .cannotDrink(let item):
            "You can't drink the \(item)."

        case .nothingToEatIn(let container):
            "There's nothing to eat in the \(container)."

        case .cannotEat(let item):
            "You can't eat the \(item)."

        case .nothingHereToEnter:
            "There's nothing here to enter."

        case .cannotFillFrom(_):
            "You can't fill from that."

        case .canOnlyUseItemAsKey:
            "You can only use an item as a key."

        case .canOnlyLookAtItems:
            "You can only look at items this way."

        case .canOnlyLookInsideItems:
            "You can only look inside items."

        case .canOnlyDrinkLiquids:
            "You can only drink liquids."

        case .canOnlyEatFood:
            "You can only eat food."

        case .canOnlyEmptyContainers:
            "You can only empty containers."

        case .jumpResponses:
            """
            You jump on the spot, fruitlessly.
            You jump up and down.
            You leap into the air.
            You bounce up and down.
            """

        case .jumpDangerous:
            "That would be extremely dangerous."

        case .jumpWater(let water):
            "You can't jump across the \(water)."

        case .jumpCharacter(let character):
            "You can't jump the \(character)."

        case .jumpSmallObject(let item):
            "You jump over the \(item) easily."

        case .jumpLargeObject(let item):
            "You can't jump the \(item)."

        case .pushWhat:
            "Push what?"

        case .removeWhat:
            "Remove what?"

        case .listenWhat:
            "Listen to what?"

        // MARK: - Basic action responses

        case .youHaveIt:
            "You have it."

        case .itsRightHere:
            "It's right here!"

        case .youHearNothingUnusual:
            "You hear nothing unusual."

        case .goodbye:
            "Goodbye!"

        case .gameSaved:
            "Game saved."

        case .gameRestored:
            "Game restored."

        case .alreadyLocked(let item):
            "The \(item) is already locked."

        case .timePasses:
            "Time passes."

        case .tastesAverage:
            "That tastes about average."

        case .smellNothingUnusual:
            "You smell nothing unusual."

        case .smellsAverage:
            "That smells about average."

        case .cannotSmellThat:
            "You can't smell that."

        case .cannotThrowYourself:
            "You can't throw yourself."

        case .currentScore(let score, let moves):
            "Your score is \(score) in \(moves) moves."

        case .saveFailed(let error):
            "Save failed: \(error)"

        case .restoreFailed(let error):
            "Restore failed: \(error)"

        case .wearWhat:
            "Wear what?"

        case .tasteWhat:
            "Taste what?"

        case .smellWhat:
            "Smell what?"

        case .nothingHereToPush:
            "There is nothing here to push."

        case .nothingHereToRemove:
            "There is nothing here to remove."

        case .nothingHereToWear:
            "There is nothing here to wear."

        case .pushSuccess(let items):
            "You push \(items). Nothing happens."
        }
    }
}
