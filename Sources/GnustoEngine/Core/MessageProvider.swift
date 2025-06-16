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
///
/// ## Thread Safety and `@unchecked Sendable`
///
/// This class uses `@unchecked Sendable` as a pragmatic exception to our general rule
/// against unchecked sendability. The decision is based on several factors:
///
/// **Why `@unchecked` is necessary:**
/// - `open class` cannot conform to `Sendable` naturally (subclasses could add mutable state)
/// - Swift's type system cannot verify sendability across arbitrary subclasses
///
/// **Why it's safe in this context:**
/// - Message providers are configured once at game startup
/// - After initialization, they operate as effectively read-only objects
/// - The only internal state (RNG) is used for deterministic message variation
/// - Usage is controlled within the engine's single-threaded game loop
///
/// **Critical requirements for subclasses:**
/// - **MUST NOT add mutable state** (use `let` properties only)
/// - **MUST NOT retain non-Sendable objects** beyond initialization
/// - **MUST ensure thread safety** if overriding methods that use shared state
/// - Consider the provider as immutable after `init()` completes
///
/// Alternative architectures (protocol-based, composition) were considered but imposed
/// significant API complexity for minimal safety benefit in this controlled usage pattern.
open class MessageProvider: @unchecked Sendable {
    public let languageCode: String

    private var randomNumberGenerator: RandomNumberGenerator

    public init(
        languageCode: String = "en",
        randomNumberGenerator: RandomNumberGenerator = SystemRandomNumberGenerator()
    ) {
        self.languageCode = languageCode
        self.randomNumberGenerator = randomNumberGenerator
    }

    open func actionHandlerInternalError(handler: String, details: String) -> String {
        "A strange buzzing sound indicates something is wrong with \(handler): \(details)"
    }

    open func actionHandlerMissingObjects(handler: String) -> String {
        "A strange buzzing sound indicates something is wrong with \(handler)."
    }

    open func alreadyHeld(item: String) -> String {
        "You already have \(item)."
    }

    open func alreadyLocked(item: String) -> String {
        "\(item.capitalizedFirst) is already locked."
    }

    open func alreadyOff() -> String {
        "It's already off."
    }

    open func alreadyOn() -> String {
        "It's already on."
    }

    open func ambiguity(text: String) -> String {
        text
    }

    open func ambiguousPronounReference(text: String) -> String {
        text
    }

    open func askAboutWhat() -> String {
        "Ask about what?"
    }

    open func askWhom() -> String {
        "Ask whom?"
    }

    open func attackNonCharacter(item: String) -> String {
        "I've known strange people, but fighting \(item)?"
    }

    open func attackWhat() -> String {
        "Attack what?"
    }

    open func attackWithBareHands(character: String) -> String {
        "Trying to attack \(character) with your bare hands is suicidal."
    }

    open func attackWithNonWeapon(character: String, weapon: String) -> String {
        "Trying to attack \(character) with \(weapon) is suicidal."
    }

    open func attackWithWeapon() -> String {
        "Let's hope it doesn't come to that."
    }

    open func badGrammar(text: String) -> String {
        text
    }

    open func blowGeneral() -> String {
        "You blow air around. Nothing happens."
    }

    open func blowOnFlammable(item: String) -> String {
        "Blowing on \(item) has no effect."
    }

    open func blowOnGeneric(item: String) -> String {
        "You blow on \(item). Nothing happens."
    }

    open func blowOnLightSource(item: String) -> String {
        "You blow on \(item), but it doesn't go out."
    }

    open func breatheResponse() -> String {
        oneOf(
            "You breathe thoughtfully, pondering the miracle of atmospheric composition.",
            "You inhale deeply, briefly grateful for the invention of oxygen.",
            "You take a breath, marveling at your lungs' stubborn refusal to give up.",
            "You breathe in life's very essence, which tastes faintly of confusion.",
            "You inhale slowly, appreciating the universe's decision to include breathable air.",
            "You take a breath, noting that it's roughly the same as the last one.",
            "You take a tentative breath, unsure whether the atmosphere is still working.",
            "You breathe in whatever passes for air around here.",
            "You take a breath, tasting hints of adventure and poor ventilation.",
            "You breathe with great purpose, although breathing tends to happen anyway.",
            "You were already doing that, but also you continue to breathe.",
            "'Breathe in the love... and blow out the jive...'",
        )
    }

    open func burnCannotBurn(item: String) -> String {
        "You can't burn \(item)."
    }

    open func burnToCatchFire(item: String) -> String {
        "\(item.capitalizedFirst) catches fire and burns to ashes."
    }

    open func burnWhat() -> String {
        "Burn what?"
    }

    open func cannotActOnThat(verb: String) -> String {
        "You can't \(verb) that."
    }

    open func cannotActWithThat(verb: String) -> String {
        "You can't \(verb) with that."
    }

    open func cannotAskAboutThat(item: String) -> String {
        "You can't ask \(item) about that."
    }

    open func cannotDeflate(item: String) -> String {
        "You can't deflate \(item)."
    }

    open func cannotDig(item: String) -> String {
        "You can't dig \(item)."
    }

