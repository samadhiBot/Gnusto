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

    open func anySomething(_ text: String) -> String {
        output(
            "anySomething(text: '\(text)')",
            "any \(text)"
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

    open func blow() -> String {
        output(
            "blowGeneral()",
            "You blow the air around, but nothing interesting happens."
        )
    }

    open func blowOn(item: String) -> String {
        output(
            "blowOnGeneric(item: '\(item)')",
            "You blow on \(item), but nothing interesting happens."
        )
    }

    open func breatheOnResponse(item: String) -> String {
        output(
            "breatheOnResponse(item: '\(item)')",
            oneOf(
                "You breathe on \(item) with the focus of someone who understands the power of proximity.",
                "You exhale toward \(item) with a commitment to sharing your personal atmosphere.",
                "You breathe on \(item) in an intimate manner that really makes an impression.",
                "You direct your breath at \(item) with full confidence in your respiratory technique.",
                "You exhale on \(item) with the authenticity of someone unafraid to get close.",
                "You breathe on \(item) with refreshing directness in your interpersonal methodology.",
                "You exhale on \(item) with an unshakable faith in the communicative power of respiration.",
                "You breathe on \(item) with the fearless intimacy of someone who shares everything.",
                "You direct your breath at \(item) with true dedication to atmospheric connection.",
                "You exhale toward \(item) with a closeness that transcends conventional boundaries.",
                "You breathe on \(item) with refreshing honesty about your breathing priorities.",
                "You direct your breath at \(item), demonstrating your belief in direct engagement.",
                "You exhale on \(item), showing your commitment to full sensory interaction.",
            )
        )
    }

    open func breatheResponse() -> String {
        output(
            "breatheResponse()",
            oneOf(
                "You breathe in life's very essence, which tastes faintly of confusion.",
                "You breathe in whatever passes for air around here.",
                "You breathe thoughtfully, pondering the miracle of atmospheric composition.",
                "You breathe with great purpose, although breathing tends to happen anyway.",
                "You inhale deeply, briefly grateful for the invention of oxygen.",
                "You inhale slowly, appreciating the universe's decision to include breathable air.",
                "You recall your mantra, 'Breathe in the love... and blow out the jive...'",
                "You take a breath, marveling at your lungs' stubborn refusal to give up.",
                "You take a breath, noting that it's roughly the same as the last one.",
                "You take a breath, tasting hints of adventure and poor ventilation.",
                "You take a tentative breath, unsure whether the atmosphere is still working.",
                "You were already doing that, but you also continue to breathe.",
            )
        )
    }

    open func burnCannotBurn(item: String) -> String {
        output(
            "burnCannotBurn(item: '\(item)')",
            "You can't burn \(item)."
        )
    }

    open func cannotDoThat(verb: String) -> String {
        output(
            "cannotDoThat(verb: '\(verb)')",
            "You can't \(verb) that."
        )
    }

    open func cannotDoThat(verb: Verb, item: String) -> String {
        output(
            "cannotDoThat(verb: \(verb), item: '\(item)')",
            "You can't \(verb.rawValue) \(item)."
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

    open func cannotEatFromClosed(container: String) -> String {
        output(
            "cannotEatFromClosed(container: \(container))",
            "You can't eat from \(container)."
        )
    }

    open func cannotFillFrom() -> String {
        output(
            "cannotFillFrom()",
            "You can't fill from that."
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

    open func characterDoesNotSeemToKnow(character: String, topic: String) -> String {
        output(
            "characterDoesNotSeemToKnow(character: '\(character)', topic: '\(topic)')",
            "\(character.capitalizedFirst) doesn't seem to know anything about \(topic)."
        )
    }

    open func characterListens(character: String, topic: String) -> String {
        output(
            "characterListens(character: '\(character)', topic: '\(topic)')",
            "\(character.capitalizedFirst) listens politely to what you say about \(topic)."
        )
    }

    open func chompEdible(item: String) -> String {
        output(
            "chompEdible(item: '\(item)')",
            "You take a bite. It tastes like \(item)."
        )
    }

    open func chompCharacter(_ character: String) -> String {
        output(
            "chompCharacter(_ character: String)",
            oneOf(
                "You chomp \(character) as one might when exploring all new social boundaries.",
                "You bite \(character) with a zeal for unconventional interaction methods.",
                "You chomp \(character) with the dauntless intimacy of a truly authentic communicator.",
                "You bite \(character) in a direct manner that cuts through all social pretense.",
                "You chomp \(character) with refreshing honesty about your primal instincts.",
                "You gnaw \(character) in a thinking-outside-the-box kind of a way.",
                "You bite \(character) with admirable confidence in your interpersonal techniques.",
                "You chomp \(character) with the thoroughness of someone who's not looking back.",
                "You gnaw \(character) with a bold authenticity of unfiltered self-expression.",
                "You bite \(character) and further extend the range in your communication repertoire.",
                "You bite \(character) despite all of the socializing you received as a child.",
            )
        )
    }

    open func chompResponse() -> String {
        output(
            "chompResponse()",
            oneOf(
                "It feels good to get some chomping done.",
                "Sounds of your chomping echo all around you.",
                "You bite with the confidence of someone who need never question their methods.",
                "You chomp decisively, showing excellent follow-through on a bold concept.",
                "You chomp enthusiastically at the air, flexing your impressive jaw strength.",
                "You chomp with a creative interpretation that redefines the whole concept.",
                "You chomp with a primal intensity that earns your ancestors' approval.",
                "You chomp with a conviction that makes reality itself seem negotiable.",
                "You chomp with the fearless abandon of a true innovator.",
                "You chomp with the raw authenticity of someone unencumbered by context.",
                "You chomp your teeth together menacingly.",
                "You clench your fists and gnash your teeth.",
                "You gnash your teeth with the passion of one who believes in their vision.",
                "You gnaw thoughtfully on nothing in particular.",
                "You practice your chomping technique.",

            )
        )
    }

    open func chompTargetResponse(item: String) -> String {
        output(
            "chompTargetResponse(item: '\(item)')",
            oneOf(
                "You bite \(item) decisively, demonstrating impressive dedication to the concept.",
                "You bite \(item) enthusiastically, showing excellent problem-solving instincts.",
                "You bite \(item) with a refreshing confidence in your unconventional approach.",
                "You bite \(item) with the experimental spirit that advances civilizations.",
                "You bite \(item) with the sort of outside-the-box thinking that changes everything.",
                "You chomp \(item) boldly, redefining what's possible in this space.",
                "You chomp \(item) with the fearless innovation of someone unbound by convention.",
                "You chomp \(item) with the kind of creative thinking that challenges assumptions.",
                "You chomp on \(item) with the boldness of a true pioneer.",
                "You gnaw \(item) thoughtfully, exploring new frontiers of possibility.",
                "You gnaw \(item) with the focused determination of a visionary.",
                "You gnaw \(item) with the methodical approach of a serious researcher.",
                "You gnaw on \(item) with the persistence of someone who truly believes in their methods.",
            )
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
                "You cry boldly, demonstrating an intuitive grasp of cathartic release.",
                "You cry with a raw vulnerability that takes real courage.",
                "You cry with an emotional authenticity that cannot be taught.",
                "You cry with the authentic passion of someone unafraid to feel deeply.",
                "You shed tears with an admirable commitment to the full human experience.",
                "You shed tears with the confident vulnerability of a true empath.",
                "You sob with the fearless emotional intelligence of a philosopher gone mad.",
                "You sob with the kind of emotional honesty that's refreshingly genuine.",
                "You sob with the natural grace of someone comfortable with their feelings.",
                "You weep beautifully, demonstrating your impressive range of expression.",
                "You weep with the emotional depth of a true artist.",
                "You weep with a heartfelt expression that defies cynicism.",
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
                "You curse with a linguistic innovation that pushes boundaries.",
                "You curse with an expressive range that demonstrates real versatility.",
                "You curse with the eloquence of a true wordsmith.",
                "You curse with the flair of a poet exploring darker themes.",
                "You curse with the fluency of one comfortable with all registers of language.",
                "You curse with the linguistic fearlessness of a true innovator.",
                "You let loose a string of expletives that reveals an impressive technical proficiency.",
                "You swear with a dedication to the full spectrum of human expression.",
                "You swear with admirable creativity, even inventing a few new combinations.",
                "You swear with the passion of a thousand frustrated adventurers.",
                "You swear with the vocabulary of someone unencumbered by politeness.",
                "You unleash expletives with the boldness of one who knows their craft.",
                "You unleash profanity with a passionate intensity that's genuinely moving.",
                "You unleash profanity with the confidence of a seasoned orator.",
            )
        )
    }

    open func curseTargetResponse(item: String) -> String {
        output(
            "curseTargetResponse(item: '\(item)')",
            oneOf(
                "You curse \(item) with a directed passion that shows excellent analytical skills.",
                "You curse \(item) with a refreshing clarity on where to assign blame.",
                "You curse \(item) with impressive dedication to holding the right parties responsible.",
                "You curse \(item) with the assuredness of one who's identified the real problem.",
                "You curse \(item) with the focused anger of someone who's really thought this through.",
                "You direct expletives at \(item) with the systematic thinking of a true investigator.",
                "You direct profanity at \(item) with that kind of strategic thinking that gets results.",
                "You swear at \(item) with a targeted approach that demonstrates real insight.",
                "You swear at \(item) with an admirable precision in your target selection.",
                "You swear at \(item) with refreshing decisiveness when it comes to fault attribution.",
                "You swear at \(item) with the logical approach of one who understands accountability.",
                "You swear at \(item) with unmatched confidence in your problem-solving methodology.",
                "You unleash a tirade at \(item) with excellent instincts for root cause analysis.",
                "You unleash expletives at \(item) with an impressive commitment to cause-and-effect reasoning.",
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
                "You boogie with admirable confidence in your choreographic vision.",
                "You boogie with impressive commitment to your personal artistic expression.",
                "You boogie with the bold conviction of one who's rewriting the rules.",
                "You boogie with the fearless self-expression of a pioneering artist.",
                "You dance with admirable commitment to the full spectrum of human motion.",
                "You dance with an innovative spirit that pushes the boundaries of the form.",
                "You dance with an interpretive boldness that transcends conventional movement.",
                "You dance with impressive range, exploring movements that defy categorization.",
                "You dance with refreshing originality, creating your own relationship with music.",
                "You dance with the confident flair of one who has finally found their voice.",
                "You dance with the fearless creativity of someone redefining rhythm itself.",
                "You dance with the natural grace of one unencumbered by traditional technique.",
                "You move rhythmically with profound dedication to your own internal beat.",
                "You move with an authentic passion that cannot be choreographed.",
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
            "You dig with \(tool), but find nothing of interest."
        )
    }

    open func directionIsBlocked(reason: String?) -> String {
        let logMessage = if let reason {
            "directionIsBlocked(reason: '\(reason)')"
        } else {
            "directionIsBlocked(reason: nil)"
        }
        return output(
            logMessage,
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

    open func doWhat(action: String) -> String {
        output(
            "doWhat(action: '\(action)')",
            "\(action.capitalizedFirst) what?"
        )
    }

    open func doWhat(verb: Verb) -> String {
        output(
            "doWhat(verb: \(verb))",
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

    open func itemBurnsToAshes(item: String) -> String {
        output(
            "itemBurnsToAshes(item: '\(item)')",
            "\(item.capitalizedFirst) catches fire and is consumed."
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

    open func itemIsNowUnlocked(item: String) -> String {
        output(
            "itemIsNowUnlocked(item: '\(item)')",
            "\(item.capitalizedFirst) is now unlocked."
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
                "You bounce with a kinetic enthusiasm that shows real _joie de vivre_.",
                "You bounce with admirable dedication to the ancient art of controlled falling.",
                "You bounce with an energetic authenticity that's genuinely inspiring.",
                "You bounce with refreshing optimism about the possibilities of upward motion.",
                "You bounce with the natural grace of one comfortable with all dimensions of vertical movement.",
                "You jump with a dedication to exploring the full range of human locomotion.",
                "You jump with a physical expression that transcends mere transportation.",
                "You jump with absolute confidence in your relationship with physics.",
                "You jump with the athletic confidence of one who's mastered vertical movement.",
                "You jump with the bold conviction of one who refuses to be earthbound.",
                "You leap unencumbered by conventional ground-based thinking.",
                "You leap with admirable commitment to defying gravity, however briefly.",
                "You leap with admirable faith in your own propulsive capabilities.",
                "You leap with impressive range, really exploring the vertical space around you.",
                "You leap with the ambition of one reaching for new heights.",
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
                "You attempt to smooch \(character) in a bold romantic initiative that takes real courage.",
                "You attempt to smooch \(character) with admirable dedication to expressing your feelings.",
                "You attempt to smooch \(character) with refreshing honesty about your intentions.",
                "You lean in to kiss \(character) with a romantic authenticity that's beautifully unguarded.",
                "You lean in to kiss \(character) with the confident charm of one who knows their worth.",
                "You lean in to kiss \(character) with the romantic confidence of one who's really reading the signals.",
                "You lean in to kiss \(character) with unshakable confidence in your interpersonal appeal.",
                "You move in for a kiss with \(character), demonstrating a bold faith in your charm offensive.",
                "You move in for a kiss with \(character), demonstrating excellent instincts for seizing the moment.",
                "You move in for a kiss with \(character), showing the bold vulnerability of a true romantic.",
                "You pucker up at \(character) with admirable faith in the power of spontaneous affection.",
                "You pucker up at \(character) with the fearless romanticism of one who shoots their shot.",
                "You pucker up toward \(character) with impressive commitment to following your heart.",
                "You pucker up toward \(character) with unchecked optimism about mutual attraction.",
            )
        )
    }

    open func kissEnemy(enemy: String) -> String {
        output(
            "kissEnemy(enemy: '\(enemy)')",
            oneOf(
                "Reading the room incorrectly, you pucker up as \(enemy) enters full attack mode.",
                "You attempt to kiss \(enemy) in an innovative act of diplomacy that truly thinks outside the box.",
                "You attempt to smooch \(enemy) with admirable dedication to the power of unexpected gestures.",
                "You attempt to smooch \(enemy) with a disarming confidence in your ability to find common ground.",
                "You give them a smooch, but \(enemy) remains disappointingly homicidal.",
                "You lean in for a kiss and narrowly avoid losing your nose.",
                "You lean in for a kiss while \(enemy) is actively trying to kill you.",
                "You lean in for a kiss, but \(enemy) seems more interested in eating your face.",
                "You lean in to kiss \(enemy) with the fearless romanticism of one who refuses to give up on love.",
                "You lean in to kiss \(enemy) in an act of creative problem-solving that redefines the situation.",
                "You move in for a kiss with \(enemy), demonstrating the bold vulnerability of a true peacemaker.",
                "You pucker up and then immediately regret this tactical decision.",
                "You pucker up at \(enemy), knowing inside that _love_ is the ultimate weapon.",
                "You try to kiss \(enemy) mid-snarl, which seems poorly timed.",
            )
        )
    }

    open func kissObject(item: String) -> String {
        output(
            "kissObject(item: '\(item)')",
            oneOf(
                "You briefly kiss \(item), which offers no secrets to your lips.",
                "You give \(item) a passionate kiss with the fearless vulnerability of a true romantic.",
                "You give \(item) a quick kiss, which fails to reveal anything significant.",
                "You give \(item) a tender kiss with confidence in your ability to connect with anything.",
                "You give \(item) an investigative kiss. The investigation yields little.",
                "You kiss \(item) curiously, but your curiosity remains unsatisfied.",
                "You kiss \(item) experimentally, but nothing remarkable happens.",
                "You kiss \(item) once, and think you detect trace amounts of indifference.",
                "You kiss \(item) with a passionate curiosity that explores all possibilities.",
                "You kiss \(item) with impressive commitment to expressing affection in all its forms.",
                "You kiss \(item) with impressive dedication to spreading love wherever you go.",
                "You kiss \(item) with the bold authenticity of one who follows their heart.",
                "You plant a brief kiss on \(item), yet your lips learn nothing new.",
                "You plant a kiss on \(item) with an emotional generosity that's beautifully inclusive.",
                "You plant a small kiss on \(item), learning nothing your eyes hadn't already told you.",
                "You plant a smooch on \(item) with admirable commitment to your emotional truth.",
                "You plant a smooch on \(item) with admirable openness to unconventional relationships.",
                "You plant a testing kiss on \(item), but the test results are inconclusive.",
                "You smooch \(item) with an open-minded affection that transcends normal boundaries.",
                "You smooch \(item) with the fearless romanticism of someone unbound by social conventions.",
            )
        )
    }

    open func kissSelf() -> String {
        output(
            "kissSelf()",
            oneOf(
                "You plant a smooch on yourself with admirable confidence in your own worth.",
                "You kiss yourself with the kind of self-acceptance that's genuinely inspiring.",
                "You give yourself a tender kiss with refreshing honesty about who deserves your affection most.",
                "You smooch yourself with the fearless self-appreciation of someone who knows their value.",
                "You kiss yourself with impressive dedication to practicing what you preach about self-care.",
                "You plant a loving kiss on yourself with the kind of emotional intelligence that starts from within.",
                "You give yourself a passionate smooch with admirable commitment to being your own best partner.",
                "You kiss yourself with the bold authenticity of someone unafraid to show self-affection.",
                "You plant a tender kiss on yourself with refreshing prioritization of the most important relationship.",
                "You smooch yourself with a _healthy_ narcissism that's actually quite evolved.",
                "You kiss yourself with impressive range in your capacity for love and appreciation.",
                "You give yourself a romantic kiss with the fearless vulnerability of true self-acceptance.",
                "You plant a smooch on yourself with admirable recognition of where charity begins.",

            )
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
                "You chortle with the sophisticated humor of someone who gets jokes others don't.",
                "You chuckle at the meaninglessness of it all.",
                "You chuckle with an admirable lightness of spirit in the face of everything.",
                "You chuckle with an appreciation for life's subtle ironies.",
                "You chuckle with the confident amusement of someone in on the cosmic joke.",
                "You chuckle with the fearless delight of someone who finds things funny that others do not.",
                "You giggle with a genuine delight that's beautifully unguarded.",
                "You giggle with refreshing honesty about what you find amusing.",
                "You laugh at the absurdity of existence.",
                "You laugh boldly at the forces arrayed against you.",
                "You laugh heroically at your impossible circumstances.",
                "You laugh in the face of cosmic indifference.",
                "You laugh in the face of overwhelming odds.",
                "You laugh in the face of your own mortality.",
                "You snicker with impressive insight into the absurdities around you.",
                "You snicker with the discerning wit of someone who sees the bigger picture.",
                "You snicker with the sophisticated appreciation of someone who truly understands irony.",
            )
        )
    }

    open func lightIsNowOff(item: String) -> String {
        output(
            "lightIsNowOff(item: '\(item)')",
            "\(item.capitalizedFirst) is now off."
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

    open func nothingSpecial(verb: Verb) -> String {
        output(
            "nothingSpecial(verb: \(verb))",
            "You \(verb.rawValue) nothing special."
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

    open func nothingWrittenOn(item: String) -> String {
        output(
            "nothingWrittenOn(item: '\(item)')",
            "There's nothing written on \(item)."
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

    open func quitCancelled() -> String {
        output(
            "quitCancelled()",
            "OK, continuing the game."
        )
    }

    open func quitConfirmationHelp() -> String {
        output(
            "quitConfirmationHelp()",
            "Please answer yes or no."
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

    open func rubGenericObject(item: String) -> String {
        output(
            "rubGenericObject(item: '\(item)')",
            "You rub \(item), but nothing interesting happens."
        )
    }

    open func saveFailed(error: String) -> String {
        output(
            "saveFailed(error: '\(error)')",
            "Save failed: '\(error)'"
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

    open func smellNothingUnusual() -> String {
        output(
            "smellNothingUnusual()",
            "You smell nothing unusual."
        )
    }

    open func smellsAverage(item: String) -> String {
        output(
            "smellsAverage()",
            "\(item.capitalizedFirst) smells about average."
        )
    }

    open func smellMyself() -> String {
        output(
            "smellMyself()",
            oneOf(
                "You give yourself a sniff with the bold authenticity of one who knows where they stand.",
                "You give yourself a sniff, proving your resolve when it comes to conducting thorough self-assessments.",
                "You inhale your own aroma, exhibiting a practical wisdom that prevents surprises.",
                "You inhale your own scent, proving your dedication to comprehensive self-monitoring.",
                "You smell yourself in a proactive measure that shows excellent planning skills.",
                "You smell yourself with admirable commitment to personal quality control.",
                "You smell yourself with admirable dedication to your personal maintenance routine.",
                "You smell yourself with an undeniable commitment to evidence-based personal awareness.",
                "You smell yourself with the determination of someone who faces facts head-on.",
                "You sniff yourself with the scientific curiosity of a dedicated researcher.",
                "You take a whiff of yourself in an impressive example of staying informed about your situation.",
            )
        )
    }

    open func squeezeCharacter(character: String) -> String {
        output(
            "squeezeCharacter(character: '\(character)')",
            oneOf(
                "You squeeze \(character) as someone unafraid who expresses love physically.",
                "You give \(character) a firm squeeze, confident in your bonding techniques.",
                "You squeeze \(character) with the fearless intimacy of a natural hugger.",
                "You give \(character) a testing squeeze with refreshing honesty about your feelings.",
                "You compress \(character) with the boldness of someone unafraid to connect.",
                "You squeeze \(character) with an impressive dedication to interpersonal closeness.",
                "You compress \(character), demonstrating your commitment to physical expression.",
                "You squeeze \(character) with a warmth that transcends social boundaries.",
                "You give \(character) a testing squeeze like the dedicated empiricist you are.",
                "You compress \(character) with a refreshing directness in your emotional approach.",
                "You give \(character) a firm squeeze like someone dedicated to hands-on bonding.",
            )
        )
    }

    open func squeezeItem(item: String) -> String {
        output(
            "squeezeItem(item: '\(item)')",
            oneOf(
                "You squeeze \(item) with the empiricism of one who learns through direct experience.",
                "You compress \(item) with the thoroughness of a dedicated researcher.",
                "You squeeze \(item) with the methodical curiosity of a true investigator.",
                "You give \(item) a firm squeeze with admirable diagnostic confidence.",
                "You compress \(item) with the scientific rigor of a hands-on analyst.",
                "You squeeze \(item) with the fearless experimentation of a pioneer.",
                "You give \(item) a testing squeeze with impressive tactile prowess.",
                "You compress \(item) with the bold curiosity of a person seeking answers.",
                "You squeeze \(item) with the practical wisdom of direct investigation.",
                "You give \(item) a firm squeeze with refreshing commitment to evidence-based science.",
                "You compress \(item) with the kind of approach that advances knowledge.",
                "You squeeze \(item) with admirable faith in physical examination.",
                "You give \(item) a testing squeeze with a confidence that comes from years of experience.",
                "You compress \(item) with a thoroughness that leaves nothing unexplored.",
            )
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
            "You could try using a tool for digging."
        )
    }

    open func taken() -> String {
        output(
            "taken()",
            "Taken.\n"
        )
    }

    open func takeItemNotInContainer(item: String, container: String) -> String {
        output(
            "takeItemNotInContainer()",
            "\(item.capitalizedFirst) is not in \(container)."
        )
    }

    open func takeItemFromNonContainer(nonContainer: String) -> String {
        output(
            "takeItemFromNonContainer(nonContainer: '\(nonContainer)')",
            "You can't take things from \(nonContainer)."
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

    open func tastesAverage(item: String) -> String {
        output(
            "tastesAverage(item: '\(item)')",
            "\(item.capitalizedFirst) tastes about average."
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

    open func thatsNotSomethingYouCan(_ verb: Verb) -> String {
        output(
            "thatsNotSomethingYouCan(verb: \(verb))",
            "That's not something you can \(verb.rawValue)."
        )
    }

    open func thatsNotSomethingYouCanPutOnThings() -> String {
        output(
            "thatsNotSomethingYouCanPutOnThings()",
            "That's not something you can put on things."
        )
    }

    open func thatsNotSomethingYouCanUseAsKey() -> String {
        output(
            "thatsNotSomethingYouCanUseAsKey()",
            "That's not something you can use as a key."
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
            "The more you think, the more it remains stubbornly locational."
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
            "\(item.capitalizedFirst) doesn't seem to be designed to be turned."
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

    open func waveFixedObject(item: String) -> String {
        output(
            "waveFixedObject(item: '\(item)')",
            "You can't wave \(item) around -- it's not something you can pick up and wave."
        )
    }

    open func waveObject(item: String) -> String {
        output(
            "waveObject(item: '\(item)')",
            "You give \(item) a little wave."
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

    open func you() -> String {
        output(
            "you()",
            "you"
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

    open func youHaveNothingToGive() -> String {
        output(
            "youHaveNothingToGive()",
            "You have nothing to give."
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

    open func xyzzyResponse() -> String {
        output(
            "xyzzyResponse()",
            #"A hollow voice says "Fool.""#
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
        _ logLevel: Logger.Level = .debug
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
