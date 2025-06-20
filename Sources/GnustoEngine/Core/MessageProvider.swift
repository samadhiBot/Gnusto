import Logging

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

    /// Internal logger for engine messages, warnings, and errors.
    let logger = Logger(label: "com.samadhibot.Gnusto.MessageProvider")

    /// A random number generator used for response randomization.
    ///
    /// This generator is used for determining random events, NPC behaviors, game mechanics,
    /// and other probabilistic elements. The default implementation uses the system's
    /// random number generator.
    ///
    /// For testing purposes, you can provide a custom implementation that returns
    /// predetermined values to ensure consistent test results.
    private var randomNumberGenerator: RandomNumberGenerator

    public init(
        languageCode: String = "en",
        randomNumberGenerator: RandomNumberGenerator = SystemRandomNumberGenerator()
    ) {
        self.languageCode = languageCode
        self.randomNumberGenerator = randomNumberGenerator
    }

    open func actionHandlerInternalError(handler: String, details: String) -> String {
        logWarning("actionHandlerInternalError(handler: '\(handler)', details: '\(details)')")
        return "A strange buzzing sound indicates something is wrong with '\(handler)': '\(details)'"
    }

    open func actionHandlerMissingObjects(handler: String) -> String {
        logWarning("actionHandlerMissingObjects(handler: '\(handler)')")
        return "A strange buzzing sound indicates something is wrong with \(handler)."
    }

    open func alreadyHeld(item: String) -> String {
        log("alreadyHeld(item: '\(item)')")
        return "You already have \(item)."
    }

    open func alreadyLocked(item: String) -> String {
        log("alreadyLocked(item: '\(item)')")
        return "\(item.capitalizedFirst) is already locked."
    }

    open func alreadyOff() -> String {
        log("alreadyOff()")
        return "It's already off."
    }

    open func alreadyOn() -> String {
        log("alreadyOn()")
        return "It's already on."
    }

    open func ambiguity(text: String) -> String {
        log("ambiguity(text: '\(text)')")
        return text
    }

    open func ambiguousPronounReference(text: String) -> String {
        log("ambiguousPronounReference(text: '\(text)')")
        return text
    }

    open func askAboutWhat() -> String {
        log("askAboutWhat()")
        return "Ask about what?"
    }

    open func askWhom() -> String {
        log("askWhom()")
        return "Ask whom?"
    }

    open func attackNonCharacter(item: String) -> String {
        log("attackNonCharacter(item: '\(item)')")
        return "I've known strange people, but fighting \(item)?"
    }

    open func attackWhat() -> String {
        log("attackWhat()")
        return "Attack what?"
    }

    open func attackWithBareHands(character: String) -> String {
        log("attackWithBareHands(character: '\(character)')")
        return "Trying to attack \(character) with your bare hands is suicidal."
    }

    open func attackWithNonWeapon(character: String, weapon: String) -> String {
        log("attackWithNonWeapon(character: '\(character)', weapon: '\(weapon)')")
        return "Trying to attack \(character) with \(weapon) is suicidal."
    }

    open func attackWithWeapon() -> String {
        log("attackWithWeapon()")
        return "Let's hope it doesn't come to that."
    }

    open func badGrammar(text: String) -> String {
        log("badGrammar(text: '\(text)')")
        return text
    }

    open func blowGeneral() -> String {
        log("blowGeneral()")
        return "You blow the air around, but nothing interesting happens."
    }

    open func blowOnFlammable(item: String) -> String {
        log("blowOnFlammable(item: '\(item)')")
        return "Blowing on \(item) has no effect."
    }

    open func blowOnGeneric(item: String) -> String {
        log("blowOnGeneric(item: '\(item)')")
        return "You blow on \(item), but nothing interesting happens."
    }

    open func blowOnLightSource(item: String) -> String {
        log("blowOnLightSource(item: '\(item)')")
        return "You blow on \(item), but it doesn't go out."
    }

    open func breatheResponse() -> String {
        log("breatheResponse()")
        return oneOf(
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
        log("burnCannotBurn(item: '\(item)')")
        return "You can't burn \(item)."
    }

    open func burnToCatchFire(item: String) -> String {
        log("burnToCatchFire(item: '\(item)')")
        return "\(item.capitalizedFirst) catches fire and burns to ashes."
    }

    open func burnWhat() -> String {
        log("burnWhat()")
        return "Burn what?"
    }

    open func cannotActOnThat(verb: String) -> String {
        log("cannotActOnThat(verb: '\(verb)')")
        return "You can't \(verb) that."
    }

    open func cannotActWithThat(verb: String) -> String {
        log("cannotActWithThat(verb: '\(verb)')")
        return "You can't \(verb) with that."
    }

    open func cannotAskAboutThat(item: String) -> String {
        log("cannotAskAboutThat(item: '\(item)')")
        return "You can't ask \(item) about that."
    }

    open func cannotDeflate(item: String) -> String {
        log("cannotDeflate(item: '\(item)')")
        return "You can't deflate \(item)."
    }

    open func cannotDig(item: String) -> String {
        log("cannotDig(item: '\(item)')")
        return "You can't dig \(item)."
    }

    open func cannotDrink(item: String) -> String {
        log("cannotDrink(item: '\(item)')")
        return "You can't drink \(item)."
    }

    open func cannotDrinkFromClosed(container: String) -> String {
        log("cannotDrinkFromClosed(container: \(container))")
        return "You can't drink \(container)."
    }

    open func cannotEat(item: String) -> String {
        log("cannotEat(item: '\(item)')")
        return "You can't eat \(item)."
    }

    open func cannotEatFromClosed(container: String) -> String {
        log("cannotEatFromClosed(container: \(container))")
        return "You can't eat from \(container)."
    }

    open func cannotEnter(item: String) -> String {
        log("cannotEnter(item: '\(item)')")
        return "You can't enter \(item)."
    }

    open func cannotFillFrom() -> String {
        log("cannotFillFrom()")
        return "You can't fill from that."
    }

    open func cannotInflate(item: String) -> String {
        log("cannotInflate(item: '\(item)')")
        return "You can't inflate \(item)."
    }

    open func cannotPress(item: String) -> String {
        log("cannotPress(item: '\(item)')")
        return "You can't press \(item)."
    }

    open func cannotPull(item: String) -> String {
        log("cannotPull(item: '\(item)')")
        return "You can't pull \(item)."
    }

    open func cannotSmellThat() -> String {
        log("cannotSmellThat()")
        return "You can't smell that."
    }

    open func cannotTurnOff() -> String {
        log("cannotTurnOff()")
        return "You can't turn that off."
    }

    open func cannotTurnOn() -> String {
        log("cannotTurnOn()")
        return "You can't turn that on."
    }

    open func cannotVerbYourself(verb: String) -> String {
        log("cannotVerbYourself(verb: '\(verb)'")
        return "You can't \(verb) yourself."
    }

    open func canOnlyActOnCharacters(verb: String) -> String {
        log("canOnlyActOnCharacters(verb: '\(verb)')")
        return "You can only \(verb) other characters."
    }

    open func canOnlyActOnItems(verb: String) -> String {
        log("canOnlyActOnItems(verb: '\(verb)')")
        return "You can only \(verb) items."
    }

    open func canOnlyDrinkLiquids() -> String {
        log("canOnlyDrinkLiquids()")
        return "You can only drink liquids."
    }

    open func canOnlyEatFood() -> String {
        log("canOnlyEatFood()")
        return "You can only eat food."
    }

    open func canOnlyEmptyContainers() -> String {
        log("canOnlyEmptyContainers()")
        return "You can only empty containers."
    }

    open func canOnlyLookAtItems() -> String {
        log("canOnlyLookAtItems()")
        return "You can only look at items this way."
    }

    open func canOnlyLookInsideItems() -> String {
        log("canOnlyLookInsideItems()")
        return "You can only look inside items."
    }

    open func canOnlyUseItemAsKey() -> String {
        log("canOnlyUseItemAsKey()")
        return "You can only use an item as a key."
    }

    open func chompContainer() -> String {
        log("chompContainer()")
        return "You'd probably break your teeth on that."
    }

    open func chompEdible(item: String) -> String {
        log("chompEdible(item: '\(item)')")
        return "You take a bite. It tastes like \(item)."
    }

    open func chompPerson() -> String {
        log("chompPerson()")
        return "That would be rude, not to mention dangerous."
    }

    open func chompResponse() -> String {
        log("chompResponse()")
        return oneOf(
            "You chomp your teeth together menacingly.",
            "You clench your fists and gnash your teeth.",
            "You chomp at the air for everyone to see.",
            "Sounds of your chomping echo around you.",
            "You practice your chomping technique.",
            "It feels good to get some chomping done.",
        )
    }

    open func chompTargetResponse(item: String) -> String {
        log("chompTargetResponse(item: '\(item)')")
        return oneOf(
            "You give \(item) a tentative nibble. It tastes terrible.",
            "You chomp on \(item) experimentally. Not very satisfying.",
            "You bite \(item). Your teeth don't make much of an impression.",
            "You gnaw on \(item) briefly before giving up.",
            "You take a bite of \(item). It's not very appetizing.",
        )
    }

    open func chompWeapon() -> String {
        log("chompWeapon()")
        return "That seems like a good way to hurt yourself."
    }

    open func chompWearable() -> String {
        log("chompWearable()")
        return "Chewing on clothing is not recommended for your dental health."
    }

    open func climbFailure(item: String) -> String {
        log("climbFailure(item: '\(item)')")
        return "You can't climb \(item)."
    }

    open func climbOnFailure(item: String) -> String {
        log("climbOnFailure(item: '\(item)')")
        return "You can't climb on \(item)."
    }

    open func climbOnWhat() -> String {
        log("climbOnWhat()")
        return "Climb on what?"
    }

    open func climbSuccess(item: String) -> String {
        log("climbSuccess(item: '\(item)')")
        return "You climb \(item)."
    }

    open func climbWhat() -> String {
        log("climbWhat()")
        return "Climb what?"
    }

    open func closed() -> String {
        log("closed()")
        return "Closed."
    }

    open func closedItem(item: String) -> String {
        log("closedItem(item: '\(item)')")
        return "You close \(item)."
    }

    open func containerAlreadyEmpty(container: String) -> String {
        log("containerAlreadyEmpty(container: \(container))")
        return "\(container.capitalizedFirst) is already empty."
    }

    open func containerIsClosed(item: String) -> String {
        log("containerIsClosed(item: '\(item)')")
        return "\(item.capitalizedFirst) is closed."
    }

    open func containerIsOpen(item: String) -> String {
        log("containerIsOpen(item: '\(item)')")
        return "\(item.capitalizedFirst) is already open."
    }

    open func cryResponse() -> String {
        log("cryResponse()")
        return oneOf(
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
        log("currentScore(score: \(score), moves: \(moves))")
        return "Your score is \(score) in \(moves) moves."
    }

    open func curseResponse() -> String {
        log("curseResponse()")
        return oneOf(
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
        log("curseTargetResponse(item: '\(item)')")
        return oneOf(
            "You curse \(item) roundly. You feel a bit better.",
            "You let loose a string of expletives at \(item).",
            "You damn \(item) to the seven hells.",
            "You swear colorfully at \(item). How therapeutic!",
            "You curse \(item) with words that would make a sailor blush.",
        )
    }

    open func custom(message: String) -> String {
        log("custom(message: '\(message)')")
        return message
    }

    open func cutNoSuitableTool() -> String {
        log("cutNoSuitableTool()")
        return "You have no suitable cutting tool."
    }

    open func cutToolNotSharp(tool: String) -> String {
        log("cutToolNotSharp(tool: '\(tool)')")
        return "\(tool.capitalizedFirst) isn't sharp enough to cut anything."
    }

    open func cutWhat() -> String {
        log("cutWhat()")
        return "Cut what?"
    }

    open func cutWithAutoTool(item: String, tool: String) -> String {
        log("cutWithAutoTool(item: '\(item)', tool: '\(tool)')")
        return "You cut \(item) with \(tool)."
    }

    open func cutWithTool(item: String, tool: String) -> String {
        log("cutWithTool(item: '\(item)', tool: '\(tool)')")
        return "You cut \(item) with \(tool)."
    }

    open func danceResponse() -> String {
        log("danceResponse()")
        return oneOf(
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
        log("debugRequiresObject()")
        return "DEBUG requires a direct object to examine."
    }

    open func deflateSuccess(item: String) -> String {
        log("deflateSuccess(item: '\(item)')")
        return "You deflate \(item)."
    }

    open func deflateWhat() -> String {
        log("deflateWhat()")
        return "Deflate what?"
    }

    open func diggingBareHandsIneffective() -> String {
        log("diggingBareHandsIneffective()")
        return "Digging with your bare hands is ineffective."
    }

    open func digWhat() -> String {
        log("digWhat()")
        return "Dig what?"
    }

    open func digWithToolNothing(tool: String) -> String {
        log("digWithToolNothing(tool: '\(tool)')")
        return "You dig with '\(tool)', but find nothing of interest."
    }

    open func directionIsBlocked(reason: String?) -> String {
        log("\(reason ?? "Something is blocking the way.")")
        return reason ?? "Something is blocking the way."
    }

    open func doorIsClosed(door: String) -> String {
        log("doorIsClosed(door: '\(door)')")
        return "\(door.capitalizedFirst) door is closed."
    }

    open func doorIsLocked(door: String) -> String {
        log("doorIsLocked(door: '\(door)')")
        return "\(door.capitalizedFirst) is locked."
    }

    open func drinkFromContainer(liquid: String, container: String) -> String {
        log("drinkFromContainer(liquid: '\(liquid)', container: \(container))")
        return "You drink \(liquid) from \(container). Refreshing!"
    }

    open func drinkSuccess(item: String) -> String {
        log("drinkSuccess(item: '\(item)')")
        return "You drink \(item). It's quite refreshing."
    }

    open func drinkWhat() -> String {
        log("drinkWhat()")
        return "Drink what?"
    }

    open func dropped() -> String {
        log("dropped()")
        return "Dropped."
    }

    open func droppedItem(item: String) -> String {
        log("droppedItem(item: '\(item)')")
        return "You drop \(item)."
    }

    open func eatFromContainer(food: String, container: String) -> String {
        log("eatFromContainer(food: '\(food)', container: \(container))")
        return "You eat \(food) from \(container). Delicious!"
    }

    open func eatSuccess(item: String) -> String {
        log("eatSuccess(item: '\(item)')")
        return "You eat \(item). It's quite satisfying."
    }

    open func eatWhat() -> String {
        log("eatWhat()")
        return "Eat what?"
    }

    open func emptyInput() -> String {
        log("emptyInput()")
        return "I beg your pardon?"
    }

    open func emptySuccess(container: String, items: String, count: Int) -> String {
        log("emptySuccess(container: \(container), items: '\(items)', count: \(count))")
        return "You empty \(container), and \(items) \(count == 1 ? "falls" : "fall") to the ground."
    }

    open func emptyWhat() -> String {
        log("emptyWhat()")
        return "Empty what?"
    }

    open func examineWhat() -> String {
        log("examineWhat()")
        return "Examine what?"
    }

    open func examineYourself() -> String {
        log("examineYourself()")
        return "You are your usual self."
    }

    open func fillSuccess(container: String, source: String) -> String {
        log("fillSuccess(container: \(container), source: '\(source)')")
        return "You fill \(container) from \(source)."
    }

    open func fillWhat() -> String {
        log("fillWhat()")
        return "Fill what?"
    }

    open func findWhat() -> String {
        log("findWhat()")
        return "Find what?"
    }

    open func gameRestored() -> String {
        log("gameRestored()")
        return "Game restored."
    }

    open func gameSaved() -> String {
        log("gameSaved()")
        return "Game saved."
    }

    open func giggleResponse() -> String {
        log("giggleResponse()")
        return oneOf(
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
        log("giveToWhom()")
        return "Give to whom?"
    }

    open func giveWhat() -> String {
        log("giveWhat()")
        return "Give what?"
    }

    open func goodbye() -> String {
        log("goodbye()")
        return "Goodbye!"
    }

    open func goWhere() -> String {
        log("goWhere()")
        return "Go where?"
    }

    open func inflateSuccess(item: String) -> String {
        log("inflateSuccess(item: '\(item)')")
        return "You inflate \(item)."
    }

    open func inflateWhat() -> String {
        log("inflateWhat()")
        return "Inflate what?"
    }

    open func insertHaveNothingToPut(container: String) -> String {
        log("insertHaveNothingToPut(container: \(container))")
        return "You have nothing to put in \(container)."
    }

    open func insertIntoWhat() -> String {
        log("insertIntoWhat()")
        return "Insert into what?"
    }

    open func insertWhat() -> String {
        log("insertWhat()")
        return "Insert what?"
    }

    open func insertWhere(item: String) -> String {
        log("insertWhere(item: '\(item)')")
        return "Where do you want to insert \(item)?"
    }

    open func internalEngineError() -> String {
        logError("internalEngineError()")
        return "A strange buzzing sound indicates something is wrong."
    }

    open func internalParseError() -> String {
        logError("internalParseError()")
        return "A strange buzzing sound indicates something is wrong."
    }

    open func invalidDirection() -> String {
        log("invalidDirection()")
        return "You can't go that way."
    }

    open func invalidIndirectObject(object: String) -> String {
        log("invalidIndirectObject(object: '\(object)')")
        return "You can't use \(object) for that."
    }

    open func itemAlreadyClosed(item: String) -> String {
        log("itemAlreadyClosed(item: '\(item)')")
        return "\(item.capitalizedFirst) is already closed."
    }

    open func itemAlreadyInflated(item: String) -> String {
        log("itemAlreadyInflated(item: '\(item)')")
        return "\(item.capitalizedFirst) is already inflated."
    }

    open func itemAlreadyOpen(item: String) -> String {
        log("itemAlreadyOpen(item: '\(item)')")
        return "\(item.capitalizedFirst) is already open."
    }

    open func itemGivenTo(item: String, recipient: String) -> String {
        log("itemGivenTo(item: '\(item)', recipient: '\(recipient)')")
        return "You give \(item) to \(recipient)."
    }

    open func itemInsertedInto(item: String, container: String) -> String {
        log("itemInsertedInto(item: '\(item)', container: \(container))")
        return "You put \(item) into \(container)."
    }

    open func itemIsAlreadyWorn(item: String) -> String {
        log("itemIsAlreadyWorn(item: '\(item)')")
        return "You are already wearing \(item)."
    }

    open func itemIsLocked(item: String) -> String {
        log("itemIsLocked(item: '\(item)')")
        return "\(item.capitalizedFirst) is locked."
    }

    open func itemIsNotWorn(item: String) -> String {
        log("itemIsNotWorn(item: '\(item)')")
        return "You are not wearing \(item)."
    }

    open func itemIsUnlocked(item: String) -> String {
        log("itemIsUnlocked(item: '\(item)')")
        return "\(item.capitalizedFirst) is already unlocked."
    }

    open func itemNotAccessible(item: String) -> String {
        log("itemNotAccessible(item: '\(item)')")
        return "You can't see \(item)."
    }

    open func itemNotClosable(item: String) -> String {
        log("itemNotClosable(item: '\(item)')")
        return "You can't close \(item)."
    }

    open func itemNotDroppable(item: String) -> String {
        log("itemNotDroppable(item: '\(item)')")
        return "You can't drop \(item)."
    }

    open func itemNotEdible(item: String) -> String {
        log("itemNotEdible(item: '\(item)')")
        return "You can't eat \(item)."
    }

    open func itemNotHeld(item: String) -> String {
        log("itemNotHeld(item: '\(item)')")
        return "You aren't holding \(item)."
    }

    open func itemNotInContainer(item: String, container: String) -> String {
        log("itemNotInContainer(item: '\(item)', container: \(container))")
        return "\(item.capitalizedFirst) isn't in \(container)."
    }

    open func itemNotInflated(item: String) -> String {
        log("itemNotInflated(item: '\(item)')")
        return "\(item.capitalizedFirst) is not inflated."
    }

    open func itemNotInScope(noun: String) -> String {
        log("itemNotInScope(noun: '\(noun)')")
        return "You can't see any \(noun) here."
    }

    open func itemNotLockable(item: String) -> String {
        log("itemNotLockable(item: '\(item)')")
        return "You can't lock \(item)."
    }

    open func itemNotOnSurface(item: String, surface: String) -> String {
        log("itemNotOnSurface(item: '\(item)', surface: '\(surface)')")
        return "\(item.capitalizedFirst) isn't on \(surface)."
    }

    open func itemNotOpenable(item: String) -> String {
        log("itemNotOpenable(item: '\(item)')")
        return "You can't open \(item)."
    }

    open func itemNotReadable(item: String) -> String {
        log("itemNotReadable(item: '\(item)')")
        return "\(item.capitalizedFirst) isn't something you can read."
    }

    open func itemNotRemovable(item: String) -> String {
        log("itemNotRemovable(item: '\(item)')")
        return "You can't remove \(item)."
    }

    open func itemNotTakable(item: String) -> String {
        log("itemNotTakable(item: '\(item)')")
        return "You can't take \(item)."
    }

    open func itemNotUnlockable(item: String) -> String {
        log("itemNotUnlockable(item: '\(item)')")
        return "You can't unlock \(item)."
    }

    open func itemNotWearable(item: String) -> String {
        log("itemNotWearable(item: '\(item)')")
        return "You can't wear \(item)."
    }

    open func itemTooLargeForContainer(item: String, container: String) -> String {
        log("itemTooLargeForContainer(item: '\(item)', container: \(container))")
        return "\(item.capitalizedFirst) won't fit in \(container)."
    }

    open func itsRightHere() -> String {
        log("itsRightHere()")
        return "It's right here!"
    }

    open func jumpCharacter(character: String) -> String {
        log("jumpCharacter(character: '\(character)')")
        return "You can't jump \(character)."
    }

    open func jumpLargeObject(item: String) -> String {
        log("jumpLargeObject(item: '\(item)')")
        return "You can't jump \(item)."
    }

    open func jumpResponse() -> String {
        log("jumpResponse()")
        return oneOf(
            "You jump on the spot, fruitlessly.",
            "You jump up and down.",
            "You leap into the air.",
            "You bounce up and down.",
        )
    }

    open func kickCharacter(character: String) -> String {
        log("kickCharacter(character: '\(character)')")
        return "I don't think \(character) would appreciate that."
    }

    open func kickLargeObject(item: String) -> String {
        log("kickLargeObject(item: '\(item)')")
        return "Ouch! You hurt your foot kicking \(item)."
    }

    open func kickWhat() -> String {
        log("kickWhat()")
        return "Kick what?"
    }

    open func kissCharacter(character: String) -> String {
        log("kissCharacter(character: '\(character)')")
        return oneOf(
            "\(character.capitalizedFirst) doesn't seem particularly receptive to your affections."
        )
    }

    open func kissEnemy(enemy: String) -> String {
        log("kissEnemy(enemy: '\(enemy)')")
        return oneOf(
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
        log("kissObject(item: '\(item)')")
        return oneOf(
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
        log("kissSelf()")
        return "You kiss yourself."
    }

    open func kissWhat() -> String {
        log("kissWhat()")
        return "Kiss what?"
    }

    open func knockOnClosedDoor(door: String) -> String {
        log("knockOnClosedDoor(door: '\(door)')")
        return "You knock on '\(door)', but there's no answer."
    }

    open func knockOnContainer(container: String) -> String {
        log("knockOnContainer(container: \(container))")
        return "Knocking on \(container) produces a hollow sound."
    }

    open func knockOnGenericObject(item: String) -> String {
        log("knockOnGenericObject(item: '\(item)')")
        return "You knock on \(item), but nothing happens."
    }

    open func knockOnLockedDoor(door: String) -> String {
        log("knockOnLockedDoor(door: '\(door)')")
        return "You knock on '\(door)', but nobody's home."
    }

    open func knockOnOpenDoor(door: String) -> String {
        log("knockOnOpenDoor(door: '\(door)')")
        return "No need to knock, \(door) is already open."
    }

    open func knockOnWhat() -> String {
        log("knockOnWhat()")
        return "Knock on what?"
    }

    open func laughResponse() -> String {
        log("laughResponse()")
        return oneOf(
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
        log("listenWhat()")
        return "Listen to what?"
    }

    open func lockSuccess(item: String) -> String {
        log("lockSuccess(item: '\(item)')")
        return "\(item.capitalizedFirst) is now locked."
    }

    open func lockWhat() -> String {
        log("lockWhat()")
        return "Lock what?"
    }

    open func lockWithWhat() -> String {
        log("lockWithWhat()")
        return "Lock it with what?"
    }

    open func lookInsideWhat() -> String {
        log("lookInsideWhat()")
        return "Look inside what?"
    }

    open func lookUnderWhat() -> String {
        log("lookUnderWhat()")
        return "Look under what?"
    }

    open func maximumVerbosity() -> String {
        log("maximumVerbosity()")
        return """
            Maximum verbosity. Full location descriptions will
            be shown every time you enter a location.
            """
    }

    open func modifierMismatch(noun: String, modifiers: [String]) -> String {
        log("""
            modifierMismatch(noun: '\(noun)', \
            modifiers: '\(modifiers.joined(separator: "', '"))')
            """)
        return "You can't see any \(modifiers.joined(separator: " ")) \(noun) here."
    }

    open func moveWhat() -> String {
        log("moveWhat()")
        return "Move what?"
    }

    open func multipleObjectsNotSupported(verb: String) -> String {
        log("multipleObjectsNotSupported(verb: '\(verb)')")
        return "The \(verb.uppercased()) command doesn't support multiple objects."
    }

    open func noLiquidInSource(source: String) -> String {
        log("noLiquidInSource(source: '\(source)')")
        return "There's no liquid in \(source) to fill from."
    }

    open func noLiquidSourceAvailable() -> String {
        log("noLiquidSourceAvailable()")
        return "There's no source of liquid here to fill from."
    }

    open func nothingHereToEnter() -> String {
        log("nothingHereToEnter()")
        return "There's nothing here to enter."
    }

    open func nothingHereToExamine() -> String {
        log("nothingHereToExamine()")
        return "There is nothing here to examine."
    }

    open func nothingHereToPush() -> String {
        log("nothingHereToPush()")
        return "There is nothing here to push."
    }

    open func nothingHereToRemove() -> String {
        log("nothingHereToRemove()")
        return "There is nothing here to remove."
    }

    open func nothingHereToWear() -> String {
        log("nothingHereToWear()")
        return "You have nothing to wear."
    }

    open func nothingSpecialAbout(item: String) -> String {
        log("nothingSpecialAbout(item: '\(item)')")
        return "You see nothing special about \(item)."
    }

    open func nothingToDrinkIn(container: String) -> String {
        log("nothingToDrinkIn(container: \(container))")
        return "There's nothing to drink in \(container)."
    }

    open func nothingToEatIn(container: String) -> String {
        log("nothingToEatIn(container: \(container))")
        return "There's nothing to eat in \(container)."
    }

    open func nothingToTakeHere() -> String {
        log("nothingToTakeHere()")
        return "Nothing to take here."
    }

    open func nowDark() -> String {
        log("nowDark()")
        return "You are plunged into darkness."
    }

    open func nowLit() -> String {
        log("nowLit()")
        return "You can see your surroundings now."
    }

    open func opened(item: String) -> String {
        log("opened(item: '\(item)')")
        return "You open \(item)."
    }

    open func openingRevealsContents(container: String, contents: String) -> String {
        log("""
            openingRevealsContents(container: \(container), \
            contents: '\(contents)')
            """)
        return "Opening \(container) reveals \(contents)."
    }

    open func parseUnknownVerb(verb: String) -> String {
        log("parseUnknownVerb(verb: '\(verb)')")
        return "I don't know the verb '(verb)."
    }

    open func playerCannotCarryMore() -> String {
        log("playerCannotCarryMore()")
        return "Your hands are full."
    }

    open func pourCannotPourItself(item: String) -> String {
        log("pourCannotPourItself(item: '\(item)')")
        return "You can't pour \(item) on itself."
    }

    open func pourCannotPourOnThat() -> String {
        log("pourCannotPourOnThat()")
        return "You can't pour something on that."
    }

    open func pourCannotPourThat() -> String {
        log("pourCannotPourThat()")
        return "You can't pour that."
    }

    open func pourNotLiquid(item: String) -> String {
        log("pourNotLiquid(item: '\(item)')")
        return "You can't pour \(item)."
    }

    open func pourOn(item: String, target: String) -> String {
        log("pourOn(item: '\(item)', target: '\(target)')")
        return "Pour \(item) on what?"
    }

    open func pourOnCharacter(item: String, character: String) -> String {
        log("pourOnCharacter(item: '\(item)', character: '\(character)')")
        return "You pour \(item) on \(character). They are not pleased with this treatment."
    }

    open func pourOnDevice(item: String, device: String) -> String {
        log("pourOnDevice(item: '\(item)', device: '\(device)')")
        return "You pour \(item) on \(device), which probably wasn't a good idea."
    }

    open func pourOnFireAndExtinguish(item: String, target: String) -> String {
        log("pourOnFireAndExtinguish(item: '\(item)', target: '\(target)')")
        return """
            You pour \(item) on \(target). The flames
            are extinguished with a hissing sound.
            """
    }

    open func pourOnGeneric(item: String, target: String) -> String {
        log("pourOnGeneric(item: '\(item)', target: '\(target)')")
        return "You pour \(item) on \(target)."
    }

    open func pourOnPlantAndRefresh(item: String, target: String) -> String {
        log("pourOnPlantAndRefresh(item: '\(item)', target: '\(target)')")
        return "You pour \(item) on \(target). It looks refreshed."
    }

    open func pourWhat() -> String {
        log("pourWhat()")
        return "Pour what?"
    }

    open func prerequisiteNotMet(message: String) -> String {
        log("prerequisiteNotMet(message: '\(message)')")
        return message.isEmpty ? "You can't do that." : message
    }

    open func pressSuccess(item: String) -> String {
        log("pressSuccess(item: '\(item)')")
        return "You press \(item)."
    }

    open func pressWhat() -> String {
        log("pressWhat()")
        return "Press what?"
    }

    open func pronounNotSet(pronoun: String) -> String {
        log("pronounNotSet(pronoun: '\(pronoun)')")
        return "I don't know what \(pronoun) refers to."
    }

    open func pronounRefersToOutOfScopeItem(pronoun: String) -> String {
        log("pronounRefersToOutOfScopeItem(pronoun: '\(pronoun)')")
        return "You can't see what \(pronoun) refers to right now."
    }

    open func pullSuccess(item: String) -> String {
        log("pullSuccess(item: '\(item)')")
        return "You pull \(item)."
    }

    open func pullWhat() -> String {
        log("pullWhat()")
        return "Pull what?"
    }

    open func pushSuccess(items: String) -> String {
        log("pushSuccess(items: '\(items)')")
        return "You push \(items), but nothing interesting happens."
    }

    open func pushWhat() -> String {
        log("pushWhat()")
        return "Push what?"
    }

    open func putCannotPutCircular(
        item: String,
        container: String,
        preposition: String
    ) -> String {
        log("""
            putCannotPutCircular(item: '\(item)', container: \
            \(container), preposition: '\(preposition)')
            """)
        return """
            You can't put \(item) on \(container) because
            \(container) is \(preposition) \(item).
            """
    }

    open func putCannotPutOnSelf() -> String {
        log("putCannotPutOnSelf()")
        return "You can't put something on itself."
    }

    open func putOnWhat(item: String) -> String {
        log("putOnWhat(item: '\(item)')")
        return "Put \(item) on what?"
    }

    open func putWhat() -> String {
        log("putWhat()")
        return "Put what?"
    }

    open func raiseCannotLift(item: String) -> String {
        log("raiseCannotLift(item: '\(item)')")
        return "You can't lift \(item)."
    }

    open func raiseWhat() -> String {
        log("raiseWhat()")
        return "Raise what?"
    }

    open func readWhat() -> String {
        log("readWhat()")
        return "Read what?"
    }

    open func removeWhat() -> String {
        log("removeWhat()")
        return "Remove what?"
    }

    open func restoreFailed(error: String) -> String {
        log("restoreFailed(error: '\(error)')")
        return "Restore failed: '\(error)'"
    }

    open func roomIsDark() -> String {
        log("roomIsDark()")
        return "It is pitch black. You can't see a thing."
    }

    open func rubCharacter(character: String) -> String {
        log("rubCharacter(character: '\(character)')")
        return "I don't think \(character) would appreciate being rubbed."
    }

    open func rubCleanItem(item: String) -> String {
        log("rubCleanItem(item: '\(item)')")
        return "You rub \(item). It feels smooth to the touch."
    }

    open func rubGenericObject(item: String) -> String {
        log("rubGenericObject(item: '\(item)')")
        return "You rub \(item), but nothing interesting happens."
    }

    open func rubLamp(item: String) -> String {
        log("rubLamp(item: '\(item)')")
        return "Rubbing \(item) doesn't seem to do anything. No djinn appears."
    }

    open func rubTakableObject(item: String) -> String {
        log("rubTakableObject(item: '\(item)')")
        return "You rub \(item). It feels smooth to the touch."
    }

    open func rubWhat() -> String {
        log("rubWhat()")
        return "Rub what?"
    }

    open func saveFailed(error: String) -> String {
        log("saveFailed(error: '\(error)')")
        return "Save failed: '\(error)'"
    }

    open func screamResponse() -> String {
        log("screamResponse()")
        return oneOf(
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
        log("scriptAlreadyOn()")
        return "Scripting is already on."
    }

    open func scriptNotOn() -> String {
        log("scriptNotOn()")
        return "Scripting is not currently on."
    }

    open func shakeCharacter(character: String) -> String {
        log("shakeCharacter(character: '\(character)')")
        return "I don't think \(character) would appreciate being shaken."
    }

    open func shakeClosedContainer(container: String) -> String {
        log("shakeClosedContainer(container: \(container))")
        return "You shake \(container) and hear something rattling inside."
    }

    open func shakeFixedObject(item: String) -> String {
        log("shakeFixedObject(item: '\(item)')")
        return "You can't shake \(item) - it's firmly in place."
    }

    open func shakeLiquidContainer(item: String) -> String {
        log("shakeLiquidContainer(item: '\(item)')")
        return "You shake \(item) and hear liquid sloshing inside."
    }

    open func shakeOpenContainer(container: String) -> String {
        log("shakeOpenContainer(container: \(container))")
        return "You shake \(container), but nothing falls out."
    }

    open func shakeTakableObject(item: String) -> String {
        log("shakeTakableObject(item: '\(item)')")
        return "You shake \(item) vigorously, but nothing happens."
    }

    open func shakeWhat() -> String {
        log("shakeWhat()")
        return "Shake what?"
    }

    open func singResponse() -> String {
        log("singResponse()")
        return oneOf(
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
        log("smellCanOnlySmellItems()")
        return "You can only smell items directly."
    }

    open func smellNothingUnusual() -> String {
        log("smellNothingUnusual()")
        return "You smell nothing unusual."
    }

    open func smellsAverage() -> String {
        log("smellsAverage()")
        return "That smells about average."
    }

    open func smellWhat() -> String {
        log("smellWhat()")
        return "Smell what?"
    }

    open func squeezeCharacter(character: String) -> String {
        log("squeezeCharacter(character: '\(character)')")
        return "I don't think \(character) would appreciate being squeezed."
    }

    open func squeezeHardObject(item: String) -> String {
        log("squeezeHardObject(item: '\(item)')")
        return "You squeeze \(item) as hard as you can, but it doesn't give."
    }

    open func squeezeLiquidContainer(item: String) -> String {
        log("squeezeLiquidContainer(item: '\(item)')")
        return "You squeeze \(item) and some of its contents ooze out."
    }

    open func squeezeSoftObject(item: String) -> String {
        log("squeezeSoftObject(item: '\(item)')")
        return "You squeeze \(item). It feels soft and yielding."
    }

    open func squeezeSponge(item: String) -> String {
        log("squeezeSponge(item: '\(item)')")
        return "You squeeze \(item) and water drips out."
    }

    open func squeezeWhat() -> String {
        log("squeezeWhat()")
        return "Squeeze what?"
    }

    open func stateValidationFailed() -> String {
        logWarning("stateValidationFailed()")
        return "A strange buzzing sound indicates something is wrong with the state validation."
    }

    open func suggestUsingToolToDig() -> String {
        log("suggestUsingToolToDig()")
        return "You could try using a tool to dig with."
    }

    open func taken() -> String {
        log("taken()")
        return "Taken."
    }

    open func targetIsNotAContainer(item: String) -> String {
        log("targetIsNotAContainer(item: '\(item)')")
        return "You can't put things in \(item)."
    }

    open func targetIsNotASurface(item: String) -> String {
        log("targetIsNotASurface(item: '\(item)')")
        return "You can't put things on \(item)."
    }

    open func tastesAverage() -> String {
        log("tastesAverage()")
        return "That tastes about average."
    }

    open func tasteWhat() -> String {
        log("tasteWhat()")
        return "Taste what?"
    }

    open func tellAboutWhat() -> String {
        log("tellAboutWhat()")
        return "Tell about what?"
    }

    open func tellCannotTellAbout(character: String) -> String {
        log("tellCannotTellAbout(character: '\(character)')")
        return "You can't tell \(character) about anything."
    }

    open func tellCanOnlyTellCharacters() -> String {
        log("tellCanOnlyTellCharacters()")
        return "You can only tell characters about things."
    }

    open func tellWhom() -> String {
        log("tellWhom()")
        return "Tell whom?"
    }

    open func thereIsNothingHereToTake() -> String {
        log("thereIsNothingHereToTake()")
        return "There is nothing here to take."
    }

    open func thinkAboutItem(item: String) -> String {
        log("thinkAboutItem(item: '\(item)')")
        return "You contemplate \(item) for a bit, but nothing fruitful comes to mind."
    }

    open func thinkAboutLocation() -> String {
        log("thinkAboutLocation()")
        return "You ponder the location, but it remains stubbornly locational."
    }

    open func thinkAboutSelf() -> String {
        log("thinkAboutSelf()")
        return "Yes, yes, you're very important."
    }

    open func thinkAboutWhat() -> String {
        log("thinkAboutWhat()")
        return "Think about what?"
    }

    open func throwAtCharacter(item: String, character: String) -> String {
        log("throwAtCharacter(item: '\(item)', character: '\(character)')")
        return "You throw \(item) at \(character)."
    }

    open func throwAtObject(item: String, target: String) -> String {
        log("throwAtObject(item: '\(item)', target: '\(target)')")
        return "You throw \(item) at \(target). It bounces off harmlessly."
    }

    open func throwGeneral(item: String) -> String {
        log("throwGeneral(item: '\(item)')")
        return "You throw \(item), and it falls to the ground."
    }

    open func throwWhat() -> String {
        log("throwWhat()")
        return "Throw what?"
    }

    open func tieCannotTieLivingBeings() -> String {
        log("tieCannotTieLivingBeings()")
        return "You can't tie living beings together like that."
    }

    open func tieCannotTieThat() -> String {
        log("tieCannotTieThat()")
        return "You can't tie that."
    }

    open func tieCannotTieToSelf(item: String) -> String {
        log("tieCannotTieToSelf(item: '\(item)')")
        return "You can't tie \(item) to itself."
    }

    open func tieCannotTieToThat() -> String {
        log("tieCannotTieToThat()")
        return "You can't tie something to that."
    }

    open func tieKnotInRope(item: String) -> String {
        log("tieKnotInRope(item: '\(item)')")
        return "You tie a knot in \(item)."
    }

    open func tieNeedsSomethingToTieCharacterWith(character: String) -> String {
        log("tieNeedsSomethingToTieCharacterWith(character: '\(character)')")
        return "You can't tie up \(character) without something to tie them with."
    }

    open func tieNeedsSomethingToTieWith(item: String) -> String {
        log("tieNeedsSomethingToTieWith(item: '\(item)')")
        return "You can't tie \(item) without something to tie it with."
    }

    open func tieWhat() -> String {
        log("tieWhat()")
        return "Tie what?"
    }

    open func timePasses() -> String {
        log("timePasses()")
        return "Time passes."
    }

    open func toolMissing(tool: String) -> String {
        log("toolMissing(tool: '\(tool)')")
        return "You need \(tool) for that."
    }

    open func toolNotSuitableForDigging(tool: String) -> String {
        log("toolNotSuitableForDigging(tool: '\(tool)')")
        return "\(tool.capitalizedFirst) isn't suitable for digging."
    }

    open func touchWhat() -> String {
        log("touchWhat()")
        return "Touch what?"
    }

    open func turnCharacter(character: String) -> String {
        log("turnCharacter(character: '\(character)')")
        return "You can't turn \(character) around like an object."
    }

    open func turnDial(item: String) -> String {
        log("turnDial(item: '\(item)')")
        return "You turn \(item). It clicks into a new position."
    }

    open func turnFixedObject(item: String) -> String {
        log("turnFixedObject(item: '\(item)')")
        return "\(item) doesn't seem to be designed to be turned."
    }

    open func turnHandle(item: String) -> String {
        log("turnHandle(item: '\(item)')")
        return "You turn \(item). It moves with a grinding sound."
    }

    open func turnKey(item: String) -> String {
        log("turnKey(item: '\(item)')")
        return "You can't just turn \(item) by itself. You need to use it with something."
    }

    open func turnKnob(item: String) -> String {
        log("turnKnob(item: '\(item)')")
        return "You turn \(item). It clicks into a new position."
    }

    open func turnOffWhat() -> String {
        log("turnOffWhat()")
        return "Turn off what?"
    }

    open func turnOnWhat() -> String {
        log("turnOnWhat()")
        return "Turn on what?"
    }

    open func turnRegularObject(item: String) -> String {
        log("turnRegularObject(item: '\(item)')")
        return "You turn \(item) around in your hands, but nothing happens."
    }

    open func turnWhat() -> String {
        log("turnWhat()")
        return "Turn what?"
    }

    open func turnWheel(item: String) -> String {
        log("turnWheel(item: '\(item)')")
        return "You turn \(item). It rotates with some effort."
    }

    open func unknownEntity() -> String {
        log("unknownEntity()")
        return "You can't see any such thing."
    }

    open func unknownNoun(noun: String) -> String {
        log("unknownNoun(noun: '\(noun)')")
        return "You can't see any \(noun) here."
    }

    open func unknownVerb(verb: String) -> String {
        log("unknownVerb(verb: '\(verb)')")
        return "I don't know how to \"'\(verb)'\" something."
    }

    open func unlockAlreadyUnlocked(item: String) -> String {
        log("unlockAlreadyUnlocked(item: '\(item)')")
        return "The \(item) is already unlocked."
    }

    open func unlockWhat() -> String {
        log("unlockWhat()")
        return "Unlock what?"
    }

    open func unlockWithWhat() -> String {
        log("unlockWithWhat()")
        return "Unlock it with what?"
    }

    open func waveCharacter(character: String) -> String {
        log("waveCharacter(character: '\(character)')")
        return "You wave \(character) around, but it doesn't seem to appreciate being waved."
    }

    open func waveFixedObject(item: String) -> String {
        log("waveFixedObject(item: '\(item)')")
        return "You can't wave \(item) around - it's not something you can pick up and wave."
    }

    open func waveFlag(item: String) -> String {
        log("waveFlag(item: '\(item)')")
        return "You wave \(item) around. It's not particularly impressive."
    }

    open func waveMagicalItem(item: String) -> String {
        log("waveMagicalItem(item: '\(item)')")
        return "You wave \(item) dramatically, but nothing magical happens."
    }

    open func waveWeapon(item: String) -> String {
        log("waveWeapon(item: '\(item)')")
        return "You brandish \(item) menacingly."
    }

    open func waveWhat() -> String {
        log("waveWhat()")
        return "Wave what?"
    }

    open func wearWhat() -> String {
        log("wearWhat()")
        return "Wear what?"
    }

    open func whatQuestion(verb: String) -> String {
        log("whatQuestion(verb: '\(verb)')")
        return "\(verb.capitalizedFirst) what?"
    }

    open func wrongKey(key: String, lock: String) -> String {
        log("wrongKey(key: '\(key)', lock: '\(lock)')")
        return "\(key.capitalizedFirst) doesn't fit \(lock)."
    }

    open func yellResponse() -> String {
        log("yellResponse()")
        return oneOf(
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
        log("youAlreadyHaveThat()")
        return "You already have that."
    }

    open func youAreCarrying() -> String {
        log("youAreCarrying()")
        return "You are carrying:"
    }

    open func youAreEmptyHanded() -> String {
        log("youAreEmptyHanded()")
        return "You are empty-handed."
    }

    open func youArentHoldingThat() -> String {
        log("youArentHoldingThat()")
        return "You aren't holding that."
    }

    open func youArentWearingAnything() -> String {
        log("youArentWearingAnything()")
        return "You aren't wearing anything."
    }

    open func youCannotTakeFromNonContainer(container: String) -> String {
        log("youCannotTakeFromNonContainer(container: \(container))")
        return "You can't take things out of \(container)."
    }

    open func youCanOnlyActOnItems(verb: String) -> String {
        log("youCanOnlyActOnItems(verb: '\(verb)')")
        return "You can only \(verb) items."
    }

    open func youCanOnlyMoveItems() -> String {
        log("youCanOnlyMoveItems()")
        return "You can only move items."
    }

    open func youCanOnlyPutItemsOnThings() -> String {
        log("youCanOnlyPutItemsOnThings()")
        return "You can only put items on things."
    }

    open func youCanOnlyPutThingsOnSurfaces() -> String {
        log("youCanOnlyPutThingsOnSurfaces()")
        return "You can only put things on items (that are surfaces)."
    }

    open func youCanOnlyRaiseItems() -> String {
        log("youCanOnlyRaiseItems()")
        return "You can only raise items."
    }

    open func youCanOnlyReadItems() -> String {
        log("youCanOnlyReadItems()")
        return "You can only read items."
    }

    open func youCanOnlySmellItems() -> String {
        log("youCanOnlySmellItems()")
        return "You can only smell items directly."
    }

    open func youCanOnlyTasteItems() -> String {
        log("youCanOnlyTasteItems()")
        return "You can only taste items."
    }

    open func youCanOnlyTellCharacters() -> String {
        log("youCanOnlyTellCharacters()")
        return "You can only tell characters about things."
    }

    open func youCanOnlyTouchItems() -> String {
        log("youCanOnlyTouchItems()")
        return "You can only touch items."
    }

    open func youCanOnlyTurnOffItems() -> String {
        log("youCanOnlyTurnOffItems()")
        return "You can only turn off items."
    }

    open func youCanOnlyTurnOnItems() -> String {
        log("youCanOnlyTurnOnItems()")
        return "You can only turn on items."
    }

    open func youCanOnlyUnlockItems() -> String {
        log("youCanOnlyUnlockItems()")
        return "You can only unlock items."
    }

    open func youCanOnlyUseItemAsKey() -> String {
        log("youCanOnlyUseItemAsKey()")
        return "You can only use an item as a key."
    }

    open func youCanOnlyWearItems() -> String {
        log("youCanOnlyWearItems()")
        return "You can only wear items."
    }

    open func youCantDoThat() -> String {
        log("youCantDoThat()")
        return "You can't do that."
    }

    open func youDontHaveThat() -> String {
        log("youDontHaveThat()")
        return "You don't have that."
    }

    open func youDropMultipleItems(items: String) -> String {
        log("youDropMultipleItems(items: '\(items)')")
        return "You drop \(items)."
    }

    open func youHaveIt() -> String {
        log("youHaveIt()")
        return "You have it."
    }

    open func youHearNothingUnusual() -> String {
        log("youHearNothingUnusual()")
        return "You hear nothing unusual."
    }

    open func youRemoveMultipleItems(items: String) -> String {
        log("youRemoveMultipleItems(items: '\(items)')")
        return "You take off \(items)."
    }

    open func youSeeNo(item: String) -> String {
        log("youSeeNo(item: '\(item)')")
        return "You see no \(item) here."
    }

    open func youTakeMultipleItems(items: String) -> String {
        log("youTakeMultipleItems(items: '\(items)')")
        return "You take \(items)."
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

    func log(_ message: String) {
        logger.info(
            Logger.Message(
                stringLiteral: "\n🎯 \(message)"
            )
        )
    }

    func logError(_ message: String) {
        logger.error(
            Logger.Message(
                stringLiteral: "\n🔥 \(message)"
            )
        )
    }

    func logWarning(_ message: String) {
        logger.warning(
            Logger.Message(
                stringLiteral: "\n⚠️ \(message)"
            )
        )
    }
}