    open func cannotDrink(item: String) -> String {
        "You can't drink \(item)."
    }

    open func cannotDrinkFromClosed(container: String) -> String {
        "You can't drink \(container)."
    }

    open func cannotEat(item: String) -> String {
        "You can't eat \(item)."
    }

    open func cannotEatFromClosed(container: String) -> String {
        "You can't eat from \(container)."
    }

    open func cannotEnter(item: String) -> String {
        "You can't enter \(item)."
    }

    open func cannotFillFrom() -> String {
        "You can't fill from that."
    }

    open func cannotInflate(item: String) -> String {
        "You can't inflate \(item)."
    }

    open func cannotPress(item: String) -> String {
        "You can't press \(item)."
    }

    open func cannotPull(item: String) -> String {
        "You can't pull \(item)."
    }

    open func cannotSmellThat() -> String {
        "You can't smell that."
    }

    open func cannotThrowYourself() -> String {
        "You can't throw yourself."
    }

    open func cannotTurnOff() -> String {
        "You can't turn that off."
    }

    open func cannotTurnOn() -> String {
        "You can't turn that on."
    }

    open func canOnlyActOnCharacters(verb: String) -> String {
        "You can only \(verb) other characters."
    }

    open func canOnlyActOnItems(verb: String) -> String {
        "You can only \(verb) items."
    }

    open func canOnlyDrinkLiquids() -> String {
        "You can only drink liquids."
    }

    open func canOnlyEatFood() -> String {
        "You can only eat food."
    }

    open func canOnlyEmptyContainers() -> String {
        "You can only empty containers."
    }

    open func canOnlyLookAtItems() -> String {
        "You can only look at items this way."
    }

    open func canOnlyLookInsideItems() -> String {
        "You can only look inside items."
    }

    open func canOnlyUseItemAsKey() -> String {
        "You can only use an item as a key."
    }

    open func chompContainer() -> String {
        "You'd probably break your teeth on that."
    }

    open func chompEdible(item: String) -> String {
        "You take a bite. It tastes like \(item)."
    }

    open func chompPerson() -> String {
        "That would be rude, not to mention dangerous."
    }

    open func chompResponse() -> String {
        oneOf(
            "You chomp your teeth together menacingly.",
            "You clench your fists and gnash your teeth.",
            "You chomp at the air for everyone to see.",
            "Sounds of your chomping echo around you.",
            "You practice your chomping technique.",
            "It feels good to get some chomping done.",
        )
    }

    open func chompTargetResponse(item: String) -> String {
        oneOf(
            "You give \(item) a tentative nibble. It tastes terrible.",
            "You chomp on \(item) experimentally. Not very satisfying.",
            "You bite \(item). Your teeth don't make much of an impression.",
            "You gnaw on \(item) briefly before giving up.",
            "You take a bite of \(item). It's not very appetizing.",
        )
    }

    open func chompWeapon() -> String {
        "That seems like a good way to hurt yourself."
    }

    open func chompWearable() -> String {
        "Chewing on clothing is not recommended for your dental health."
    }

    open func climbFailure(item: String) -> String {
        "You can't climb \(item)."
    }

    open func climbOnFailure(item: String) -> String {
        "You can't climb on \(item)."
    }

    open func climbOnWhat() -> String {
        "Climb on what?"
    }

    open func climbSuccess(item: String) -> String {
        "You climb \(item)."
    }

    open func climbWhat() -> String {
        "Climb what?"
    }

    open func closed() -> String {
        "Closed."
    }

    open func closedItem(item: String) -> String {
        "You close \(item)."
    }

    open func containerAlreadyEmpty(container: String) -> String {
        "\(container.capitalizedFirst) is already empty."
    }

    open func containerIsClosed(item: String) -> String {
        "\(item.capitalizedFirst) is closed."
    }

    open func containerIsOpen(item: String) -> String {
        "\(item.capitalizedFirst) is already open."
    }

    open func cryResponse() -> String {
        oneOf(
            "You shed a tear for the futility of it all.",
            "You weep quietly to yourself.",
            "You sob dramatically, and feel a little better.",
            "You cry a bit. There, there now.",
            "You bawl your eyes out, which is somewhat cathartic.",
            "You weep with the passion of a thousand sorrows.",
            "You cry like a baby. How embarrassing.",
            "You shed crocodile tears. Very convincing.",
            "You weep bitter tears.",
            "You break down and cry. After a bit the world seems a little brighter.",
        )
    }

    open func currentScore(score: Int, moves: Int) -> String {
        "Your score is \(score) in \(moves) moves."
    }

    open func curseResponse() -> String {
        oneOf(
            "You curse under your breath.",
            "You let out a string of colorful expletives.",
            "You swear like a sailor. Very cathartic.",
            "You curse the fates that brought you here.",
            "You damn everything in sight. You feel better now.",
            "You use language that would make your mother wash your mouth out with soap.",
            "You curse fluently in several languages.",
            "You swear with the passion of a thousand frustrated adventurers.",
        )
    }

