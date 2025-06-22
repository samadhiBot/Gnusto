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
        output(
            "actionHandlerInternalError(handler: '\(handler)', details: '\(details)')",
            "A strange buzzing sound indicates something is wrong with '\(handler)': '\(details)'",
            .warning
        )
    }

    open func actionHandlerMissingObjects(handler: String) -> String {
        output(
            "actionHandlerMissingObjects(handler: '\(handler)')",
            "A strange buzzing sound indicates something is wrong with \(handler).",
            .warning
        )
    }

    open func alreadyHeld(item: String) -> String {
        output(
            "alreadyHeld(item: '\(item)')",
            "You already have \(item)."
        )
    }

    open func alreadyLocked(item: String) -> String {
        output(
            "alreadyLocked(item: '\(item)')",
            "\(item.capitalizedFirst) is already locked."
        )
    }

    open func alreadyOff() -> String {
        output(
            "alreadyOff()",
            "It's already off."
        )
    }

    open func alreadyOn() -> String {
        output(
            "alreadyOn()",
            "It's already on."
        )
    }

    open func ambiguity(text: String) -> String {
        output(
            "ambiguity(text: '\(text)')",
            text
        )
    }

    open func ambiguousPronounReference(text: String) -> String {
        output(
            "ambiguousPronounReference(text: '\(text)')",
            text
        )
    }

    open func askWhom() -> String {
        output(
            "askWhom()",
            "Ask whom?"
        )
    }

    open func attackNonCharacter(item: String) -> String {
        output(
            "attackNonCharacter(item: '\(item)')",
            "I've known strange people, but fighting \(item)?"
        )
    }

    open func attackWithBareHands(character: String) -> String {
        output(
            "attackWithBareHands(character: '\(character)')",
            "Trying to attack \(character) with your bare hands is suicidal."
        )
    }

    open func attackWithNonWeapon(character: String, weapon: String) -> String {
        output(
            "attackWithNonWeapon(character: '\(character)', weapon: '\(weapon)')",
            "Trying to attack \(character) with \(weapon) is suicidal."
        )
    }

    open func attackWithWeapon() -> String {
        output(
            "attackWithWeapon()",
            "Let's hope it doesn't come to that."
        )
    }

    open func badGrammar(text: String) -> String {
        output(
            "badGrammar(text: '\(text)')",
            "I don't understand that sentence."
        )
    }

    open func blowGeneral() -> String {
        output(
            "blowGeneral()",
            "You blow the air around, but nothing interesting happens."
        )
    }

    open func blowOnFlammable(item: String) -> String {
        output(
            "blowOnFlammable(item: '\(item)')",
            "Blowing on \(item) has no effect."
        )
    }

    open func blowOnGeneric(item: String) -> String {
        output(
            "blowOnGeneric(item: '\(item)')",
            "You blow on \(item), but nothing interesting happens."
        )
    }

    open func blowOnLightSource(item: String) -> String {
        output(
            "blowOnLightSource(item: '\(item)')",
            "You blow on \(item), but it doesn't go out."
        )
    }

    open func breatheResponse() -> String {
        output(
            "breatheResponse()",
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
        )
    }

    open func burnCannotBurn(item: String) -> String {
        output(
            "burnCannotBurn(item: '\(item)')",
            "You can't burn \(item)."
        )
    }

    open func burnToCatchFire(item: String) -> String {
        output(
            "burnToCatchFire(item: '\(item)')",
            "\(item.capitalizedFirst) catches fire and burns to ashes."
        )
    }

    open func cannotDoThat(verb: String) -> String {
        output(
            "cannotDoThat(verb: '\(verb)')",
            "You can't \(verb) that."
        )
    }

    open func cannotActWithThat(verb: String) -> String {
        output(
            "cannotActWithThat(verb: '\(verb)')",
            "You can't \(verb) with that."
        )
    }

    open func cannotAskAboutThat(item: String) -> String {
        output(
            "cannotAskAboutThat(item: '\(item)')",
            "You can't ask \(item) about that."
        )
    }

    open func cannotDeflate(item: String) -> String {
        output(
            "cannotDeflate(item: '\(item)')",
            "You can't deflate \(item)."
        )
    }

    open func cannotDig(item: String) -> String {
        output(
            "cannotDig(item: '\(item)')",
            "You can't dig \(item)."
        )
    }

    open func cannotDrink(item: String) -> String {
        output(
            "cannotDrink(item: '\(item)')",
            "You can't drink \(item)."
        )
    }

    open func cannotDrinkFromClosed(container: String) -> String {
        output(
            "cannotDrinkFromClosed(container: \(container))",
            "You can't drink \(container)."
        )
    }

    open func cannotEat(item: String) -> String {
        output(
            "cannotEat(item: '\(item)')",
            "You can't eat \(item)."
        )
    }

    open func cannotEatFromClosed(container: String) -> String {
        output(
            "cannotEatFromClosed(container: \(container))",
            "You can't eat from \(container)."
        )
    }

    open func cannotEnter(item: String) -> String {
        output(
            "cannotEnter(item: '\(item)')",
            "You can't enter \(item)."
        )
    }

    open func cannotFillFrom() -> String {
        output(
            "cannotFillFrom()",
            "You can't fill from that."
        )
    }

    open func cannotInflate(item: String) -> String {
        output(
            "cannotInflate(item: '\(item)')",
            "You can't inflate \(item)."
        )
    }

    open func cannotPress(item: String) -> String {
        output(
            "cannotPress(item: '\(item)')",
            "You can't press \(item)."
        )
    }

    open func cannotPull(item: String) -> String {
        output(
            "cannotPull(item: '\(item)')",
            "You can't pull \(item)."
        )
    }

    open func cannotPutItemInItself(item: String) -> String {
        output(
            "cannotPutItemInItself(item: '\(item)')",
            "You can't put \(item) inside itself."
        )
    }

    open func cannotPutContainerInContained(parent: String, child: String) -> String {
        output(
            "cannotPutContainerInContained(parent: '\(parent), child: '\(child)')",
            "You can't put \(parent) in \(child), because \(child) is inside \(parent)."
        )
    }

    open func cannotSmellThat() -> String {
        output(
            "cannotSmellThat()",
            "You can't smell that."
        )
    }

    open func cannotTurnOff() -> String {
        output(
            "cannotTurnOff()",
            "You can't turn that off."
        )
    }

    open func cannotTurnOn() -> String {
        output(
            "cannotTurnOn()",
            "You can't turn that on."
        )
    }

    open func cannotVerbYourself(verb: String) -> String {
        output(
            "cannotVerbYourself(verb: '\(verb)'",
            "You can't \(verb) yourself."
        )
    }

    open func canOnlyActOnCharacters(verb: String) -> String {
        output(
            "canOnlyActOnCharacters(verb: '\(verb)')",
            "You can only \(verb) other characters."
        )
    }

    open func canOnlyActOnItems(verb: String) -> String {
        output(
            "canOnlyActOnItems(verb: '\(verb)')",
            "You can only \(verb) items."
        )
    }

    open func canOnlyDrinkLiquids() -> String {
        output(
            "canOnlyDrinkLiquids()",
            "You can only drink liquids."
        )
    }

    open func canOnlyEatFood() -> String {
        output(
            "canOnlyEatFood()",
            "You can only eat food."
        )
    }

    open func canOnlyEmptyContainers() -> String {
        output(
            "canOnlyEmptyContainers()",
            "You can only empty containers."
        )
    }

    open func canOnlyLookAtItems() -> String {
        output(
            "canOnlyLookAtItems()",
            "You can only look at items this way."
        )
    }

    open func canOnlyLookInsideItems() -> String {
        output(
            "canOnlyLookInsideItems()",
            "You can only look inside items."
        )
    }

    open func canOnlyUseItemAsKey() -> String {
        output(
            "canOnlyUseItemAsKey()",
            "You can only use an item as a key."
        )
    }

    open func chompContainer() -> String {
        output(
            "chompContainer()",
            "You'd probably break your teeth on that."
        )
    }

    open func chompEdible(item: String) -> String {
        output(
            "chompEdible(item: '\(item)')",
            "You take a bite. It tastes like \(item)."
        )
    }

    open func chompPerson() -> String {
        output(
            "chompPerson()",
            "That would be rude, not to mention dangerous."
        )
    }

    open func chompResponse() -> String {
        output(
            "chompResponse()",
            oneOf(
                "You chomp your teeth together menacingly.",
                "You clench your fists and gnash your teeth.",
                "You chomp at the air for everyone to see.",
                "Sounds of your chomping echo around you.",
                "You practice your chomping technique.",
                "It feels good to get some chomping done.",
            )
        )
    }

    open func chompTargetResponse(item: String) -> String {
        output(
            "chompTargetResponse(item: '\(item)')",
            oneOf(
                "You give \(item) a tentative nibble. It tastes terrible.",
                "You chomp on \(item) experimentally. Not very satisfying.",
                "You bite \(item). Your teeth don't make much of an impression.",
                "You gnaw on \(item) briefly before giving up.",
                "You take a bite of \(item). It's not very appetizing.",
            )
        )
    }

    open func chompWeapon() -> String {
        output(
            "chompWeapon()",
            "That seems like a good way to hurt yourself."
        )
    }

    open func chompWearable() -> String {
        output(
            "chompWearable()",
            "Chewing on clothing is not recommended for your dental health."
        )
    }

    open func climbFailure(item: String) -> String {
        output(
            "climbFailure(item: '\(item)')",
            "You can't climb \(item)."
        )
    }

    open func climbOnFailure(item: String) -> String {
        output(
            "climbOnFailure(item: '\(item)')",
            "You can't climb on \(item)."
        )
    }

    open func climbSuccess(item: String) -> String {
        output(
            "climbSuccess(item: '\(item)')",
            "You climb \(item)."
        )
    }

    open func closed() -> String {
        output(
            "closed()",
            "Closed."
        )
    }

    open func closedItem(item: String) -> String {
        output(
            "closedItem(item: '\(item)')",
            "You close \(item)."
        )
    }

    open func containerAlreadyEmpty(container: String) -> String {
        output(
            "containerAlreadyEmpty(container: \(container))",
            "\(container.capitalizedFirst) is already empty."
        )
    }

    open func containerIsClosed(item: String) -> String {
        output(
            "containerIsClosed(item: '\(item)')",
            "\(item.capitalizedFirst) is closed."
        )
    }

    open func containerIsOpen(item: String) -> String {
        output(
            "containerIsOpen(item: '\(item)')",
            "\(item.capitalizedFirst) is already open."
        )
    }

    open func cryResponse() -> String {
        output(
            "cryResponse()",
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
        )
    }

    open func currentScore(score: Int, moves: Int) -> String {
        output(
            "currentScore(score: \(score), moves: \(moves))",
            "Your score is \(score) in \(moves) moves."
        )
    }

    open func curseResponse() -> String {
        output(
            "curseResponse()",
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
        )
    }

    open func curseTargetResponse(item: String) -> String {
        output(
            "curseTargetResponse(item: '\(item)')",
            oneOf(
                "You curse \(item) roundly. You feel a bit better.",
                "You let loose a string of expletives at \(item).",
                "You damn \(item) to the seven hells.",
                "You swear colorfully at \(item). How therapeutic!",
                "You curse \(item) with words that would make a sailor blush.",
            )
        )
    }

    open func custom(message: String) -> String {
        output(
            "custom(message: '\(message)')",
            message
        )
    }

    open func cutNoSuitableTool() -> String {
        output(
            "cutNoSuitableTool()",
            "You have no suitable cutting tool."
        )
    }

    open func cutToolNotSharp(tool: String) -> String {
        output(
            "cutToolNotSharp(tool: '\(tool)')",
            "\(tool.capitalizedFirst) isn't sharp enough to cut anything."
        )
    }

    open func cutWithAutoTool(item: String, tool: String) -> String {
        output(
            "cutWithAutoTool(item: '\(item)', tool: '\(tool)')",
            "You cut \(item) with \(tool)."
        )
    }

    open func cutWithTool(item: String, tool: String) -> String {
        output(
            "cutWithTool(item: '\(item)', tool: '\(tool)')",
            "You cut \(item) with \(tool)."
        )
    }

    open func danceResponse() -> String {
        output(
            "danceResponse()",
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
        )
    }

    open func debugRequiresObject() -> String {
        output(
            "debugRequiresObject()",
            "DEBUG requires a direct object to examine."
        )
    }

    open func deflateSuccess(item: String) -> String {
        output(
            "deflateSuccess(item: '\(item)')",
            "You deflate \(item)."
        )
    }

    open func diggingBareHandsIneffective() -> String {
        output(
            "diggingBareHandsIneffective()",
            "Digging with your bare hands is ineffective."
        )
    }

    open func digWithToolNothing(tool: String) -> String {
        output(
            "digWithToolNothing(tool: '\(tool)')",
            "You dig with '\(tool)', but find nothing of interest."
        )
    }

    open func directionIsBlocked(reason: String?) -> String {
        output(
            "\(reason ?? "Something is blocking the way.")",
            reason ?? "Something is blocking the way."
        )
    }

    open func doorIsClosed(door: String) -> String {
        output(
            "doorIsClosed(door: '\(door)')",
            "\(door.capitalizedFirst) door is closed."
        )
    }

    open func doorIsLocked(door: String) -> String {
        output(
            "doorIsLocked(door: '\(door)')",
            "\(door.capitalizedFirst) is locked."
        )
    }

    open func doWhat(verb: VerbID) -> String {
        output(
            "doWhat(verb: .\(verb))",
            "\(verb.rawValue.capitalizedFirst) what?"
        )
    }

    open func drinkFromContainer(liquid: String, container: String) -> String {
        output(
            "drinkFromContainer(liquid: '\(liquid)', container: \(container))",
            "You drink \(liquid) from \(container). Refreshing!"
        )
    }

    open func drinkSuccess(item: String) -> String {
        output(
            "drinkSuccess(item: '\(item)')",
            "You drink \(item). It's quite refreshing."
        )
    }

    open func dropped() -> String {
        output(
            "dropped()",
            "Dropped."
        )
    }

    open func droppedItem(item: String) -> String {
        output(
            "droppedItem(item: '\(item)')",
            "You drop \(item)."
        )
    }

    open func eatFromContainer(food: String, container: String) -> String {
        output(
            "eatFromContainer(food: '\(food)', container: \(container))",
            "You eat \(food) from \(container). Delicious!"
        )
    }

    open func eatSuccess(item: String) -> String {
        output(
            "eatSuccess(item: '\(item)')",
            "You eat \(item). It's quite satisfying."
        )
    }

    open func emptyInput() -> String {
        output(
            "emptyInput()",
            "I beg your pardon?"
        )
    }

    open func emptySuccess(container: String, items: String, count: Int) -> String {
        output(
            "emptySuccess(container: \(container), items: '\(items)', count: \(count))",
            "You empty \(container), and \(items) \(count == 1 ? "falls" : "fall") to the ground."
        )
    }

    open func examineYourself() -> String {
        output(
            "examineYourself()",
            "You are your usual self."
        )
    }

    open func fillSuccess(container: String, source: String) -> String {
        output(
            "fillSuccess(container: \(container), source: '\(source)')",
            "You fill \(container) from \(source)."
        )
    }

    open func gameRestored() -> String {
        output(
            "gameRestored()",
            "Game restored."
        )
    }

    open func gameSaved() -> String {
        output(
            "gameSaved()",
            "Game saved."
        )
    }

    open func giggleResponse() -> String {
        output(
            "giggleResponse()",
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
        )
    }

    open func giveToWhom() -> String {
        output(
            "giveToWhom()",
            "Give to whom?"
        )
    }

    open func goodbye() -> String {
        output(
            "goodbye()",
            "Goodbye!"
        )
    }

    open func goWhere() -> String {
        output(
            "goWhere()",
            "Where do you want to go?"
        )
    }

    open func inflateSuccess(item: String) -> String {
        output(
            "inflateSuccess(item: '\(item)')",
            "You inflate \(item)."
        )
    }

    open func insertHaveNothingToPut(container: String) -> String {
        output(
            "insertHaveNothingToPut(container: \(container))",
            "You have nothing to put in \(container)."
        )
    }

    open func insertWhere(item: String) -> String {
        output(
            "insertWhere(item: '\(item)')",
            "Where do you want to insert \(item)?"
        )
    }

    open func internalEngineError() -> String {
        output(
            "internalEngineError()",
            "A strange buzzing sound indicates something is wrong.",
            .error
        )
    }

    open func internalParseError() -> String {
        output(
            "internalParseError()",
            "A strange buzzing sound indicates something is wrong.",
            .error
        )
    }

    open func invalidDirection() -> String {
        output(
            "invalidDirection()",
            "You can't go that way."
        )
    }

    open func invalidIndirectObject(object: String) -> String {
        output(
            "invalidIndirectObject(object: '\(object)')",
            "You can't use \(object) for that."
        )
    }

    open func itemAlreadyClosed(item: String) -> String {
        output(
            "itemAlreadyClosed(item: '\(item)')",
            "\(item.capitalizedFirst) is already closed."
        )
    }

    open func itemAlreadyInflated(item: String) -> String {
        output(
            "itemAlreadyInflated(item: '\(item)')",
            "\(item.capitalizedFirst) is already inflated."
        )
    }

    open func itemAlreadyOpen(item: String) -> String {
        output(
            "itemAlreadyOpen(item: '\(item)')",
            "\(item.capitalizedFirst) is already open."
        )
    }

    open func itemGivenTo(item: String, recipient: String) -> String {
        output(
            "itemGivenTo(item: '\(item)', recipient: '\(recipient)')",
            "You give \(item) to \(recipient)."
        )
    }

    open func itemInsertedInto(item: String, container: String) -> String {
        output(
            "itemInsertedInto(item: '\(item)', container: \(container))",
            "You put \(item) into \(container)."
        )
    }

    open func itemIsAlreadyWorn(item: String) -> String {
        output(
            "itemIsAlreadyWorn(item: '\(item)')",
            "You are already wearing \(item)."
        )
    }

    open func itemIsLocked(item: String) -> String {
        output(
            "itemIsLocked(item: '\(item)')",
            "\(item.capitalizedFirst) is locked."
        )
    }

    open func itemIsNotWorn(item: String) -> String {
        output(
            "itemIsNotWorn(item: '\(item)')",
            "You aren't wearing \(item)."
        )
    }

    open func itemIsUnlocked(item: String) -> String {
        output(
            "itemIsUnlocked(item: '\(item)')",
            "\(item.capitalizedFirst) is already unlocked."
        )
    }

    open func itemNotAccessible(item: String) -> String {
        output(
            "itemNotAccessible(item: '\(item)')",
            "You can't see \(item)."
        )
    }

    open func itemNotClosable(item: String) -> String {
        output(
            "itemNotClosable(item: '\(item)')",
            "You can't close \(item)."
        )
    }

    open func itemNotDroppable(item: String) -> String {
        output(
            "itemNotDroppable(item: '\(item)')",
            "You can't drop \(item)."
        )
    }

    open func itemNotEdible(item: String) -> String {
        output(
            "itemNotEdible(item: '\(item)')",
            "You can't eat \(item)."
        )
    }

    open func itemNotHeld(item: String) -> String {
        output(
            "itemNotHeld(item: '\(item)')",
            "You aren't holding \(item)."
        )
    }

    open func itemNotInContainer(item: String, container: String) -> String {
        output(
            "itemNotInContainer(item: '\(item)', container: \(container))",
            "\(item.capitalizedFirst) isn't in \(container)."
        )
    }

    open func itemNotInflated(item: String) -> String {
        output(
            "itemNotInflated(item: '\(item)')",
            "\(item.capitalizedFirst) is not inflated."
        )
    }

    open func itemNotInScope(noun: String) -> String {
        output(
            "itemNotInScope(noun: '\(noun)')",
            "You can't see any \(noun) here."
        )
    }

    open func itemNotLockable(item: String) -> String {
        output(
            "itemNotLockable(item: '\(item)')",
            "You can't lock \(item)."
        )
    }

    open func itemNotOnSurface(item: String, surface: String) -> String {
        output(
            "itemNotOnSurface(item: '\(item)', surface: '\(surface)')",
            "\(item.capitalizedFirst) isn't on \(surface)."
        )
    }

    open func itemNotOpenable(item: String) -> String {
        output(
            "itemNotOpenable(item: '\(item)')",
            "You can't open \(item)."
        )
    }

    open func itemNotReadable(item: String) -> String {
        output(
            "itemNotReadable(item: '\(item)')",
            "\(item.capitalizedFirst) isn't something you can read."
        )
    }

    open func itemNotRemovable(item: String) -> String {
        output(
            "itemNotRemovable(item: '\(item)')",
            "You can't remove \(item)."
        )
    }

    open func itemNotTakable(item: String) -> String {
        output(
            "itemNotTakable(item: '\(item)')",
            "You can't take \(item)."
        )
    }

    open func itemNotUnlockable(item: String) -> String {
        output(
            "itemNotUnlockable(item: '\(item)')",
            "You can't unlock \(item)."
        )
    }

    open func itemNotWearable(item: String) -> String {
        output(
            "itemNotWearable(item: '\(item)')",
            "You can't wear \(item)."
        )
    }

    open func itemTooLargeForContainer(item: String, container: String) -> String {
        output(
            "itemTooLargeForContainer(item: '\(item)', container: \(container))",
            "\(item.capitalizedFirst) won't fit in \(container)."
        )
    }

    open func itsRightHere() -> String {
        output(
            "itsRightHere()",
            "It's right here!"
        )
    }

    open func jumpCharacter(character: String) -> String {
        output(
            "jumpCharacter(character: '\(character)')",
            "You can't jump \(character)."
        )
    }

    open func jumpLargeObject(item: String) -> String {
        output(
            "jumpLargeObject(item: '\(item)')",
            "You can't jump \(item)."
        )
    }

    open func jumpResponse() -> String {
        output(
            "jumpResponse()",
            oneOf(
                "You jump on the spot, fruitlessly.",
                "You jump up and down.",
                "You leap into the air.",
                "You bounce up and down.",
            )
        )
    }

    open func kickCharacter(character: String) -> String {
        output(
            "kickCharacter(character: '\(character)')",
            "I don't think \(character) would appreciate that."
        )
    }

    open func kickLargeObject(item: String) -> String {
        output(
            "kickLargeObject(item: '\(item)')",
            "Ouch! You hurt your foot kicking \(item)."
        )
    }

    open func kissCharacter(character: String) -> String {
        output(
            "kissCharacter(character: '\(character)')",
            oneOf(
                "\(character.capitalizedFirst) doesn't seem particularly receptive to your affections."
            )
        )
    }

    open func kissEnemy(enemy: String) -> String {
        output(
            "kissEnemy(enemy: '\(enemy)')",
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
        )
    }

    open func kissObject(item: String) -> String {
        output(
            "kissObject(item: '\(item)')",
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
        )
    }

    open func kissSelf() -> String {
        output(
            "kissSelf()",
            "You kiss yourself."
        )
    }

    open func knockOnClosedDoor(door: String) -> String {
        output(
            "knockOnClosedDoor(door: '\(door)')",
            "You knock on \(door), but there's no answer."
        )
    }

    open func knockOnContainer(container: String) -> String {
        output(
            "knockOnContainer(container: \(container))",
            "Knocking on \(container) produces a hollow sound."
        )
    }

    open func knockOnGenericObject(item: String) -> String {
        output(
            "knockOnGenericObject(item: '\(item)')",
            "You knock on \(item), but nothing happens."
        )
    }

    open func knockOnLockedDoor(door: String) -> String {
        output(
            "knockOnLockedDoor(door: '\(door)')",
            "You knock on \(door), but nobody's home."
        )
    }

    open func knockOnOpenDoor(door: String) -> String {
        output(
            "knockOnOpenDoor(door: '\(door)')",
            "No need to knock, \(door) is already open."
        )
    }

    open func knockOnWhat() -> String {
        output(
            "knockOnWhat()",
            "Knock on what?"
        )
    }

    open func laughResponse() -> String {
        output(
            "laughResponse()",
            oneOf(
                "You cackle at the futility of everything.",
                "You chortle knowingly.",
                "You chuckle at the meaninglessness of it all.",
                "You giggle uncontrollably.",
                "You laugh at the absurdity of existence.",
                "You laugh boldly at the forces arrayed against you.",
                "You laugh brazenly at your predicament.",
                "You laugh courageously in spite of everything.",
                "You laugh defiantly at Fate itself.",
                "You laugh fearlessly at the abyss.",
                "You laugh heroically at your impossible circumstances.",
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
        )
    }

    open func lockSuccess(item: String) -> String {
        output(
            "lockSuccess(item: '\(item)')",
            "\(item.capitalizedFirst) is now locked."
        )
    }

    open func lockWithWhat(item: String) -> String {
        output(
            "lockWithWhat(item: \(item))",
            "Lock \(item) with what?"
        )
    }

    open func maximumVerbosity() -> String {
        output(
            "maximumVerbosity()",
            """
            Maximum verbosity. Full location descriptions will
            be shown every time you enter a location.
            """
        )
    }

    open func modifierMismatch(noun: String, modifiers: [String]) -> String {
        output(
            """
            modifierMismatch(noun: '\(noun)', \
            modifiers: '\(modifiers.joined(separator: "', '"))')
            """,
            "You can't see any \(modifiers.joined(separator: " ")) \(noun) here."
        )
    }

    open func multipleObjectsNotSupported(verb: String) -> String {
        output(
            "multipleObjectsNotSupported(verb: '\(verb)')",
            "The \(verb.uppercased()) command doesn't support multiple objects."
        )
    }

    open func noLiquidInSource(source: String) -> String {
        output(
            "noLiquidInSource(source: '\(source)')",
            "There's no liquid in \(source) to fill from."
        )
    }

    open func noLiquidSourceAvailable() -> String {
        output(
            "noLiquidSourceAvailable()",
            "There's no source of liquid here to fill from."
        )
    }

    open func nothingHereToEnter() -> String {
        output(
            "nothingHereToEnter()",
            "There's nothing here to enter."
        )
    }

    open func nothingHereToExamine() -> String {
        output(
            "nothingHereToExamine()",
            "There is nothing here to examine."
        )
    }

    open func nothingHereToPush() -> String {
        output(
            "nothingHereToPush()",
            "There is nothing here to push."
        )
    }

    open func nothingHereToRemove() -> String {
        output(
            "nothingHereToRemove()",
            "There is nothing here to remove."
        )
    }

    open func nothingHereToWear() -> String {
        output(
            "nothingHereToWear()",
            "You have nothing to wear."
        )
    }

    open func nothingOfInterestUnder(item: String) -> String {
        output(
            "nothingOfInterestUnder(item: '\(item)')",
            "You find nothing of interest under \(item)."
        )
    }

    open func nothingSpecialAbout(item: String) -> String {
        output(
            "nothingSpecialAbout(item: '\(item)')",
            "You see nothing special about \(item)."
        )
    }

    open func nothingToDrinkIn(container: String) -> String {
        output(
            "nothingToDrinkIn(container: \(container))",
            "There's nothing to drink in \(container)."
        )
    }

    open func nothingToEatIn(container: String) -> String {
        output(
            "nothingToEatIn(container: \(container))",
            "There's nothing to eat in \(container)."
        )
    }

    open func nothingToTakeHere() -> String {
        output(
            "nothingToTakeHere()",
            "Nothing to take here."
        )
    }

    open func nowDark() -> String {
        output(
            "nowDark()",
            "You are plunged into darkness."
        )
    }

    open func nowLit() -> String {
        output(
            "nowLit()",
            "You can see your surroundings now."
        )
    }

    open func opened(item: String) -> String {
        output(
            "opened(item: '\(item)')",
            "You open \(item)."
        )
    }

    open func openingRevealsContents(container: String, contents: String) -> String {
        output(
            "openingRevealsContents(container: \(container), contents: '\(contents)')",
            "Opening \(container) reveals \(contents)."
        )
    }

    open func parseUnknownVerb(verb: String) -> String {
        output(
            "parseUnknownVerb(verb: '\(verb)')",
            "I don't know the verb '\(verb)'."
        )
    }

    open func playerCannotCarryMore() -> String {
        output(
            "playerCannotCarryMore()",
            "Your hands are full."
        )
    }

    open func pourCannotPourItself(item: String) -> String {
        output(
            "pourCannotPourItself(item: '\(item)')",
            "You can't pour \(item) on itself."
        )
    }

    open func pourCannotPourItemOnThat(item: String) -> String {
        output(
            "pourCannotPourItemOnThat(item: \(item))",
            "You can't pour \(item) on that."
        )
    }

    open func pourCannotPourThat() -> String {
        output(
            "pourCannotPourThat()",
            "You can't pour that."
        )
    }

    open func pourItemOnWhat(item: String) -> String {
        output(
            "pourItemOnWhat(item: '\(item)'",
            "Pour \(item) on what?"
        )
    }

    open func pourItemOn(item: String, target: String) -> String {
        output(
            "pourItemOn(item: '\(item)', target: '\(target)')",
            "You pour \(item) on \(target)."
        )
    }

    open func prerequisiteNotMet(message: String) -> String {
        output(
            "prerequisiteNotMet(message: '\(message)')",
            message.isEmpty ? "You can't do that." : message
        )
    }

    open func pressSuccess(item: String) -> String {
        output(
            "pressSuccess(item: '\(item)')",
            "You press \(item)."
        )
    }

    open func pronounNotSet(pronoun: String) -> String {
        output(
            "pronounNotSet(pronoun: '\(pronoun)')",
            "I don't know what \(pronoun) refers to."
        )
    }

    open func pronounRefersToOutOfScopeItem(pronoun: String) -> String {
        output(
            "pronounRefersToOutOfScopeItem(pronoun: '\(pronoun)')",
            "You can't see what \(pronoun) refers to right now."
        )
    }

    open func pullSuccess(item: String) -> String {
        output(
            "pullSuccess(item: '\(item)')",
            "You pull \(item)."
        )
    }

    open func pushSuccess(items: String) -> String {
        output(
            "pushSuccess(items: '\(items)')",
            "You push \(items), but nothing interesting happens."
        )
    }

    open func putCannotPutCircular(
        item: String,
        container: String,
        preposition: String
    ) -> String {
        output(
            """
            putCannotPutCircular(item: '\(item)', container: \
            \(container), preposition: '\(preposition)')
            """,
            """
            You can't put \(item) on \(container) because
            \(container) is \(preposition) \(item).
            """
        )
    }

    open func putCannotPutOnSelf() -> String {
        output(
            "putCannotPutOnSelf()",
            "You can't put something on itself."
        )
    }

    open func putOnWhat(item: String) -> String {
        output(
            "putOnWhat(item: '\(item)')",
            "Put \(item) on what?"
        )
    }

    open func putWhatOn(item: String) -> String {
        output(
            "putWhatOn(item: '\(item)')",
            "Put what on \(item)?"
        )
    }

    open func raiseCannotLift(item: String) -> String {
        output(
            "raiseCannotLift(item: '\(item)')",
            "You can't lift \(item)."
        )
    }

    open func restoreFailed(error: String) -> String {
        output(
            "restoreFailed(error: '\(error)')",
            "Restore failed: '\(error)'"
        )
    }

    open func roomIsDark() -> String {
        output(
            "roomIsDark()",
            "It is pitch black. You can't see a thing."
        )
    }

    open func rubCharacter(character: String) -> String {
        output(
            "rubCharacter(character: '\(character)')",
            "I don't think \(character) would appreciate being rubbed."
        )
    }

    open func rubCleanItem(item: String) -> String {
        output(
            "rubCleanItem(item: '\(item)')",
            "You rub \(item). It feels smooth to the touch."
        )
    }

    open func rubGenericObject(item: String) -> String {
        output(
            "rubGenericObject(item: '\(item)')",
            "You rub \(item), but nothing interesting happens."
        )
    }

    open func rubLamp(item: String) -> String {
        output(
            "rubLamp(item: '\(item)')",
            "Rubbing \(item) doesn't seem to do anything. No djinn appears."
        )
    }

    open func rubTakableObject(item: String) -> String {
        output(
            "rubTakableObject(item: '\(item)')",
            "You rub \(item). It feels smooth to the touch."
        )
    }

    open func saveFailed(error: String) -> String {
        output(
            "saveFailed(error: '\(error)')",
            "Save failed: '\(error)'"
        )
    }

    open func screamResponse() -> String {
        output(
            "screamResponse()",
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
        )
    }

    open func scriptAlreadyOn() -> String {
        output(
            "scriptAlreadyOn()",
            "Scripting is already on."
        )
    }

    open func scriptNotOn() -> String {
        output(
            "scriptNotOn()",
            "Scripting is not currently on."
        )
    }

    open func shakeCharacter(character: String) -> String {
        output(
            "shakeCharacter(character: '\(character)')",
            "I don't think \(character) would appreciate being shaken."
        )
    }

    open func shakeClosedContainer(container: String) -> String {
        output(
            "shakeClosedContainer(container: \(container))",
            "You shake \(container) and hear something rattling inside."
        )
    }

    open func shakeFixedObject(item: String) -> String {
        output(
            "shakeFixedObject(item: '\(item)')",
            "You can't shake \(item) - it's firmly in place."
        )
    }

    open func shakeLiquidContainer(item: String) -> String {
        output(
            "shakeLiquidContainer(item: '\(item)')",
            "You shake \(item) and hear liquid sloshing inside."
        )
    }

    open func shakeOpenContainer(container: String) -> String {
        output(
            "shakeOpenContainer(container: \(container))",
            "You shake \(container), but nothing falls out."
        )
    }

    open func shakeTakableObject(item: String) -> String {
        output(
            "shakeTakableObject(item: '\(item)')",
            "You shake \(item) vigorously, but nothing happens."
        )
    }

    open func singResponse() -> String {
        output(
            "singResponse()",
            oneOf(
                "You belt out a tune with the fearless creativity of a true genius.",
                "You croon beautifully, in a very personal interpretation of the melody.",
                "You croon like a nightingale with a head cold, but somehow it works.",
                "You hum a little theme from an old adventure game.",
                "You sing melodiously, creating your own unique scale system.",
                "You sing the song of your people.",
                "You sing with a natural ability that defies conventional music theory.",
                "You sing with the confidence of someone who's never heard themselves.",
                "You vocalize with admirable enthusiasm, inventing new notes as you go.",
                "You warble charmingly, redefining several musical concepts in the process.",
                "You warble with the kind of authenticity that cannot be taught.",
                "Your musical genius is painfully ahead of its time.",
            )
        )
    }

    open func smellCanOnlySmellItems() -> String {
        output(
            "smellCanOnlySmellItems()",
            "You can only smell items directly."
        )
    }

    open func smellNothingUnusual() -> String {
        output(
            "smellNothingUnusual()",
            "You smell nothing unusual."
        )
    }

    open func smellsAverage() -> String {
        output(
            "smellsAverage()",
            "That smells about average."
        )
    }

    open func squeezeCharacter(character: String) -> String {
        output(
            "squeezeCharacter(character: '\(character)')",
            "I don't think \(character) would appreciate being squeezed."
        )
    }

    open func squeezeHardObject(item: String) -> String {
        output(
            "squeezeHardObject(item: '\(item)')",
            "You squeeze \(item) as hard as you can, but it doesn't give."
        )
    }

    open func squeezeLiquidContainer(item: String) -> String {
        output(
            "squeezeLiquidContainer(item: '\(item)')",
            "You squeeze \(item) and some of its contents ooze out."
        )
    }

    open func squeezeSoftObject(item: String) -> String {
        output(
            "squeezeSoftObject(item: '\(item)')",
            "You squeeze \(item). It feels soft and yielding."
        )
    }

    open func squeezeSponge(item: String) -> String {
        output(
            "squeezeSponge(item: '\(item)')",
            "You squeeze \(item) and water drips out."
        )
    }

    open func stateValidationFailed() -> String {
        output(
            "stateValidationFailed()",
            "A strange buzzing sound indicates something is wrong with the state validation.",
            .warning
        )
    }

    open func suggestUsingToolToDig() -> String {
        output(
            "suggestUsingToolToDig()",
            "You could try using a tool to dig with."
        )
    }

    open func taken() -> String {
        output(
            "taken()",
            "Taken."
        )
    }

    open func targetIsNotAContainer(item: String) -> String {
        output(
            "targetIsNotAContainer(item: '\(item)')",
            "You can't put things in \(item)."
        )
    }

    open func targetIsNotASurface(item: String) -> String {
        output(
            "targetIsNotASurface(item: '\(item)')",
            "You can't put things on \(item)."
        )
    }

    open func tastesAverage() -> String {
        output(
            "tastesAverage()",
            "That tastes about average."
        )
    }

    open func tellCharacterAboutWhat(character: String) -> String {
        output(
            "tellCharacterAboutWhat(character: \(character)",
            "Tell \(character) about what?"
        )
    }

    open func tellCannotTellAbout(item: String) -> String {
        output(
            "tellCannotTellAbout(item: '\(item)')",
            "You can't tell \(item) about anything."
        )
    }

    open func tellCanOnlyTellCharacters() -> String {
        output(
            "tellCanOnlyTellCharacters()",
            "You can only tell things to other characters."
        )
    }

    open func tellWhom() -> String {
        output(
            "tellWhom()",
            "Tell whom?"
        )
    }

    open func thereIsNothingHereToTake() -> String {
        output(
            "thereIsNothingHereToTake()",
            "There is nothing here to take."
        )
    }

    open func thinkAboutItem(item: String) -> String {
        output(
            "thinkAboutItem(item: '\(item)')",
            "You contemplate \(item) for a bit, but nothing fruitful comes to mind."
        )
    }

    open func thinkAboutLocation() -> String {
        output(
            "thinkAboutLocation()",
            "You ponder the location, but it remains stubbornly locational."
        )
    }

    open func thinkAboutSelf() -> String {
        output(
            "thinkAboutSelf()",
            "Yes, yes, you're very important."
        )
    }

    open func throwAtCharacter(item: String, character: String) -> String {
        output(
            "throwAtCharacter(item: '\(item)', character: '\(character)')",
            "You throw \(item) at \(character)."
        )
    }

    open func throwAtObject(item: String, target: String) -> String {
        output(
            "throwAtObject(item: '\(item)', target: '\(target)')",
            "You throw \(item) at \(target). It bounces off harmlessly."
        )
    }

    open func throwGeneral(item: String) -> String {
        output(
            "throwGeneral(item: '\(item)')",
            "You throw \(item), and it falls to the ground."
        )
    }

    open func tieCannotTieLivingBeings() -> String {
        output(
            "tieCannotTieLivingBeings()",
            "You can't tie living beings together like that."
        )
    }

    open func tieCannotTieThat() -> String {
        output(
            "tieCannotTieThat()",
            "You can't tie that."
        )
    }

    open func tieCannotTieToSelf(item: String) -> String {
        output(
            "tieCannotTieToSelf(item: '\(item)')",
            "You can't tie \(item) to itself."
        )
    }

    open func tieCannotTieToThat() -> String {
        output(
            "tieCannotTieToThat()",
            "You can't tie something to that."
        )
    }

    open func tieKnotInRope(item: String) -> String {
        output(
            "tieKnotInRope(item: '\(item)')",
            "You tie a knot in \(item)."
        )
    }

    open func tieNeedsSomethingToTieCharacterWith(character: String) -> String {
        output(
            "tieNeedsSomethingToTieCharacterWith(character: '\(character)')",
            "You can't tie up \(character) without something to tie them with."
        )
    }

    open func tieNeedsSomethingToTieWith(item: String) -> String {
        output(
            "tieNeedsSomethingToTieWith(item: '\(item)')",
            "You can't tie \(item) without something to tie it with."
        )
    }

    open func timePasses() -> String {
        output(
            "timePasses()",
            "Time passes."
        )
    }

    open func toolMissing(tool: String) -> String {
        output(
            "toolMissing(tool: '\(tool)')",
            "You need \(tool) for that."
        )
    }

    open func toolNotSuitableForDigging(tool: String) -> String {
        output(
            "toolNotSuitableForDigging(tool: '\(tool)')",
            "\(tool.capitalizedFirst) isn't suitable for digging."
        )
    }

    open func turnCharacter(character: String) -> String {
        output(
            "turnCharacter(character: '\(character)')",
            "You can't turn \(character) around like an object."
        )
    }

    open func turnDial(item: String) -> String {
        output(
            "turnDial(item: '\(item)')",
            "You turn \(item). It clicks into a new position."
        )
    }

    open func turnFixedObject(item: String) -> String {
        output(
            "turnFixedObject(item: '\(item)')",
            "\(item) doesn't seem to be designed to be turned."
        )
    }

    open func turnHandle(item: String) -> String {
        output(
            "turnHandle(item: '\(item)')",
            "You turn \(item). It moves with a grinding sound."
        )
    }

    open func turnKey(item: String) -> String {
        output(
            "turnKey(item: '\(item)')",
            "You can't just turn \(item) by itself. You need to use it with something."
        )
    }

    open func turnKnob(item: String) -> String {
        output(
            "turnKnob(item: '\(item)')",
            "You turn \(item). It clicks into a new position."
        )
    }

    open func turnRegularObject(item: String) -> String {
        output(
            "turnRegularObject(item: '\(item)')",
            "You turn \(item) around in your hands, but nothing happens."
        )
    }

    open func turnWheel(item: String) -> String {
        output(
            "turnWheel(item: '\(item)')",
            "You turn \(item). It rotates with some effort."
        )
    }

    open func unknownEntity() -> String {
        output(
            "unknownEntity()",
            "You can't see any such thing."
        )
    }

    open func unknownNoun(noun: String) -> String {
        output(
            "unknownNoun(noun: '\(noun)')",
            "You can't see any \(noun) here."
        )
    }

    open func unknownVerb(verb: String) -> String {
        output(
            "unknownVerb(verb: '\(verb)')",
            "I don't know how to \"'\(verb)'\" something."
        )
    }

    open func unlockAlreadyUnlocked(item: String) -> String {
        output(
            "unlockAlreadyUnlocked(item: '\(item)')",
            "The \(item) is already unlocked."
        )
    }

    open func unlockWithWhat(item: String) -> String {
        output(
            "unlockWithWhat(item: \(item))",
            "Unlock \(item) with what?"
        )
    }

    open func waveCharacter(character: String) -> String {
        output(
            "waveCharacter(character: '\(character)')",
            "You wave \(character) around, but it doesn't seem to appreciate being waved."
        )
    }

    open func waveFixedObject(item: String) -> String {
        output(
            "waveFixedObject(item: '\(item)')",
            "You can't wave \(item) around - it's not something you can pick up and wave."
        )
    }

    open func waveFlag(item: String) -> String {
        output(
            "waveFlag(item: '\(item)')",
            "You wave \(item) around. It's not particularly impressive."
        )
    }

    open func waveMagicalItem(item: String) -> String {
        output(
            "waveMagicalItem(item: '\(item)')",
            "You wave \(item) dramatically, but nothing magical happens."
        )
    }

    open func waveWeapon(item: String) -> String {
        output(
            "waveWeapon(item: '\(item)')",
            "You brandish \(item) menacingly."
        )
    }

    open func wrongKey(key: String, lock: String) -> String {
        output(
            "wrongKey(key: '\(key)', lock: '\(lock)')",
            "\(key.capitalizedFirst) doesn't fit \(lock)."
        )
    }

    open func yellResponse() -> String {
        output(
            "yellResponse()",
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
        )
    }

    open func youAlreadyHaveThat() -> String {
        output(
            "youAlreadyHaveThat()",
            "You already have that."
        )
    }

    open func youAreCarrying() -> String {
        output(
            "youAreCarrying()",
            "You are carrying:"
        )
    }

    open func youAreEmptyHanded() -> String {
        output(
            "youAreEmptyHanded()",
            "You are empty-handed."
        )
    }

    open func youArentHoldingThat() -> String {
        output(
            "youArentHoldingThat()",
            "You aren't holding that."
        )
    }

    open func youArentWearingAnything() -> String {
        output(
            "youArentWearingAnything()",
            "You aren't wearing anything."
        )
    }

    open func youCannotTakeFromNonContainer(container: String) -> String {
        output(
            "youCannotTakeFromNonContainer(container: \(container))",
            "You can't take things out of \(container)."
        )
    }

    open func youCanOnlyActOnItems(verb: String) -> String {
        output(
            "youCanOnlyActOnItems(verb: '\(verb)')",
            "You can only \(verb) items."
        )
    }

    open func youCanOnlyMoveItems() -> String {
        output(
            "youCanOnlyMoveItems()",
            "You can only move items."
        )
    }

    open func youCanOnlyPutItemsOnThings() -> String {
        output(
            "youCanOnlyPutItemsOnThings()",
            "You can only put items on things."
        )
    }

    open func youCanOnlyPutThingsOnSurfaces() -> String {
        output(
            "youCanOnlyPutThingsOnSurfaces()",
            "You can only put things on items (that are surfaces)."
        )
    }

    open func youCanOnlyRaiseItems() -> String {
        output(
            "youCanOnlyRaiseItems()",
            "You can only raise items."
        )
    }

    open func youCanOnlyReadItems() -> String {
        output(
            "youCanOnlyReadItems()",
            "You can only read items."
        )
    }

    open func youCanOnlySmellItems() -> String {
        output(
            "youCanOnlySmellItems()",
            "You can only smell items directly."
        )
    }

    open func youCanOnlyTasteItems() -> String {
        output(
            "youCanOnlyTasteItems()",
            "You can only taste items."
        )
    }

    open func youCanOnlyTellCharacters() -> String {
        output(
            "youCanOnlyTellCharacters()",
            "You can only tell characters about things."
        )
    }

    open func youCanOnlyTouchItems() -> String {
        output(
            "youCanOnlyTouchItems()",
            "You can only touch items."
        )
    }

    open func youCanOnlyTurnOffItems() -> String {
        output(
            "youCanOnlyTurnOffItems()",
            "You can only turn off items."
        )
    }

    open func youCanOnlyTurnOnItems() -> String {
        output(
            "youCanOnlyTurnOnItems()",
            "You can only turn on items."
        )
    }

    open func youCanOnlyUnlockItems() -> String {
        output(
            "youCanOnlyUnlockItems()",
            "You can only unlock items."
        )
    }

    open func youCanOnlyUseItemAsKey() -> String {
        output(
            "youCanOnlyUseItemAsKey()",
            "You can only use an item as a key."
        )
    }

    open func youCanOnlyWearItems() -> String {
        output(
            "youCanOnlyWearItems()",
            "You can only wear items."
        )
    }

    open func youCantDoThat() -> String {
        output(
            "youCantDoThat()",
            "You can't do that."
        )
    }

    open func youDontHaveThat() -> String {
        output(
            "youDontHaveThat()",
            "You don't have that."
        )
    }

    open func youDropMultipleItems(items: String) -> String {
        output(
            "youDropMultipleItems(items: '\(items)')",
            "You drop \(items)."
        )
    }

    open func youHaveIt() -> String {
        output(
            "youHaveIt()",
            "You have it."
        )
    }

    open func youHaveNothingToPutIn(container: String) -> String {
        output(
            "youHaveNothingToPutIn(container: \(container))",
            "You have nothing to put in \(container)."
        )
    }

    open func youHearNothingUnusual() -> String {
        output(
            "youHearNothingUnusual()",
            "You hear nothing unusual."
        )
    }

    open func youRemoveMultipleItems(items: String) -> String {
        output(
            "youRemoveMultipleItems(items: '\(items)')",
            "You take off \(items)."
        )
    }

    open func youPutItemInContainer(item: String, container: String) -> String {
        output(
            "youPutItemInContainer(item: '\(item)', container: \(container))",
            "You put \(item) in \(container)."
        )
    }

    open func youPutItemOnSurface(item: String, surface: String) -> String {
        output(
            "youPutItemOnSurface(item: '\(item)', surface: \(surface))",
            "You put \(item) on \(surface)."
        )
    }

    open func youPutOn(item: String) -> String {
        output(
            "youPutOn(item: '\(item)')",
            "You put on \(item)."
        )
    }

    open func youSeeNo(item: String) -> String {
        output(
            "youSeeNo(item: '\(item)')",
            "You see no \(item) here."
        )
    }

    open func youTakeMultipleItems(items: String) -> String {
        output(
            "youTakeMultipleItems(items: '\(items)')",
            "You take \(items)."
        )
    }

    open func quitScoreAndPrompt(score: Int, maxScore: Int, moves: Int) -> String {
        output(
            "quitScoreAndPrompt(score: \(score), maxScore: \(maxScore), moves: \(moves))",
            """
            Your score is \(score) (total of \(maxScore) points), in \(moves) moves.
            Do you wish to leave the game? (Y is affirmative):
            """
        )
    }

    open func quitConfirmationHelp() -> String {
        output(
            "quitConfirmationHelp()",
            "Please answer yes or no."
        )
    }

    open func quitCancelled() -> String {
        output(
            "quitCancelled()",
            "OK, continuing the game."
        )
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

    /// Logs a debug message and returns the game output string.
    ///
    /// This method provides a dual-purpose logging and output mechanism for message providers.
    /// It logs detailed debug information about which message method was called and with what
    /// parameters, while returning the actual game text that should be displayed to the player.
    ///
    /// The log messages are formatted with emoji icons to make them easily scannable during
    /// development and debugging. These logs help track message generation flow and identify
    /// which specific message methods are being triggered during gameplay.
    ///
    /// - Parameters:
    ///   - logMessage: Debug information about the message method call (autoclosure for performance)
    ///   - gameOutput: The actual text to display to the player (autoclosure for performance)
    ///   - logLevel: The logging level for the debug message (defaults to `.info`)
    /// - Returns: The game output string that should be displayed to the player
    public func output(
        _ logMessage: @autoclosure () -> String,
        _ gameOutput: @autoclosure () -> String,
        _ logLevel: Logger.Level = .info
    ) -> String {
        let icon = switch logLevel {
        case .trace: "🔍"
        case .debug: "🐛"
        case .info: "🎯"
        case .notice: "📣"
        case .warning: "⚠️"
        case .error: "🛑"
        case .critical: "💀"
        }
        logger.log(
            level: logLevel,
            Logger.Message(
                stringLiteral: "\n\(icon) \(logMessage())"
            )
        )
        return gameOutput()
    }
}