    open func curseTargetResponse(item: String) -> String {
        oneOf(
            "You curse \(item) roundly. You feel a bit better.",
            "You let loose a string of expletives at \(item).",
            "You damn \(item) to the seven hells.",
            "You swear colorfully at \(item). How therapeutic!",
            "You curse \(item) with words that would make a sailor blush.",
        )
    }

    open func custom(message: String) -> String {
        message
    }

    open func cutNoSuitableTool() -> String {
        "You have no suitable cutting tool."
    }

    open func cutToolNotSharp(tool: String) -> String {
        "\(tool.capitalizedFirst) isn't sharp enough to cut anything."
    }

    open func cutWhat() -> String {
        "Cut what?"
    }

    open func cutWithAutoTool(item: String, tool: String) -> String {
        "You cut \(item) with \(tool)."
    }

    open func cutWithTool(item: String, tool: String) -> String {
        "You cut \(item) with \(tool)."
    }

    open func danceResponse() -> String {
        oneOf(
            "Dancing is forbidden.",
            "You dance an adorable little jig.",
            "You boogie down with surprising grace.",
            "You perform a modern interpretive dance.",
            "You dance like nobody's watching (which they aren't).",
            "You cut a rug with style and panache.",
            "You dance the dance of your people.",
            "You waltz around the area with imaginary partners.",
            "You break into spontaneous choreography.",
            "You dance with wild abandon. Bravo!",
            "Let all the children boogie.",
        )
    }

    open func debugRequiresObject() -> String {
        "DEBUG requires a direct object to examine."
    }

    open func deflateSuccess(item: String) -> String {
        "You deflate \(item)."
    }

    open func deflateWhat() -> String {
        "Deflate what?"
    }

    open func diggingBareHandsIneffective() -> String {
        "Digging with your bare hands is ineffective."
    }

    open func digWhat() -> String {
        "Dig what?"
    }

    open func digWithToolNothing(tool: String) -> String {
        "You dig with \(tool), but find nothing of interest."
    }

    open func directionIsBlocked(reason: String?) -> String {
        reason ?? "Something is blocking the way."
    }

    open func doorIsClosed(door: String) -> String {
        "\(door.capitalizedFirst) door is closed."
    }

    open func doorIsLocked(door: String) -> String {
        "\(door.capitalizedFirst) is locked."
    }

    open func drinkFromContainer(liquid: String, container: String) -> String {
        "You drink \(liquid) from \(container). Refreshing!"
    }

    open func drinkSuccess(item: String) -> String {
        "You drink \(item). It's quite refreshing."
    }

    open func drinkWhat() -> String {
        "Drink what?"
    }

    open func dropped() -> String {
        "Dropped."
    }

    open func droppedItem(item: String) -> String {
        "You drop \(item)."
    }

    open func eatFromContainer(food: String, container: String) -> String {
        "You eat \(food) from \(container). Delicious!"
    }

    open func eatSuccess(item: String) -> String {
        "You eat \(item). It's quite satisfying."
    }

    open func eatWhat() -> String {
        "Eat what?"
    }

    open func emptyInput() -> String {
        "I beg your pardon?"
    }

    open func emptySuccess(container: String, items: String, count: Int) -> String {
        "You empty \(container), and \(items) \(count == 1 ? "falls" : "fall") to the ground."
    }

    open func emptyWhat() -> String {
        "Empty what?"
    }

    open func examineWhat() -> String {
        "Examine what?"
    }

    open func examineYourself() -> String {
        "You are your usual self."
    }

    open func fillSuccess(container: String, source: String) -> String {
        "You fill \(container) from \(source)."
    }

    open func fillWhat() -> String {
        "Fill what?"
    }

    open func findWhat() -> String {
        "Find what?"
    }

    open func gameRestored() -> String {
        "Game restored."
    }

    open func gameSaved() -> String {
        "Game saved."
    }

    open func giggleResponse() -> String {
        oneOf(
            "You giggle softly to yourself.",
            "You chuckle with amusement.",
            "You snicker quietly. How mischievous!",
            "You titter like a schoolchild.",
            "You giggle uncontrollably. How embarrassing!",
            "You chuckle at some private joke.",
            "You giggle with glee.",
            "You snicker at the absurdity of it all.",
            "You chortle with delight.",
            "You giggle like a maniac. Very therapeutic.",
        )
    }

    open func giveToWhom() -> String {
        "Give to whom?"
    }

    open func giveWhat() -> String {
        "Give what?"
    }

    open func goodbye() -> String {
        "Goodbye!"
    }

    open func goWhere() -> String {
        "Go where?"
    }

    open func inflateSuccess(item: String) -> String {
        "You inflate \(item)."
    }

    open func inflateWhat() -> String {
        "Inflate what?"
    }

    open func insertHaveNothingToPut(container: String) -> String {
        "You have nothing to put in \(container)."
    }

    open func insertIntoWhat() -> String {
        "Insert into what?"
    }

    open func insertWhat() -> String {
        "Insert what?"
    }

    open func insertWhere(item: String) -> String {
        "Where do you want to insert \(item)?"
    }

    open func internalEngineError() -> String {
        "A strange buzzing sound indicates something is wrong."
    }

    open func internalParseError() -> String {
        "A strange buzzing sound indicates something is wrong."
    }

    open func invalidDirection() -> String {
        "You can't go that way."
    }

    open func invalidIndirectObject(object: String) -> String {
        "You can't use \(object) for that."
    }

    open func itemAlreadyClosed(item: String) -> String {
        "\(item.capitalizedFirst) is already closed."
    }

    open func itemAlreadyInflated(item: String) -> String {
        "\(item.capitalizedFirst) is already inflated."
    }

    open func itemAlreadyOpen(item: String) -> String {
        "\(item.capitalizedFirst) is already open."
    }

    open func itemGivenTo(item: String, recipient: String) -> String {
        "You give \(item) to \(recipient)."
    }

    open func itemInsertedInto(item: String, container: String) -> String {
        "You put \(item) into \(container)."
    }

    open func itemIsAlreadyWorn(item: String) -> String {
        "You are already wearing \(item)."
    }

    open func itemIsLocked(item: String) -> String {
        "\(item.capitalizedFirst) is locked."
    }

    open func itemIsNotWorn(item: String) -> String {
        "You are not wearing \(item)."
    }

    open func itemIsUnlocked(item: String) -> String {
        "\(item.capitalizedFirst) is already unlocked."
    }

    open func itemNotAccessible(item: String) -> String {
        "You can't see \(item)."
    }

    open func itemNotClosable(item: String) -> String {
        "\(item.capitalizedFirst) is not something you can close."
    }

    open func itemNotDroppable(item: String) -> String {
        "You can't drop \(item)."
    }

    open func itemNotEdible(item: String) -> String {
        "You can't eat \(item)."
    }

    open func itemNotHeld(item: String) -> String {
        "You aren't holding \(item)."
    }

    open func itemNotInContainer(item: String, container: String) -> String {
        "\(item.capitalizedFirst) isn't in \(container)."
    }

    open func itemNotInflated(item: String) -> String {
        "\(item.capitalizedFirst) is not inflated."
    }

    open func itemNotInScope(noun: String) -> String {
        "You can't see any '\(noun)' here."
    }

    open func itemNotLockable(item: String) -> String {
        "You can't lock \(item)."
    }

    open func itemNotOnSurface(item: String, surface: String) -> String {
        "\(item.capitalizedFirst) isn't on \(surface)."
    }

    open func itemNotOpenable(item: String) -> String {
        "You can't open \(item)."
    }

    open func itemNotReadable(item: String) -> String {
        "\(item.capitalizedFirst) isn't something you can read."
    }

    open func itemNotRemovable(item: String) -> String {
        "You can't remove \(item)."
    }

    open func itemNotTakable(item: String) -> String {
        "You can't take \(item)."
    }

    open func itemNotUnlockable(item: String) -> String {
        "You can't unlock \(item)."
    }

    open func itemNotWearable(item: String) -> String {
        "You can't wear \(item)."
    }

    open func itemTooLargeForContainer(item: String, container: String) -> String {
        "\(item.capitalizedFirst) won't fit in \(container)."
    }

    open func itsRightHere() -> String {
        "It's right here!"
    }

    open func jumpCharacter(character: String) -> String {
        "You can't jump \(character)."
    }

    open func jumpLargeObject(item: String) -> String {
        "You can't jump \(item)."
    }

    open func jumpResponse() -> String {
        oneOf(
            "You jump on the spot, fruitlessly.",
            "You jump up and down.",
            "You leap into the air.",
            "You bounce up and down.",
        )
    }

    open func kickCharacter(character: String) -> String {
        "I don't think \(character) would appreciate that."
    }

    open func kickLargeObject(item: String) -> String {
        "Ouch! You hurt your foot kicking \(item)."
    }

    open func kickWhat() -> String {
        "Kick what?"
    }

    open func kissCharacter(character: String) -> String {
        oneOf(
            "\(character.capitalizedFirst) doesn't seem particularly receptive to your affections."
        )
    }

    open func kissEnemy(enemy: String) -> String {
        oneOf(
            "You try to kiss \(enemy) mid-snarl, which seems poorly timed.",
            "You lean in for a kiss, but \(enemy) seems more interested in eating your face.",
            "You pucker up romantically, but \(enemy) responds with claws and teeth.",
            "You move in for a smooch, but apparently \(enemy) is not in the mood for romance.",
            "You lean in for a kiss while \(enemy) is actively trying to kill you.",
            "Reading the room incorrectly, you pucker up as \(enemy) in full attack mode.",
            "You give them a smooch, but \(enemy) remains disappointingly homicidal.",
            "You lean in for a kiss and narrowly avoid losing your nose.",
            "You pucker up and then immediately regret this tactical decision.",
        )
    }

    open func kissObject(item: String) -> String {
        oneOf(
            "You give \(item) a quick kiss, which fails to reveal anything significant.",
            "You kiss \(item) experimentally, but nothing remarkable happens.",
            "You plant a brief kiss on \(item), yet your lips learn nothing new.",
            "You kiss \(item) once, and think you detect trace amounts of indifference.",
            "You kiss it curiously, but your curiosity remains unsatisfied.",
            "You briefly kiss \(item), which offers no secrets to your lips.",
            "You give \(item) an investigative kiss. The investigation yields little.",
            "You plant a small kiss on \(item), learning nothing your eyes hadn't already told you.",
            "You plant a testing kiss on \(item), but the test results are inconclusive.",
        )
    }

    open func kissSelf() -> String {
        "You kiss yourself."
    }

    open func kissWhat() -> String {
        "Kiss what?"
    }

    open func knockOnClosedDoor(door: String) -> String {
        "You knock on \(door), but there's no answer."
    }

    open func knockOnContainer(container: String) -> String {
        "Knocking on \(container) produces a hollow sound."
    }

    open func knockOnGenericObject(item: String) -> String {
        "You knock on \(item), but nothing happens."
    }

    open func knockOnLockedDoor(door: String) -> String {
        "You knock on \(door), but nobody's home."
    }

    open func knockOnOpenDoor(door: String) -> String {
        "No need to knock, \(door) is already open."
    }

    open func knockOnWhat() -> String {
        "Knock on what?"
    }

    open func laughResponse() -> String {
        oneOf(
            "You cackle at the futility of everything.",
            "You chortle knowingly.",
            "You chuckle at the meaninglessness of it all.",
            "You giggle uncontrollably.",
            "You laugh at the absurdity of existence.",
            "You laugh boldly at the forces arrayed against you.",
            "You laugh brazenly at your predicament.",
            "You laugh courageously in spite of everything.",
            "You laugh defiantly at fate itself.",
            "You laugh fearlessly at the abyss.",
            "You laugh heroically at impossible circumstances.",
            "You laugh in the face of cosmic indifference.",
            "You laugh in the face of danger.",
            "You laugh in the face of overwhelming odds.",
            "You laugh in the face of your own mortality.",
            "You laugh with the hollow ring of someone who's given up.",
            "You laugh with the intensity of someone who's seen too much.",
            "You let out a mirthless chuckle.",
            "You snicker mischievously.",
            "You snort with amusement.",
            "You titter politely.",
            "You wheeze with laughter.",
        )
    }

    open func listenWhat() -> String {
        "Listen to what?"
    }

    open func lockSuccess(item: String) -> String {
        "\(item.capitalizedFirst) is now locked."
    }

    open func lockWhat() -> String {
        "Lock what?"
    }

    open func lockWithWhat() -> String {
        "Lock it with what?"
    }

    open func lookInsideWhat() -> String {
        "Look inside what?"
    }

    open func lookUnderWhat() -> String {
        "Look under what?"
    }

    open func maximumVerbosity() -> String {
        "Maximum verbosity. Full location descriptions will be shown every time you enter a location."
    }

    open func modifierMismatch(noun: String, modifiers: [String]) -> String {
        "I don't see any '\(modifiers.joined(separator: " ")) \(noun)' here."
    }

    open func moveWhat() -> String {
        "Move what?"
    }

    open func multipleObjectsNotSupported(verb: String) -> String {
        "The \(verb.uppercased()) command doesn't support multiple objects."
    }

    open func noLiquidInSource(source: String) -> String {
        "There's no liquid in \(source) to fill from."
    }

    open func noLiquidSourceAvailable() -> String {
        "There's no source of liquid here to fill from."
    }

    open func nothingHereToEnter() -> String {
        "There's nothing here to enter."
    }

    open func nothingHereToExamine() -> String {
        "There is nothing here to examine."
    }

    open func nothingHereToPush() -> String {
        "There is nothing here to push."
    }

    open func nothingHereToRemove() -> String {
        "There is nothing here to remove."
    }

    open func nothingHereToWear() -> String {
        "You have nothing to wear."
    }

    open func nothingSpecialAbout(item: String) -> String {
        "You see nothing special about \(item)."
    }

    open func nothingToDrinkIn(container: String) -> String {
        "There's nothing to drink in \(container)."
    }

    open func nothingToEatIn(container: String) -> String {
        "There's nothing to eat in \(container)."
    }

    open func nothingToTakeHere() -> String {
        "Nothing to take here."
    }

    open func nowDark() -> String {
        "You are plunged into darkness."
    }

    open func nowLit() -> String {
        "You can see your surroundings now."
    }

    open func opened(item: String) -> String {
        "You open \(item)."
    }

    open func openingRevealsContents(container: String, contents: String) -> String {
        "Opening \(container) reveals \(contents)."
    }

    open func parseUnknownVerb(verb: String) -> String {
        "I don't know the verb '\(verb)'."
    }

    open func playerCannotCarryMore() -> String {
        "Your hands are full."
    }

    open func pourCannotPourItself(item: String) -> String {
        "You can't pour \(item) on itself."
    }

    open func pourCannotPourOnThat() -> String {
        "You can't pour something on that."
    }

    open func pourCannotPourThat() -> String {
        "You can't pour that."
    }

    open func pourNotLiquid(item: String) -> String {
        "You can't pour \(item)."
    }

    open func pourOn(item: String, target: String) -> String {
        "Pour \(item) on what?"
    }

    open func pourOnCharacter(item: String, character: String) -> String {
        "You pour \(item) on \(character). They are not pleased with this treatment."
    }

    open func pourOnDevice(item: String, device: String) -> String {
        "You pour \(item) on \(device), which probably wasn't a good idea."
    }

    open func pourOnFireAndExtinguish(item: String, target: String) -> String {
        "You pour \(item) on \(target). The flames are extinguished with a hissing sound."
    }

    open func pourOnGeneric(item: String, target: String) -> String {
        "You pour \(item) on \(target)."
    }

    open func pourOnPlantAndRefresh(item: String, target: String) -> String {
        "You pour \(item) on \(target). It looks refreshed."
    }

    open func pourWhat() -> String {
        "Pour what?"
    }

    open func prerequisiteNotMet(message: String) -> String {
        message.isEmpty ? "You can't do that." : message
    }

    open func pressSuccess(item: String) -> String {
        "You press \(item)."
    }

    open func pressWhat() -> String {
        "Press what?"
    }

    open func pronounNotSet(pronoun: String) -> String {
        "I don't know what '\(pronoun)' refers to."
    }

    open func pronounRefersToOutOfScopeItem(pronoun: String) -> String {
        "You can't see what '\(pronoun)' refers to right now."
    }

    open func pullSuccess(item: String) -> String {
        "You pull \(item)."
    }

    open func pullWhat() -> String {
        "Pull what?"
    }

    open func pushSuccess(items: String) -> String {
        "You push \(items). Nothing happens."
    }

    open func pushWhat() -> String {
        "Push what?"
    }

    open func putCannotPutCircular(item: String, container: String, preposition: String) -> String {
        "You can't put \(item) on \(container) because \(container) is \(preposition) \(item)."
    }

    open func putCannotPutOnSelf() -> String {
        "You can't put something on itself."
    }

    open func putOnWhat(item: String) -> String {
        "Put \(item) on what?"
    }

    open func putWhat() -> String {
        "Put what?"
    }

    open func raiseCannotLift(item: String) -> String {
        "You can't lift \(item)."
    }

    open func raiseWhat() -> String {
        "Raise what?"
    }

    open func readWhat() -> String {
        "Read what?"
    }

    open func removeWhat() -> String {
        "Remove what?"
    }

    open func restoreFailed(error: String) -> String {
        "Restore failed: \(error)"
    }

    open func roomIsDark() -> String {
        "It is pitch black. You can't see a thing."
    }

    open func rubCharacter(character: String) -> String {
        "I don't think \(character) would appreciate being rubbed."
    }

    open func rubCleanItem(item: String) -> String {
        "You rub \(item). It feels smooth to the touch."
    }

    open func rubGenericObject(item: String) -> String {
        "You rub \(item), but nothing interesting happens."
    }

    open func rubLamp(item: String) -> String {
        "Rubbing \(item) doesn't seem to do anything. No djinn appears."
    }

    open func rubTakableObject(item: String) -> String {
        "You rub \(item). It feels smooth to the touch."
    }

    open func rubWhat() -> String {
        "Rub what?"
    }

    open func saveFailed(error: String) -> String {
        "Save failed: \(error)"
    }

    open func screamResponse() -> String {
        oneOf(
            "You scream at the top of your lungs. Very therapeutic!",
            "You shriek like a banshee.",
            "You let out a blood-curdling scream.",
            "You screech with primal fury.",
            "You howl like a wounded animal.",
            "You scream until your voice is hoarse.",
            "You emit a piercing shriek that echoes through the area.",
            "You scream with the passion of a thousand frustrated souls.",
            "You let loose a scream that would wake the dead.",
            "You scream so loudly that birds flee from nearby trees.",
        )
    }

    open func scriptAlreadyOn() -> String {
        "Scripting is already on."
    }

    open func scriptNotOn() -> String {
        "Scripting is not currently on."
    }

    open func shakeCharacter(character: String) -> String {
        "I don't think \(character) would appreciate being shaken."
    }

    open func shakeClosedContainer(container: String) -> String {
        "You shake \(container) and hear something rattling inside."
    }

    open func shakeFixedObject(item: String) -> String {
        "You can't shake \(item) - it's firmly in place."
    }

    open func shakeLiquidContainer(item: String) -> String {
        "You shake \(item) and hear liquid sloshing inside."
    }

    open func shakeOpenContainer(container: String) -> String {
        "You shake \(container), but nothing falls out."
    }

    open func shakeTakableObject(item: String) -> String {
        "You shake \(item) vigorously, but nothing happens."
    }

    open func shakeWhat() -> String {
        "Shake what?"
    }

    open func singResponse() -> String {
        oneOf(
            "You sing a little ditty. How delightful!",
            "You hum a tune under your breath.",
            "You warble melodiously. Very soothing.",
            "You croon like a nightingale.",
            "You sing off-key. Perhaps stick to adventuring.",
            "You belt out a rousing chorus. Bravo!",
            "You hum the theme from an old adventure game.",
            "You sing a song of your people.",
            "You vocalize with surprising talent.",
            "You sing so beautifully that birds gather to listen."
        )
    }

    open func smellCanOnlySmellItems() -> String {
        "You can only smell items directly."
    }

    open func smellNothingUnusual() -> String {
        "You smell nothing unusual."
    }

    open func smellsAverage() -> String {
        "That smells about average."
    }

    open func smellWhat() -> String {
        "Smell what?"
    }

    open func squeezeCharacter(character: String) -> String {
        "I don't think \(character) would appreciate being squeezed."
    }

    open func squeezeHardObject(item: String) -> String {
        "You squeeze \(item) as hard as you can, but it doesn't give."
    }

    open func squeezeLiquidContainer(item: String) -> String {
        "You squeeze \(item) and some of its contents ooze out."
    }

    open func squeezeSoftObject(item: String) -> String {
        "You squeeze \(item). It feels soft and yielding."
    }

    open func squeezeSponge(item: String) -> String {
        "You squeeze \(item) and water drips out."
    }

    open func squeezeWhat() -> String {
        "Squeeze what?"
    }

    open func stateValidationFailed() -> String {
        "A strange buzzing sound indicates something is wrong with the state validation."
    }

    open func suggestUsingToolToDig() -> String {
        "You could try using a tool to dig with."
    }

    open func taken() -> String {
        "Taken."
    }

    open func targetIsNotAContainer(item: String) -> String {
        "You can't put things in \(item)."
    }

    open func targetIsNotASurface(item: String) -> String {
        "You can't put things on \(item)."
    }

    open func tastesAverage() -> String {
        "That tastes about average."
    }

    open func tasteWhat() -> String {
        "Taste what?"
    }

    open func tellAboutWhat() -> String {
        "Tell about what?"
    }

    open func tellCannotTellAbout(character: String) -> String {
        "You can't tell \(character) about anything."
    }

    open func tellCanOnlyTellCharacters() -> String {
        "You can only tell characters about things."
    }

    open func tellWhom() -> String {
        "Tell whom?"
    }

    open func thereIsNothingHereToTake() -> String {
        "There is nothing here to take."
    }

    open func thinkAboutItem(item: String) -> String {
        "You contemplate \(item) for a bit, but nothing fruitful comes to mind."
    }

    open func thinkAboutLocation() -> String {
        "You ponder the location, but it remains stubbornly locational."
    }

    open func thinkAboutSelf() -> String {
        "Yes, yes, you're very important."
    }

    open func thinkAboutWhat() -> String {
        "Think about what?"
    }

    open func throwAtCharacter(item: String, character: String) -> String {
        "You throw \(item) at \(character)."
    }

    open func throwAtObject(item: String, target: String) -> String {
        "You throw \(item) at \(target). It bounces off harmlessly."
    }

    open func throwGeneral(item: String) -> String {
        "You throw \(item), and it falls to the ground."
    }

    open func throwWhat() -> String {
        "Throw what?"
    }

    open func tieCannotTieLivingBeings() -> String {
        "You can't tie living beings together like that."
    }

    open func tieCannotTieThat() -> String {
        "You can't tie that."
    }

    open func tieCannotTieToSelf(item: String) -> String {
        "You can't tie \(item) to itself."
    }

    open func tieCannotTieToThat() -> String {
        "You can't tie something to that."
    }

    open func tieKnotInRope(item: String) -> String {
        "You tie a knot in \(item)."
    }

    open func tieNeedsSomethingToTieCharacterWith(character: String) -> String {
        "You can't tie up \(character) without something to tie them with."
    }

    open func tieNeedsSomethingToTieWith(item: String) -> String {
        "You can't tie \(item) without something to tie it with."
    }

    open func tieWhat() -> String {
        "Tie what?"
    }

    open func timePasses() -> String {
        "Time passes."
    }

    open func toolMissing(tool: String) -> String {
        "You need \(tool) for that."
    }

    open func toolNotSuitableForDigging(tool: String) -> String {
        "\(tool.capitalizedFirst) isn't suitable for digging."
    }

    open func touchWhat() -> String {
        "Touch what?"
    }

    open func turnCharacter(character: String) -> String {
        "You can't turn \(character) around like an object."
    }

    open func turnDial(item: String) -> String {
        "You turn \(item). It clicks into a new position."
    }

    open func turnFixedObject(item: String) -> String {
        "\(item) doesn't seem to be designed to be turned."
    }

    open func turnHandle(item: String) -> String {
        "You turn \(item). It moves with a grinding sound."
    }

    open func turnKey(item: String) -> String {
        "You can't just turn \(item) by itself. You need to use it with something."
    }

    open func turnKnob(item: String) -> String {
        "You turn \(item). It clicks into a new position."
    }

    open func turnOffWhat() -> String {
        "Turn off what?"
    }

    open func turnOnWhat() -> String {
        "Turn on what?"
    }

    open func turnRegularObject(item: String) -> String {
        "You turn \(item) around in your hands, but nothing happens."
    }

    open func turnWhat() -> String {
        "Turn what?"
    }

    open func turnWheel(item: String) -> String {
        "You turn \(item). It rotates with some effort."
    }

    open func unknownEntity() -> String {
        "You can't see any such thing."
    }

    open func unknownNoun(noun: String) -> String {
        "I don't see any '\(noun)' here."
    }

    open func unknownVerb(verb: String) -> String {
        "I don't know how to \"\(verb)\" something."
    }

    open func unlockAlreadyUnlocked(item: String) -> String {
        "The \(item) is already unlocked."
    }

    open func unlockWhat() -> String {
        "Unlock what?"
    }

    open func unlockWithWhat() -> String {
        "Unlock it with what?"
    }

    open func waveCharacter(character: String) -> String {
        "You wave \(character) around, but it doesn't seem to appreciate being waved."
    }

    open func waveFixedObject(item: String) -> String {
        "You can't wave \(item) around - it's not something you can pick up and wave."
    }

    open func waveFlag(item: String) -> String {
        "You wave \(item) around. It's not particularly impressive."
    }

    open func waveMagicalItem(item: String) -> String {
        "You wave \(item) dramatically, but nothing magical happens."
    }

    open func waveWeapon(item: String) -> String {
        "You brandish \(item) menacingly."
    }

    open func waveWhat() -> String {
        "Wave what?"
    }

    open func wearWhat() -> String {
        "Wear what?"
    }

    open func whatQuestion(verb: String) -> String {
        "\(verb.capitalizedFirst) what?"
    }

    open func wrongKey(key: String, lock: String) -> String {
        "\(key.capitalizedFirst) doesn't fit \(lock)."
    }

    open func yellResponse() -> String {
        oneOf(
            "You bellow magnificently as the universe checks its watch.",
            "You bellow with the wild abandon of one who's given up on making sense.",
            "You bellow importantly, although the importance fails to materialize.",
            "You holler with misplaced confidence.",
            "You holler into the void. While the void doesn't reply, it does raise an eyebrow.",
            "You shout with gusto. The world remains studiously unimpressed.",
            "You shout with purpose, although the _exact_ purpose is unclear.",
            "You shout with the determination of one who's definitely onto something, probably.",
            "You yell as if the universe owes you money.",
            "You yell enthusiastically while reality politely ignores you",
            "You yell with conviction about nothing at all.",
        )
    }

    open func youAlreadyHaveThat() -> String {
        "You already have that."
    }

    open func youAreCarrying() -> String {
        "You are carrying:"
    }

    open func youAreEmptyHanded() -> String {
        "You are empty-handed."
    }

    open func youArentHoldingThat() -> String {
        "You aren't holding that."
    }

    open func youArentWearingAnything() -> String {
        "You aren't wearing anything."
    }

    open func youCannotTakeFromNonContainer(container: String) -> String {
        "You can't take things out of \(container)."
    }

    open func youCanOnlyActOnItems(verb: String) -> String {
        "You can only \(verb) items."
    }

    open func youCanOnlyMoveItems() -> String {
        "You can only move items."
    }

    open func youCanOnlyPutItemsOnThings() -> String {
        "You can only put items on things."
    }

    open func youCanOnlyPutThingsOnSurfaces() -> String {
        "You can only put things on items (that are surfaces)."
    }

    open func youCanOnlyRaiseItems() -> String {
        "You can only raise items."
    }

    open func youCanOnlyReadItems() -> String {
        "You can only read items."
    }

    open func youCanOnlySmellItems() -> String {
        "You can only smell items directly."
    }

    open func youCanOnlyTasteItems() -> String {
        "You can only taste items."
    }

    open func youCanOnlyTellCharacters() -> String {
        "You can only tell characters about things."
    }

    open func youCanOnlyTouchItems() -> String {
        "You can only touch items."
    }

    open func youCanOnlyTurnOffItems() -> String {
        "You can only turn off items."
    }

    open func youCanOnlyTurnOnItems() -> String {
        "You can only turn on items."
    }

    open func youCanOnlyUnlockItems() -> String {
        "You can only unlock items."
    }

    open func youCanOnlyUseItemAsKey() -> String {
        "You can only use an item as a key."
    }

    open func youCanOnlyWearItems() -> String {
        "You can only wear items."
    }

    open func youCantDoThat() -> String {
        "You can't do that."
    }

    open func youDontHaveThat() -> String {
        "You don't have that."
    }

    open func youDropMultipleItems(items: String) -> String {
        "You drop \(items)."
    }

    open func youHaveIt() -> String {
        "You have it."
    }

    open func youHearNothingUnusual() -> String {
        "You hear nothing unusual."
    }

    open func youRemoveMultipleItems(items: String) -> String {
        "You take off \(items)."
    }

    open func youTakeMultipleItems(items: String) -> String {
        "You take \(items)."
    }
}

extension MessageProvider {
    /// Returns one of a collection of responses at random.
    ///
    /// For testing purposes, a deterministic random number generator can specified when
    /// initializing the MessageProvider. By default the SystemRandomNumberGenerator is used.
    ///
    /// - Parameter responses: A collection of responses.
    /// - Returns: A randomly selected response.
    public func oneOf(_ responses: String...) -> String {
        responses.randomElement(using: &randomNumberGenerator) ?? internalEngineError()
    }
}
