import Logging

// swiftlint:disable file_length

/// A class responsible for generating user-facing messages in the interactive fiction game.
///
/// The `StandardMessenger` class provides methods for creating standardized text responses
/// for various game actions, events, and error conditions. Each method returns a formatted
/// string that can be displayed to the player.
///
/// This class is designed to be subclassed to allow customization of messages for different
/// games or localization purposes.
///
/// `StandardMessenger` and its subclasses are forced to declare `@unchecked Sendable` because
/// it is an open class.
open class StandardMessenger: @unchecked Sendable {
    /// Internal logger for engine messages, warnings, and errors.
    let logger = Logger(label: "com.samadhibot.Gnusto.StandardMessenger")

    /// A random number generator used for response randomization.
    ///
    /// For testing purposes, a deterministic random number generator can specified when
    /// initializing the StandardMessenger. By default the SystemRandomNumberGenerator is used.
    private var randomNumberGenerator: RandomNumberGenerator

    public init(
        randomNumberGenerator: RandomNumberGenerator = SystemRandomNumberGenerator()
    ) {
        self.randomNumberGenerator = randomNumberGenerator
    }

    open func allCommandNothingHere() -> String {
        oneOf(
            "A profound emptiness greets your acquisitive intentions.",
            "Nothing here warrants your attention.",
            "The immediate vicinity offers nothing of consequence.",
            "There is nothing here worth troubling yourself over."
        )
    }

    open func almostDo(_ verb: Verb, item: String) -> String {
        oneOf(
            "You almost \(verb) \(item), but think better of it.",
            "You consider whether to \(verb) \(item), then decide against it.",
            "Something makes you hesitate before you \(verb) \(item). Perhaps not.",
            "You start to \(verb) \(item) but stop yourself at the last moment.",
            "On second thought, you decide not to \(verb) \(item)."
        )
    }

    open func alreadyBurning(_ item: String) -> String {
        oneOf(
            "\(item) already dances with flame.",
            "\(item) is already burning merrily away.",
            "Fire has already claimed \(item) as its own.",
            "\(item) is already ablaze."
        )
    }

    open func alreadyDead(_ character: String) -> String {
        oneOf(
            "\(character) is already dead.",
            "\(character) has already departed this mortal coil.",
            "Death has already claimed \(character).",
            "\(character) is beyond such concerns now, being dead.",
            "You're too late--\(character) is already deceased."
        )
    }

    open func alreadyDone(_ command: Command, item: String) -> String {
        output("\(item) is already \(command.pastParticiple).")
    }

    open func alreadyInCombat(with enemy: String) -> String {
        oneOf(
            "You're already locked in combat with \(enemy)!",
            "The fight with \(enemy) has already begun!",
            "You're currently engaged with \(enemy)--focus!",
            "In case you hadn't noticed, \(enemy) is already trying to kill you!",
            "You and \(enemy) are already exchanging blows!"
        )
    }

    open func alreadyOff() -> String {
        oneOf(
            "It's already off.",
            "It rests in darkness already.",
            "No power flows through it now."
        )
    }

    open func alreadyOn() -> String {
        oneOf(
            "It's already on.",
            "It hums with life already.",
            "Power already courses through it."
        )
    }

    open func ambiguity(_ text: String) -> String {
        output(text, .notice)
    }

    open func ambiguousObjectReference(_ noun: String, options: [String]) -> String {
        if options.count < 2 {
            output("Which \(noun) do you mean?")
        } else {
            output("Which do you mean, \(options.commaListing("or"))?")
        }
    }

    open func ambiguousReference(_ options: [String]) -> String {
        output("Which do you mean: \(options.commaListing("or"))?")
    }

    open func ambiguousVerb(_ phrase: String, verbs: [String]) -> String {
        let verbsString = verbs.joined(separator: ", ")
        return output(
            """
            The word '\(phrase)' could refer to multiple commands (\(verbsString)),
            but none can handle this syntax. Please be more specific.
            """
        )
    }

    open func anySuchThing() -> String {
        output("any such thing", capitalize: false)
    }

    open func askWhom() -> String {
        output("Ask whom?")
    }

    open func attackNonCharacter(_ object: String) -> String {
        oneOf(
            "Violence isn't the answer to this one.",
            "Attacking \(object) would accomplish nothing productive.",
            "Your aggressive feelings toward \(object) won't solve anything.",
            "\(object) is immune to your hostility.",
            "Perhaps try a less combative approach with \(object)."
        )
    }

    open func attackSelf() -> String {
        oneOf(
            "I've heard of self-criticism, but that's taking it too far.",
            "That seems counterproductive at best.",
            "Let's redirect that aggression outward, shall we?",
            "Self-preservation suggests otherwise.",
            "There are better ways to deal with your frustrations."
        )
    }

    open func badGrammar(_ text: String) -> String {
        output(text, .notice)
    }

    open func blow() -> String {
        oneOf(
            "You exhale dramatically into the void.",
            "You blow air with great purpose but little effect.",
            "A gust of your breath disturbs the immediate atmosphere, achieving precisely nothing."
        )
    }

    open func blowOn(_ item: String) -> String {
        oneOf(
            "Your breath plays across \(item) to no discernible effect.",
            "Blowing on \(item) accomplishes nothing of note.",
            "\(item) remains unmoved by your exhalations."
        )
    }

    open func breatheOnResponse(_ item: String) -> String {
        output("You breathe on \(item). Nothing happens.")
    }

    open func breatheResponse() -> String {
        oneOf(
            "You draw in a deep, contemplative breath.",
            "You fill your lungs with purpose.",
            "A measured breath steadies your resolve."
        )
    }

    open func briefMode() -> String {
        output(
            """
            Brief mode is now on. Full location descriptions will
            be shown only when you first enter a location.
            """
        )
    }

    open func burnCharacter(_ command: Command, character: String) -> String {
        output("That would be needlessly cruel.")
    }

    open func burnItemWithTool(_ command: Command, item: String, tool: String) -> String {
        oneOf(
            "\(tool) proves woefully inadequate as an implement of combustion for \(item).",
            "Fire refuses to bridge the gap between \(tool) and \(item).",
            "You cannot coax flames from \(tool) to \(item)."
        )
    }

    open func canOnlyDoCharacters(_ command: Command) -> String {
        oneOf(
            "You can only \(command.verbPhrase) people.",
            "That action requires a living target, not an object.",
            "\(command.verbPhrase) works better with actual characters.",
            "You'll need someone animate to \(command.verbPhrase).",
            "Try finding a person to \(command.verbPhrase) instead."
        )
    }

    open func cannotAskAboutThat(_ item: String) -> String {
        oneOf(
            "You can't ask \(item) about anything.",
            "\(item) lacks the capacity for conversation.",
            "Questions require someone who can answer--\(item) cannot.",
            "\(item) remains unresponsive to your queries.",
            "Your interrogation of \(item) yields only silence."
        )
    }

    open func cannotDo(_ command: Command, item: String) -> String {
        oneOf(
            "\(item) stubbornly resists your attempts to \(command.verbPhrase) it.",
            "The universe denies your request to \(command.verbPhrase) \(item).",
            "You cannot \(command.verbPhrase) \(item), much as you might wish otherwise."
        )
    }

    open func cannotDoThat(_ command: Command) -> String {
        oneOf(
            "That defies the fundamental laws of \(command.gerund).",
            "Your ambition to \(command.verbPhrase) that must remain unfulfilled.",
            "You cannot \(command.verbPhrase) that, despite your best intentions."
        )
    }

    open func cannotDoWithThat(
        _ command: Command,
        item: String,
        instrument: String? = nil
    ) -> String {
        output(
            """
            You can't \(command.verb) \(item)
            \(command.preposition ?? "with") \(instrument ?? "that").
            """
        )
    }

    open func cannotDoYourself(_ command: Command) -> String {
        oneOf(
            "The logistics of \(command.gerund) oneself prove insurmountable.",
            "You cannot \(command.verbPhrase) yourself, thankfully.",
            "Self-\(command.gerund) remains beyond your capabilities."
        )
    }

    open func cannotGiveThingsToThat() -> String {
        oneOf(
            "That lacks both the capacity and inclination to receive gifts.",
            "Your generous impulse finds no willing recipient there.",
            "You cannot bestow possessions upon the inanimate."
        )
    }

    open func cannotPutContainerInContained(_ parent: String, child: String) -> String {
        oneOf(
            "The laws of physics sternly forbid putting \(parent) inside its own contents.",
            "You cannot fold space-time sufficiently to put \(parent) in \(child).",
            "That would create a paradox even M.C. Escher would find troubling."
        )
    }

    open func cannotPutItemInItself(_ item: String) -> String {
        oneOf(
            "The universe politely but firmly prevents such recursive madness.",
            "\(item) cannot contain itself--this isn't that kind of story.",
            "You'd need to break several laws of physics to achieve that."
        )
    }

    open func cannotTurnOff() -> String {
        oneOf(
            "It lacks the necessary mechanism for deactivation.",
            "That refuses to acknowledge your attempts to silence it.",
            "No amount of fiddling will turn that off."
        )
    }

    open func cannotTurnOn() -> String {
        oneOf(
            "It remains stubbornly inert despite your ministrations.",
            "That lacks the spark of mechanical life you seek to kindle.",
            "No amount of coaxing will activate that."
        )
    }

    open func characterDoesNotSeemToKnow(_ character: String, topic: String) -> String {
        oneOf(
            "\(character) meets your inquiry about \(topic) with genuine bewilderment.",
            "The mention of \(topic) draws only a blank stare from \(character).",
            "\(character) regards you with polite confusion at the mention of \(topic)."
        )
    }

    open func characterListens(_ character: String, topic: String) -> String {
        oneOf(
            "\(character) listens with patient attention as you expound upon \(topic).",
            "Your discourse on \(topic) holds \(character)'s polite, if not rapt, attention.",
            "\(character) nods thoughtfully as you share your thoughts on \(topic)."
        )
    }

    open func chomp() -> String {
        oneOf(
            "Your teeth clack together in a display of purposeless aggression.",
            "You chomp at the air like a creature possessed.",
            "You gnash your teeth at nothing in particular."
        )
    }

    open func chompAbort() -> String {
        output("You decide against biting anything.")
    }

    open func chompCharacter(_ character: String) -> String {
        oneOf(
            "Your dental assault on \(character) would likely end your relationship, and possibly your teeth.",
            "\(character) deserves better than to be treated like an appetizer.",
            "Biting \(character) falls well outside the bounds of civilized interaction."
        )
    }

    open func chompEnemy(_ enemy: String) -> String {
        oneOf(
            "Resorting to biting would lower you to a rather primitive level of combat.",
            "There are more dignified ways to engage \(enemy) in battle.",
            "Your teeth are not the weapons this conflict requires."
        )
    }

    open func chompItem(_ item: String) -> String {
        oneOf(
            "Your teeth are no match for \(item).",
            "\(item) proves impervious to dental assault.",
            "Biting \(item) would bring only regret and possibly dental bills."
        )
    }

    open func circularDependency(_ error: String) -> String {
        output("Circular dependency error detected: \(error).", .critical)
    }

    open func climbSuccess(_ item: String) -> String {
        output("You climb \(item).")
    }

    open func closed() -> String {
        oneOf(
            "Firmly closed.",
            "Shut tight.",
            "Closed."
        )
    }

    open func containerAlreadyEmpty(_ container: String) -> String {
        output("\(container) is already empty.")
    }

    open func containerContents(_ container: String, contents: String) -> String {
        output("In \(container) you can see \(contents).")
    }

    open func containerIsAlreadyOpen(_ item: String) -> String {
        output("\(item) is already open.")
    }

    open func containerIsClosed(_ item: String) -> String {
        output("\(item) is closed.")
    }

    open func containerIsEmpty(_ item: String) -> String {
        output("\(item) is empty.")
    }

    open func containerIsOpen(_ item: String) -> String {
        output("\(item) is open.")
    }

    open func conversationNeverMind() -> String {
        output("Never mind.")
    }

    open func conversationWhatNext() -> String {
        output("What would you like to do next?")
    }

    open func cryResponse() -> String {
        oneOf(
            "A moment of melancholy overtakes you.",
            "You allow yourself a brief, cathartic sob.",
            "Tears trace silent paths down your face."
        )
    }

    open func currentScore(_ score: Int, maxScore: Int, moves: Int) -> String {
        output(
            """
            Your score is \(score) (total of \(maxScore) points),
            in \(moves) \(moves == 1 ? "move" : "moves").
            """
        )
    }

    open func curse() -> String {
        oneOf(
            "You unleash a cascade of inventive profanity.",
            "Words best left unrecorded escape your lips.",
            "You curse with the passion of a thousand frustrated adventurers."
        )
    }

    open func curseCharacter(_ character: String) -> String {
        output("You curse \(character) under your breath.")
    }

    open func curseTarget(_ item: String) -> String {
        output("You curse \(item) with great feeling.")
    }

    open func cutCharacter(_ character: String) -> String {
        oneOf(
            "Violence against \(character) would solve nothing and create many new problems.",
            "\(character) deserves better than casual brutality.",
            "Your blade must find purpose elsewhere--not in \(character)'s flesh."
        )
    }

    open func cutEnemy(_ enemy: String) -> String {
        oneOf(
            "Perhaps words might succeed where blades would only escalate matters.",
            "Violence begets violence--consider a less sanguinary approach.",
            "Your conflict with \(enemy) need not be written in blood."
        )
    }

    open func cutItem(_ item: String) -> String {
        oneOf(
            "\(item) resists division with stubborn integrity.",
            "Your attempts at bisecting \(item) prove fruitless.",
            "You cannot cut \(item), no matter how you try."
        )
    }

    open func cutPlayer() -> String {
        output("Self-harm is not the solution to your problems.")
    }

    open func danceResponse() -> String {
        oneOf(
            "You execute a series of movements that could generously be called dancing.",
            "You dance with abandon, dignity be damned.",
            "Your impromptu performance would make even the most charitable observer wince."
        )
    }

    open func danceWith(_ item: String) -> String {
        oneOf(
            "\(item) proves a disappointingly rigid dance partner.",
            "You attempt a pas de deux with \(item), but it takes two to tango.",
            "\(item) lacks both rhythm and the capacity for movement."
        )
    }

    open func danceWithEnemy(_ enemy: String) -> String {
        oneOf(
            "\(enemy) prefers a different sort of deadly dance--one involving weapons.",
            "Your invitation to dance meets with hostile incredulity from \(enemy).",
            "\(enemy) interprets your dance request as mockery, and not without reason."
        )
    }

    open func danceWithPartner(_ partner: String) -> String {
        oneOf(
            "You and \(partner) move together in unexpected harmony, if only for a moment.",
            "\(partner) accepts your hand, and together you share a brief, graceful respite.",
            "For a fleeting instant, you and \(partner) find rhythm in each other's movements."
        )
    }

    open func debugRequiresObject() -> String {
        output("DEBUG requires a direct object to examine.")
    }

    open func deflateSuccess(_ item: String) -> String {
        output("You deflate \(item).")
    }

    open func dig() -> String {
        oneOf(
            "The ground here resists your archaeological ambitions.",
            "Digging here would yield nothing but frustration.",
            "This seems an unpromising spot for excavation."
        )
    }

    open func directionIsBlocked(_ reason: String?) -> String {
        output(reason ?? "Something is blocking the way.")
    }

    open func doWhat(_ command: Command) -> String {
        output("\(command.verbPhrase) what?")
    }

    open func doWhere(_ verb: Verb, item: String) -> String {
        output("\(verb) \(item) where?")
    }

    open func doWithWhat(_ command: Command, item: String) -> String {
        output("\(command.verbPhrase) \(item) with what?")
    }

    open func doYouWantToEat(_ item: String) -> String {
        output("Do you mean you want to eat \(item)?")
    }

    open func doorIsClosed(_ door: String) -> String {
        output("\(door) is closed.")
    }

    open func doorIsLocked(_ door: String) -> String {
        output("\(door) is locked.")
    }

    open func doorIsOpen(_ door: String) -> String {
        output("\(door) is open.")
    }

    open func drinkDrinkableDenied(_ item: String) -> String {
        oneOf(
            "Now is not the moment for imbibing \(item).",
            "Circumstances conspire against drinking \(item) at present.",
            "\(item) must wait for a more opportune moment of consumption."
        )
    }

    open func drinkUndrinkableDenied(_ item: String) -> String {
        oneOf(
            "\(item) was never meant to pass human lips.",
            "Your throat closes at the mere thought of drinking \(item).",
            "\(item) belongs to the category of things decidedly not potable."
        )
    }

    open func dropped() -> String {
        oneOf(
            "Dropped.",
            "Released.",
            "Relinquished."
        )
    }

    open func eatEdibleDenied(_ item: String) -> String {
        oneOf(
            "Your appetite for \(item) must wait for better circumstances.",
            "Now is not the time to consume \(item).",
            "\(item) remains tantalizingly out of reach of your digestive ambitions."
        )
    }

    open func eatInedibleDenied(_ item: String) -> String {
        oneOf(
            "\(item) falls well outside the realm of culinary possibility.",
            "Your digestive system firmly vetoes the consumption of \(item).",
            "\(item) is many things, but edible is not among them."
        )
    }

    open func emptyInput() -> String {
        oneOf(
            "I beg your pardon?",
            "Come again?",
            "The universe awaits your command.",
            "Silence speaks volumes, but accomplishes little."
        )
    }

    open func emptyIntoTargetSuccess(_ container: String, items: String, target: String) -> String {
        output("You empty \(items) from \(container) into \(target).")
    }

    open func emptyOntoGroundSuccess(_ container: String, items: String, count: Int) -> String {
        output(
            "You empty \(container), and \(items) \(count == 1 ? "falls" : "fall") to the ground."
        )
    }

    open func endOfGameOptions() -> String {
        output("Would you like to RESTART, RESTORE a saved game, or QUIT?")
    }

    open func examineYourself(
        healthRatio: Double = 1
    ) -> String {
        switch true {
        case healthRatio == 0:
            oneOf(
                """
                You conduct a thorough self-examination and reach an inescapable conclusion:
                you are profoundly, irreversibly dead.
                """,
                """
                Against all logic, you examine your deceased form.
                The diagnosis is not encouraging.
                """,
                """
                You appear to be examining yourself from somewhere outside your body,
                which is never a good sign. You are decidedly dead.
                """,
                """
                A careful inventory of your condition reveals a critical shortage of life.
                You are, in technical terms, dead.
                """,
                """
                You note with detached interest that you are dead.
                This complicates matters somewhat.
                """
            )
        case healthRatio < 0.15:
            output(
                """
                You're a breath away from oblivion. Every movement is agony, your vision
                swims with darkness, and you can barely remain conscious.
                """
            )
        case healthRatio < 0.25:
            output(
                """
                You're in critical condition. Blood seeps from numerous wounds, and you
                struggle to stay upright. Death feels uncomfortably close.
                """
            )
        case healthRatio < 0.35:
            output(
                """
                You're badly wounded. Pain radiates through your body with every heartbeat,
                and your strength is failing. You need help, desperately.
                """
            )
        case healthRatio < 0.45:
            output(
                """
                You're seriously hurt. Deep injuries throb with persistent pain, and you're
                moving with obvious difficulty. This is getting dangerous.
                """
            )
        case healthRatio < 0.55:
            output(
                """
                You're wounded and weary. Several painful injuries slow your movements,
                and you're definitely not at your best. You've been better.
                """
            )
        case healthRatio < 0.65:
            output(
                """
                You're battered but functional. Various cuts and bruises make themselves
                known, but nothing that won't heal with time.
                """
            )
        case healthRatio < 0.75:
            output(
                """
                You're somewhat worse for wear. A collection of minor injuries and aches
                remind you that adventure has its price.
                """
            )
        case healthRatio < 0.85:
            output(
                """
                You're lightly scuffed up. A few scrapes and bruises mark your recent
                activities, but nothing a good night's rest won't fix.
                """
            )
        case healthRatio < 0.95:
            output(
                """
                You're nearly pristine, with only the faintest marks to show for your
                troubles. You've had worse paper cuts.
                """
            )
        default:
            oneOf(
                """
                You are in peak condition, unmarred by the world's
                various attempts to damage you.
                """,
                """
                As good-looking as ever, which is to say, adequately presentable.
                """,
                """
                You are magnificently intact, without so much as a misplaced hair
                to suggest adventure.
                """,
                """
                You examine yourself with satisfaction. Not a scratch.
                The universe has failed to leave its mark.
                """,
                """
                You are in pristine condition, as if freshly minted for adventure.
                """
            )
        }
    }

    open func expectedDirection() -> String {
        output("Which direction?")
    }

    open func expectedParticleAfterVerb(
        _ expectedParticle: String,
        verb: Verb,
        found: Verb
    ) -> String {
        output("Expected '\(expectedParticle)' after '\(verb)' but found '\(found).'")
    }

    open func expectedParticleButReachedEnd(_ expectedParticle: String) -> String {
        output("Expected '\(expectedParticle)' but reached end of input.")
    }

    open func extinguishFail(_ command: Command, item: String) -> String {
        oneOf(
            "\(item) refuses to be \(command.pastParticiple).",
            "Your attempts to \(command.verbPhrase) \(item) come to naught.",
            "\(item) cannot be \(command.pastParticiple) by any means available to you."
        )
    }

    open func extinguishSuccess(_ command: Command, item: String) -> String {
        output("You \(command.verbPhrase) \(item).")
    }

    open func feelNothingUnusual(_ verb: Verb) -> String {
        oneOf(
            "You feel nothing unexpected.",
            "Your tactile exploration yields no surprises.",
            "Nothing unusual meets your questing fingers."
        )
    }

    open func fillContainerWithSource(_ container: String, source: String) -> String {
        output("You fill \(container) from \(source).")
    }

    open func fillContainerWithWhat(_ container: String) -> String {
        output("Fill \(container) with what?")
    }

    open func gameRestored() -> String {
        output("Game restored.")
    }

    open func gameSaved(_ path: String) -> String {
        output("Game saved.")
    }

    open func giveItemToWhom(_ item: String) -> String {
        output("Give \(item) to whom?")
    }

    open func giveWhatToRecipient(_ recipient: String) -> String {
        output("Give what to \(recipient)?")
    }

    open func giveWhatToWhom() -> String {
        output("Give what to whom?")
    }

    open func goWhere() -> String {
        oneOf(
            "The compass awaits your decision.",
            "Which direction calls to your wandering spirit?",
            "Where would you have your feet carry you?"
        )
    }

    open func goodbye() -> String {
        oneOf(
            "Farewell, brave soul!",
            "Until we meet again in another tale...",
            "May your adventures elsewhere prove fruitful!"
        )
    }

    open func help() -> String {
        output(
            """
            This is an interactive fiction game. You control the story by typing commands.

            Common commands:

            - LOOK or L - Look around your current location
            - EXAMINE <object> or X <object> - Look at something closely
            - TAKE <object> or GET <object> - Pick up an item
            - DROP <object> - Put down an item you're carrying
            - INVENTORY or I - See what you're carrying
            - GO <direction> or just <direction> - Move in a direction (N, S, E, W, etc.)
            - OPEN <object> - Open doors, containers, etc.
            - CLOSE <object> - Close doors, containers, etc.
            - PUT <object> IN <container> - Put something in a container
            - PUT <object> ON <surface> - Put something on a surface
            - SAVE - Save your game
            - RESTORE - Restore a saved game
            - QUIT - End the game

            You can use multiple objects with some commands (TAKE ALL, DROP SWORD AND SHIELD).

            Try different things--experimentation is part of the fun!
            """
        )
    }

    open func holdingRevealsNothingSpecial(_ item: String) -> String {
        oneOf(
            "Your hands find no hidden secrets in \(item).",
            "Holding \(item) yields no revelations beyond the obvious.",
            "\(item) keeps its mysteries, if any, well hidden from your grasp."
        )
    }

    open func inContainerYouCanSee(
        _ container: ItemProxy,
        contents: [ItemProxy],
        also: Bool
    ) async -> String {
        let onIn = await container.isSurface ? "On" : "In"
        let theContainer = await container.withDefiniteArticle
        let contentListing = await contents.listWithIndefiniteArticles() ?? "*"
        return output(
            "\(onIn) \(theContainer) you \(also ? "also" : "can") see \(contentListing)."
        )
    }

    open func inflateSuccess(_ item: String) -> String {
        output("You inflate \(item).")
    }

    open func internalEngineError(_ error: String) -> String {
        output("Internal error: \(error)")
    }

    open func internalParseError(_ error: String) -> String {
        output("Parse error: \(error)")
    }

    open func invalidDirection() -> String {
        oneOf(
            "That way lies only disappointment.",
            "You can't go that way.",
            "Your path does not extend in that direction.",
            "The universe conspires against your movement that way."
        )
    }

    open func invalidIndirectObject(_ object: String) -> String {
        oneOf(
            "\(object) proves spectacularly unsuited for that purpose.",
            "That's not what \(object) was designed for, and it shows.",
            "\(object) refuses to participate in such shenanigans."
        )
    }

    open func itemAlreadyOpen(_ item: String) -> String {
        output("\(item) is already open.")
    }

    open func itemBeginsToBurn(_ item: String) -> String {
        output("\(item) begins to burn.")
    }

    open func itemGivenTo(_ item: String, recipient: String) -> String {
        output("You give \(item) to \(recipient).")
    }

    open func itemIsAlreadyWorn(_ item: String) -> String {
        output("You are already wearing \(item).")
    }

    open func itemIsLocked(_ item: String) -> String {
        output("\(item) is locked.")
    }

    open func itemIsNotWorn(_ item: String) -> String {
        output("You aren't wearing \(item).")
    }

    open func itemIsNowUnlocked(_ item: String) -> String {
        output("\(item) is now unlocked.")
    }

    open func itemNotAccessible(_ item: String) -> String {
        oneOf(
            "\(item) lurks beyond your reach.",
            "\(item) remains frustratingly inaccessible.",
            "You cannot reach \(item) from here."
        )
    }

    open func itemNotHeld(_ item: String) -> String {
        output("You aren't holding \(item).")
    }

    open func itemNotInScope(_ noun: String) -> String {
        oneOf(
            "No \(noun) graces this vicinity with its presence.",
            "You search in vain for any \(noun) here.",
            "The \(noun) you seek is conspicuously absent."
        )
    }

    open func itemNotInflated(_ item: String) -> String {
        output("\(item) is not inflated.")
    }

    open func itemTooLargeForContainer(_ item: String, container: String) -> String {
        output("\(item) won't fit in \(container).")
    }

    open func itsRightHere() -> String {
        oneOf(
            "It stands before you in all its mundane glory!",
            "Behold! It's right here!",
            "Your powers of observation are truly remarkable--it's right here!"
        )
    }

    open func jump() -> String {
        oneOf(
            "You spring upward with temporary defiance of gravity.",
            "You leap enthusiastically, achieving modest altitude.",
            "You jump on the spot, gravity's brief adversary."
        )
    }

    open func jumpCharacter(_ character: String) -> String {
        oneOf(
            "Leaping upon \(character) would be an extraordinary breach of personal space.",
            "\(character) is not a trampoline for your acrobatic ambitions.",
            "Your aerial assault on \(character) would end badly for all involved."
        )
    }

    open func jumpEnemy(_ enemy: String) -> String {
        oneOf(
            "Pouncing on \(enemy) seems tactically inadvisable.",
            "Your jumping attack would likely meet with sharp resistance from \(enemy).",
            "Leaping at \(enemy) invites a violent response you're unprepared for."
        )
    }

    open func jumpObject(_ item: String) -> String {
        output("You can't jump over \(item).")
    }

    open func kickCharacter(_ character: String) -> String {
        oneOf(
            "Kicking \(character) would irreparably damage your relationship, among other things.",
            "\(character) has done nothing to deserve such unprovoked violence.",
            "Your foot and \(character)'s personage must remain forever unacquainted."
        )
    }

    open func kickHeldObject(_ item: String) -> String {
        oneOf(
            "The logistics of kicking \(item) while holding it defy basic anatomy.",
            "You'd need to let go of \(item) first--kicking requires distance.",
            "Your grip on \(item) rather precludes the kicking option."
        )
    }

    open func kickLargeObject(_ item: String) -> String {
        oneOf(
            "Your foot meets \(item) in an unequal contest. Your foot loses.",
            "Kicking \(item) would injure your pride and possibly your toes.",
            "\(item) absorbs your kick with monumental indifference."
        )
    }

    open func kickSmallObject(_ item: String) -> String {
        oneOf(
            "You nudge \(item) with your foot. The universe yawns.",
            "\(item) shifts slightly under your half-hearted kick.",
            "Your foot makes contact with \(item). History remains unchanged."
        )
    }

    open func kissCharacter(_ character: String) -> String {
        oneOf(
            "Your romantic impulses toward \(character) must remain unexpressed.",
            "\(character) has given no indication of welcoming such intimate contact.",
            "The moment for kissing \(character) has neither arrived nor been invited."
        )
    }

    open func kissEnemy(_ enemy: String) -> String {
        oneOf(
            "Romance and warfare make poor bedfellows, especially with \(enemy).",
            "Your lips approaching \(enemy) would likely meet steel rather than flesh.",
            "That's an unusual combat strategy, and \(enemy) seems unlikely to reciprocate."
        )
    }

    open func kissObject(_ item: String) -> String {
        oneOf(
            "You and \(item) lack the necessary chemistry.",
            "\(item) remains unmoved by your romantic overtures.",
            "Your lips and \(item) are destined never to meet."
        )
    }

    open func kissSelf() -> String {
        oneOf(
            "Your flexibility, while admirable, has limits.",
            "Self-affection requires a level of contortion beyond your abilities.",
            "You'd need a mirror and considerably less dignity to manage that."
        )
    }

    open func laugh() -> String {
        oneOf(
            "Laughter bubbles up from somewhere deep within.",
            "You laugh with genuine mirth.",
            "A hearty chuckle escapes your lips."
        )
    }

    open func laughAbout(_ entity: String) -> String {
        output("You laugh about \(entity).")
    }

    open func laughAt(_ entity: String) -> String {
        output("You laugh at \(entity). How rude!")
    }

    open func lightIsNowBurning(_ item: String) -> String {
        output("You light \(item). You can see your surroundings now.")
    }

    open func lightIsNowOff(_ item: String) -> String {
        output("\(item) is now off.")
    }

    open func lightRequiresFlame(_ item: String) -> String {
        output("You need something to light \(item) with.")
    }

    open func lightRequiresIgniter(_ item: String, igniter: String) -> String {
        output("You can't light \(item) with \(igniter).")
    }

    open func listen() -> String {
        oneOf(
            "The world holds its breath as you listen, revealing nothing of import.",
            "You strain your ears but detect only the ordinary soundtrack of existence.",
            "Silence, punctuated only by the mundane."
        )
    }

    open func listenFor(_ item: String) -> String {
        output("You listen for \(item) but hear nothing.")
    }

    open func listenInDarkness() -> String {
        output("You strain your ears in the darkness but hear nothing unusual.")
    }

    open func listenTo(_ item: String) -> String {
        output("You listen to \(item). You hear nothing unusual.")
    }

    open func lockSuccess(_ item: String) -> String {
        output("\(item) is now locked.")
    }

    open func maximumVerbosity() -> String {
        output(
            """
            Maximum verbosity. Full location descriptions will
            be shown every time you enter a location.
            """
        )
    }

    open func modifierMismatch(_ noun: String, modifiers: [String]) -> String {
        output("You can't see any \(modifiers.joined(separator: " ")) \(noun) here.")
    }

    open func move() -> String {
        oneOf(
            "You pace about with restless energy.",
            "You shift your position, accomplishing little.",
            "Nervous movement carries you nowhere in particular."
        )
    }

    open func moveItem(_ item: String) -> String {
        oneOf(
            "\(item) resists relocation with impressive stubbornness.",
            "Moving \(item) exceeds your current capabilities.",
            "\(item) remains firmly where it is, despite your efforts."
        )
    }

    open func moveItemToTarget(_ item: String, target: String) -> String {
        oneOf(
            "The journey from \(item) to \(target) cannot be made.",
            "You cannot forge a path between \(item) and \(target).",
            "Moving \(item) to \(target) proves impossible."
        )
    }

    open func multipleObjectsNotSupported(_ command: Command) -> String {
        output("The verb '\(command.verbPhrase)' doesn't support multiple objects.")
    }

    open func nibbleWhat() -> String {
        output("Nibble what?")
    }

    open func noWhat() -> String {
        output("No what?")
    }

    open func nothing() -> String {
        output("nothing", capitalize: false)
    }

    open func nothingHereToDo(_ command: Command) -> String {
        output("There is nothing here to \(command.verbPhrase).")
    }

    open func nothingOfInterestInside(_ item: String) -> String {
        oneOf(
            "The interior of \(item) disappoints with its mundane emptiness.",
            "Within \(item) lies nothing but unfulfilled expectations.",
            "\(item)'s inner mysteries prove remarkably unmysterious."
        )
    }

    open func nothingOfInterestUnder(_ item: String) -> String {
        oneOf(
            "Beneath \(item) lurks only disappointment and possibly dust.",
            "Your investigation under \(item) reveals a profound absence of interest.",
            "The space beneath \(item) harbors no secrets worth discovering."
        )
    }

    open func nothingSpecialAbout(_ item: String) -> String {
        oneOf(
            "\(item) reveals itself to be exactly what it appears--nothing more, nothing less.",
            "Your scrutiny of \(item) yields no hidden depths or secret purposes.",
            "\(item) stubbornly remains ordinary despite your thorough examination."
        )
    }

    open func nothingToDrinkIn(_ container: String) -> String {
        oneOf(
            "\(container) offers nothing to slake your thirst.",
            "Your hopes for liquid refreshment in \(container) are sadly misplaced.",
            "\(container) contains many things perhaps, but potable liquid is not among them."
        )
    }

    open func nothingToTakeHere() -> String {
        oneOf(
            "This place offers nothing portable worth acquiring.",
            "Your acquisitive instincts find no satisfaction here.",
            "The local inventory of takeable items stands at precisely zero."
        )
    }

    open func nothingWrittenOn(_ item: String) -> String {
        oneOf(
            "\(item) bears no inscription, message, or literary content whatsoever.",
            "The surface of \(item) remains unmarked by pen, quill, or chisel.",
            "\(item) offers no text for your eager eyes to decode."
        )
    }

    open func nowDark() -> String {
        oneOf(
            "Darkness rushes in like a living thing.",
            "The world vanishes into absolute blackness.",
            "You are swallowed by impenetrable shadow."
        )
    }

    open func opened(_ item: String) -> String {
        oneOf(
            "You open \(item) with a satisfying sense of purpose.",
            "\(item) yields to your efforts and swings open.",
            "With practiced ease, you open \(item)."
        )
    }

    open func openingRevealsContents(_ container: String, contents: String) -> String {
        oneOf(
            "As \(container) opens, it reveals \(contents) within.",
            "\(container) parts to disclose \(contents), previously hidden from view.",
            "Opening \(container) brings \(contents) into the light."
        )
    }

    open func playerCannotCarryMore() -> String {
        oneOf(
            "Your burden has reached its practical limit.",
            "You're juggling quite enough already.",
            "Your hands are full and your pockets protest."
        )
    }

    open func playerReferenceCannotBeModified(_ reference: String, modifiers: [String]) -> String {
        output(
            """
            Player reference '\(reference)' cannot be modified
            by '\(modifiers.joined(separator: " "))'.
            """
        )
    }

    open func pourCannotPourItself() -> String {
        oneOf(
            "The physics of self-pouring remain theoretical at best.",
            "That would require a Klein bottle and a suspension of disbelief.",
            "You cannot pour something onto itself without breaking reality."
        )
    }

    open func pourFail() -> String {
        oneOf(
            "That lacks the necessary fluidity for pouring.",
            "Pouring requires a more liquid state of matter.",
            "That stubbornly maintains its unpourable nature."
        )
    }

    open func pourItemOn(_ item: String, target: String) -> String {
        output("You pour \(item) on \(target).")
    }

    open func pourItemOnSelf(_ item: String) -> String {
        output("You pour \(item) on yourself. How refreshing.")
    }

    open func pourItemOnWhat(_ item: String) -> String {
        output("Pour \(item) on what?")
    }

    open func pourTargetFail() -> String {
        output("You can't pour anything on that.")
    }

    open func prepositionMismatch(
        _ verb: String,
        expected: String,
        found: String
    ) -> String {
        output(
            "Preposition mismatch for verb '\(verb)' (expected '\(expected)', found '\(found)')."
        )
    }

    open func pronounCannotBeModified(_ pronoun: String) -> String {
        output("Pronouns like '\(pronoun)' usually cannot be modified.")
    }

    open func pronounNotSet(_ pronoun: String) -> String {
        output("I don't know what '\(pronoun)' refers to.")
    }

    open func pronounRefersToOutOfScopeItem(_ pronoun: String) -> String {
        output("You can't see what '\(pronoun)' refers to right now.")
    }

    open func pullCharacter(_ character: String) -> String {
        oneOf(
            "\(character) is not a rope to be tugged at your convenience.",
            "Yanking \(character) about would strain both fabric and friendship.",
            "\(character) prefers locomotion under their own power."
        )
    }

    open func pullEnemy(_ enemy: String) -> String {
        oneOf(
            "Grabbing \(enemy) would escalate tensions beyond recovery.",
            "Your hands reaching for \(enemy) would provoke immediate retaliation.",
            "Physical grappling with \(enemy) seems profoundly unwise."
        )
    }

    open func pullObject(_ item: String) -> String {
        oneOf(
            "\(item) resists your tugging with stoic determination.",
            "No amount of pulling will budge \(item).",
            "You strain against \(item) to no avail."
        )
    }

    open func pushCharacter(_ character: String) -> String {
        oneOf(
            "Shoving \(character) would cross lines better left uncrossed.",
            "\(character) maintains their position through dignity, not your pushing.",
            "Your hands and \(character)'s person should maintain a respectful distance."
        )
    }

    open func pushEnemy(_ enemy: String) -> String {
        oneOf(
            "Pushing \(enemy) would transform tension into outright conflict.",
            "Your shove would be answered with considerably more force by \(enemy).",
            "Physical provocation of \(enemy) invites consequences you'd rather avoid."
        )
    }

    open func pushObject(_ item: String) -> String {
        oneOf(
            "\(item) meets your push with immovable resistance.",
            "You lean into \(item), but it refuses to acknowledge your efforts.",
            "Pushing \(item) proves an exercise in futility."
        )
    }

    open func putCannotPutOnSelf(_ item: String) -> String {
        oneOf(
            "The topology required to put \(item) on itself eludes you.",
            "\(item) cannot rest upon itself--that way lies madness.",
            "You'd need to fold space to put \(item) on itself."
        )
    }

    open func putItemOn(_ item: String) -> String {
        output("You put on \(item).")
    }

    open func putItemOnCircular(_ item: String, container: String) -> String {
        output("You can't put \(item) on \(container) because \(container) is on \(item).")
    }

    open func putItemOnNonSurface(_ item: String, container: String) -> String {
        output("You can't put things on \(container).")
    }

    open func putMeOn() -> String {
        oneOf(
            "You are not an object to be placed upon things.",
            "That would require you to be both subject and object simultaneously.",
            "The verb 'put' requires less self-referential gymnastics."
        )
    }

    open func putOnBadTarget(_ item: String) -> String {
        oneOf(
            "That surface rejects \(item) with prejudice.",
            "\(item) and that surface are incompatible.",
            "You cannot balance \(item) there, physics be damned."
        )
    }

    open func putOnWhat(_ item: String) -> String {
        output("Put \(item) on what?")
    }

    open func quitCancelled() -> String {
        oneOf(
            "The adventure continues!",
            "Death postponed--onwards!",
            "Your story isn't over yet."
        )
    }

    open func quitScoreAndPrompt(_ score: Int, maxScore: Int, moves: Int) -> String {
        output(
            """
            \(currentScore(score, maxScore: maxScore, moves: moves))
            Do you wish to leave the game? (Y is affirmative):
            """
        )
    }

    open func removeAll() -> String {
        output("You remove everything you're wearing.")
    }

    open func responseNotUnderstood() -> String {
        oneOf(
            "Your response defies my comprehension.",
            "I'm afraid that answer eludes my understanding.",
            "Could you rephrase that in terms a humble parser might grasp?"
        )
    }

    open func restartCancelled() -> String {
        output("Restart cancelled.")
    }

    open func restartConfirmation() -> String {
        output(
            """
            If you restart now you will lose any unsaved progress.
            Are you sure you want to restart? (Y is affirmative):
            """
        )
    }

    open func restartRestoreQuit() -> String {
        output("Please type RESTART, RESTORE, or QUIT.")
    }

    open func restarting() -> String {
        output("Restarting the game...")
    }

    open func restoreCancelled() -> String {
        output("Restore cancelled.")
    }

    open func restoreConfirmation() -> String {
        output(
            """
            If you restore your saved game now you will lose any unsaved progress.
            Are you sure you want to restore? (Y is affirmative):
            """
        )
    }

    open func restoreFailed(_ error: String) -> String {
        output("Restore failed: \(error)")
    }

    open func restoring() -> String {
        output("Restoring game...")
    }

    open func roomIsDark() -> String {
        oneOf(
            "Darkness presses against you like a physical thing. You are effectively blind.",
            "The darkness here is absolute, consuming all light and hope of sight.",
            """
            You stand in a depthless black where even your thoughts seem to whisper,
            careful not to make a sound.
            """,
            """
            This is the kind of dark that swallows shapes and edges,
            leaving only breath and heartbeat to prove you exist.
            """,
            """
            Light feels theoretical here--an idea someone once had,
            now forgotten by the room itself.
            """,
        )
    }

    open func rubCharacter(_ verb: Verb, character: String) -> String {
        output("I don't think \(character) would appreciate that.")
    }

    open func rubEnemy(_ verb: Verb, enemy: String) -> String {
        output("That would be quite inappropriate.")
    }

    open func rubObject(_ verb: Verb, item: String) -> String {
        oneOf(
            "Your vigorous rubbing of \(item) produces neither genies nor results.",
            "You polish \(item) with your hand. It remains stubbornly unmagical.",
            "\(item) endures your rubbing without transformation or complaint."
        )
    }

    open func rubSelf(_ verb: Verb) -> String {
        oneOf(
            "You rub yourself vigorously, achieving little beyond mild warmth.",
            "Your self-massage provides minimal therapeutic value.",
            "You give yourself a rub. The universe politely looks away."
        )
    }

    open func saveFailed(_ error: String) -> String {
        output("Save failed: '\(error)'")
    }

    open func shakeCharacter(_ verb: Verb, character: String) -> String {
        oneOf(
            "Rattling \(character) like a maraca would be most undignified.",
            "\(character) is not a snow globe requiring agitation.",
            "Your urge to shake \(character) must remain forever unfulfilled."
        )
    }

    open func shakeEnemy(_ verb: Verb, enemy: String) -> String {
        oneOf(
            "Attempting to shake sense into \(enemy) would likely shake teeth loose instead.",
            "\(enemy) would respond to shaking with considerably more violent movements.",
            "Your hands on \(enemy) would precipitate immediate combat."
        )
    }

    open func shakeObject(_ verb: Verb, item: String) -> String {
        oneOf(
            "You give \(item) a vigorous shake. Nothing rattles, breaks, or emerges.",
            "\(item) tolerates your shaking with stoic indifference.",
            "Your agitation of \(item) produces no observable effect."
        )
    }

    open func shakeSelf(_ verb: Verb) -> String {
        oneOf(
            "You shake yourself like a wet dog, dignity be damned.",
            "A vigorous self-shake loosens your muscles if not your troubles.",
            "You give yourself a thorough rattling. It's oddly satisfying."
        )
    }

    open func sing(_ verb: Verb) -> String {
        oneOf(
            "You unleash a melodic assault upon the immediate vicinity.",
            "Your voice rises in what you generously call song.",
            "You sing with more enthusiasm than skill."
        )
    }

    open func singToCharacter(_ verb: Verb, character: String) -> String {
        oneOf(
            "\(character) endures your impromptu serenade with admirable patience.",
            "Your song draws a smile from \(character), though whether from joy or pity remains unclear.",
            "\(character) listens to your performance with diplomatic appreciation."
        )
    }

    open func singToEnemy(_ verb: Verb, enemy: String) -> String {
        oneOf(
            "Your aria only deepens \(enemy)'s desire to silence you permanently.",
            "\(enemy) finds your singing more offensive than any insult.",
            "Music may soothe the savage beast, but \(enemy) proves the exception."
        )
    }

    open func singToObject(_ command: Command, item: String) -> String {
        oneOf(
            "Your serenade to \(item) falls upon deaf... well, absent ears.",
            "\(item) remains unmoved by your musical offering, lacking the capacity for appreciation.",
            "You pour your heart out in song to \(item). The silence that follows is deafening."
        )
    }

    open func smellCharacter(_ verb: Verb, character: String) -> String {
        oneOf(
            "Sniffing \(character) would violate numerous social conventions.",
            "\(character)'s personal aroma remains their private business.",
            "Your olfactory curiosity about \(character) must remain unsatisfied."
        )
    }

    open func smellEnemy(_ verb: Verb, enemy: String) -> String {
        output("You detect nothing unusual about \(enemy.possessive) scent.")
    }

    open func smellNothingUnusual(_ verb: Verb) -> String {
        oneOf(
            "The air carries only its usual secrets.",
            "Nothing remarkable greets your nostrils.",
            "You detect no olfactory surprises."
        )
    }

    open func smellObject(_ verb: Verb, item: String) -> String {
        oneOf(
            "The scent of \(item) proves unremarkable to your discerning nostrils.",
            "\(item) smells exactly as you'd expect, which is to say, not particularly noteworthy.",
            "Your olfactory investigation of \(item) yields no aromatic surprises."
        )
    }

    open func smellSelf(_ verb: Verb) -> String {
        oneOf(
            "Your personal aroma falls within acceptable parameters.",
            "You smell of adventure, sweat, and determination--the usual.",
            "Your scent speaks of recent exertions but nothing alarming."
        )
    }

    open func some(_ items: String) -> String {
        output("some \(items)", capitalize: false)
    }

    open func somethingDisappears(toward direction: Direction?) -> String {
        switch direction {
        case .none: "from sight"
        case .down: "down and out of sight"
        case .east: "to the east"
        case .inside: "in and out of sight"
        case .north: "to the north"
        case .northeast: "to the northeast"
        case .northwest: "to the northwest"
        case .outside: "out and out of sight"
        case .south: "to the south"
        case .southeast: "to the southeast"
        case .southwest: "to the southwest"
        case .up: "up and out of sight"
        case .west: "to the west"
        }
    }

    open func specificVerbRequired(_ requiredVerb: String) -> String {
        output("This syntax requires the specific verb '\(requiredVerb).'")
    }

    open func squeezeCharacter(_ command: Command, character: String) -> String {
        oneOf(
            "You consider \(command.gerund) \(character), then wisely think better of it.",
            "\(character) is unlikely to appreciate being \(command.pastParticiple) right now.",
            "Perhaps don't \(command.verb) \(character). Relations tend to sour after that.",
            "You reach toward \(character) and pause. This is not the moment for \(command.gerund).",
            "\(command.verb) \(character)? Bold choice. Perhaps try something less personal."
        )
    }

    open func squeezeEnemy(_ command: Command, enemy: String) -> String {
        oneOf(
            "That would be more provocative than productive.",
            "\(command.gerund) \(enemy) seems… ill-advised in the current climate.",
            "You consider \(command.gerund) \(enemy) and imagine the outcome. You reconsider.",
            "Aggression is one thing; \(command.gerund) \(enemy) is quite another.",
            "This is combat, not a cuddle. Best not \(command.verb) \(enemy)."
        )
    }

    open func squeezeObject(_ command: Command, item: String) -> String {
        oneOf(
            "You \(command.verb) \(item). It remains stubbornly unsqueezeworthy.",
            "You \(command.verb) \(item) with determination. Nothing of note occurs.",
            "You apply pressure to \(item). The universe declines to be impressed.",
            "You give \(item) a firm \(command.gerund). It yields little and reveals less.",
            "You \(command.verb) \(item). If it has secrets, they are not released by squeezing."
        )
    }

    open func squeezeSelf(_ command: Command) -> String {
        oneOf(
            "You embrace yourself in a moment of self-comfort.",
            "A reassuring self-squeeze bolsters your spirits.",
            "You give yourself a comforting hug. It helps, a little."
        )
    }

    open func surfaceContents(_ surface: String, contents: String) -> String {
        output("On \(surface) you can see \(contents).")
    }

    open func takeItemNotInContainer(_ item: String, container: String) -> String {
        output("\(item) is not in \(container).")
    }

    open func taken() -> String {
        oneOf(
            "Taken.\n",
            "Acquired.\n",
            "Got it.\n"
        )
    }

    open func takenImplied() -> String {
        output("(Taken)\n")
    }

    open func targetIsNotAContainer(_ item: String) -> String {
        output("You can't put things in \(item).")
    }

    open func tasteCharacter(_ verb: Verb, character: String) -> String {
        oneOf(
            "Your culinary interest in \(character) crosses every conceivable boundary.",
            "Tasting \(character) would end your relationship and possibly your freedom.",
            "\(character) is a person, not a delicacy to be sampled."
        )
    }

    open func tasteEnemy(_ verb: Verb, enemy: String) -> String {
        oneOf(
            "Your tongue approaching \(enemy) would meet violent opposition.",
            "Tasting \(enemy) ranks among history's worst battle strategies.",
            "That's a level of intimacy \(enemy) would answer with sharp steel."
        )
    }

    open func tasteNothingUnusual(_ verb: Verb) -> String {
        oneOf(
            "Your palate detects nothing remarkable.",
            "The flavor profile proves disappointingly ordinary.",
            "You taste nothing worth noting."
        )
    }

    open func tasteObject(_ verb: Verb, item: String) -> String {
        oneOf(
            "Your tongue's brief encounter with \(item) reveals no gustatory secrets.",
            "\(item) tastes remarkably like you'd expect \(item) to taste.",
            "The flavor of \(item) will not be making any culinary history."
        )
    }

    open func tasteSelf(_ verb: Verb) -> String {
        oneOf(
            "You sample your own flavor. The results are predictably salty.",
            "Your auto-gustatory exploration yields no surprising flavors.",
            "You taste vaguely of determination and poor life choices."
        )
    }

    open func tellCharacter(_ character: String) -> String {
        oneOf(
            "What knowledge would you share with \(character)?",
            "\(character) awaits the subject of your discourse.",
            "Your voice trails off, leaving \(character) waiting expectantly."
        )
    }

    open func tellCharacterAboutTopic(_ character: String, topic: String) -> String {
        oneOf(
            "You share your knowledge of \(topic) with \(character), who listens intently.",
            "\(character) absorbs your words about \(topic) with thoughtful consideration.",
            "Your explanation of \(topic) finds an attentive audience in \(character)."
        )
    }

    open func tellEnemy(_ enemy: String) -> String {
        oneOf(
            "\(enemy) prefers action to words, specifically violent action.",
            "Conversation with \(enemy) has given way to darker intentions.",
            "\(enemy) responds to your overture with hostile silence."
        )
    }

    open func tellEnemyAboutTopic(_ enemy: String, topic: String) -> String {
        oneOf(
            "Your discourse on \(topic) falls upon \(enemy)'s deliberately deaf ears.",
            "\(enemy) dismisses your words about \(topic) with contemptuous silence.",
            "The subject of \(topic) cannot bridge the chasm between you and \(enemy)."
        )
    }

    open func tellItemAboutTopic(_ item: String, topic: String) -> String {
        oneOf(
            "\(item) lacks the necessary consciousness to appreciate your discourse on \(topic).",
            "Your eloquent exposition on \(topic) is wasted on \(item)'s inanimate indifference.",
            "\(item) remains unmoved by your knowledge of \(topic), being unmovable by words in general."
        )
    }

    open func tellObject(_ item: String) -> String {
        oneOf(
            "\(item) maintains the silence of the truly inanimate.",
            "Your words bounce off \(item) without effect or acknowledgment.",
            "Communication requires a listener, which \(item) decidedly is not."
        )
    }

    open func tellSelfAbout(_ item: String?) -> String {
        oneOf(
            "You engage in a spirited internal dialogue about \(item ?? "various matters").",
            "Your monologue on \(item ?? "sundry topics") echoes in the silence.",
            "You become your own audience for thoughts on \(item ?? "this and that")."
        )
    }

    open func tellTopic() -> String {
        output("Tell about what?")
    }

    open func tellUniverseAbout(_ item: String?) -> String {
        oneOf(
            "You share your thoughts on \(item ?? "existence") with the cosmic void.",
            "The universe listens with infinite patience as you expound on \(item ?? "everything and nothing").",
            "Your words about \(item ?? "the nature of things") dissipate into the eternal silence."
        )
    }

    open func tellWhom() -> String {
        oneOf(
            "To whom would you address these words?",
            "Your voice trails off, seeking an audience.",
            "Who should receive this wisdom you're eager to share?"
        )
    }

    open func thatsNotSomethingYouCan(_ command: Command) -> String {
        output("That's not something you can \(command.verbPhrase).")
    }

    open func the(_ item: String) -> String {
        output("the \(item)", capitalize: false)
    }

    open func thereAreIndefiniteItemsHere(_ items: [ItemProxy]) async -> String {
        let isAre =
            if items.count == 1 {
                await items.first?.hasFlag(.isPlural) == true ? "are" : "is"
            } else {
                "are"
            }
        let listWithDefiniteArticles = await items.listWithIndefiniteArticles() ?? "nothing"
        return oneOf(
            "There \(isAre) \(listWithDefiniteArticles) here.",
            "You can see \(listWithDefiniteArticles) here.",
            "Present in this location \(isAre) \(listWithDefiniteArticles)."
        )
    }

    open func think() -> String {
        oneOf(
            "The gears of contemplation grind slowly but surely.",
            "You lose yourself momentarily in the labyrinth of thought.",
            "Deep cogitation yields no immediate revelations."
        )
    }

    open func thinkAboutCharacter(_ character: String) -> String {
        output("You think about \(character).")
    }

    open func thinkAboutEnemy(_ enemy: String) -> String {
        output("You think about \(enemy) with some concern.")
    }

    open func thinkAboutItem(_ item: String) -> String {
        oneOf(
            "Your thoughts circle around \(item) like moths around flame.",
            "You lose yourself in contemplation of \(item) and its implications.",
            "\(item) occupies your mental landscape for a thoughtful moment."
        )
    }

    open func thinkAboutLocation(_ location: String) -> String {
        oneOf(
            "Your mind wanders through memories and impressions of \(location).",
            "\(location) fills your thoughts with its particular atmosphere.",
            "You reflect on the nature and significance of \(location)."
        )
    }

    open func thinkAboutSelf() -> String {
        oneOf(
            "You turn your thoughts inward, finding the usual mixture of hope and regret.",
            "A moment of introspection reveals nothing you didn't already suspect.",
            "You contemplate your place in the grand narrative."
        )
    }

    open func thinkAboutUniversal(_ universal: String) -> String {
        oneOf(
            "You ponder the deeper meaning of \(universal).",
            "Your thoughts spiral around the concept of \(universal).",
            "The nature of \(universal) occupies your philosophical attention."
        )
    }

    open func throwAtCharacter(
        _ command: Command,
        item: String,
        character: String
    ) -> String {
        output(
            """
            You \(command.verb) \(item) at \(character), who dodges aside
            with an indignant look. The \(item) clatters to the ground.
            """
        )
    }

    open func throwAtEnemy(
        _ command: Command,
        item: String,
        enemy: String
    ) -> String {
        output(
            """
            You \(command.verb) \(item) at \(enemy), but your aim falls short.
            The \(item) tumbles uselessly to the ground.
            """
        )
    }

    open func throwAtObject(
        _ command: Command,
        item: String,
        target: String
    ) -> String {
        output(
            """
            You \(command.verb) \(item) at \(target). It bounces off and falls to the ground
            with an unimpressive thud.
            """
        )
    }

    open func throwItem(
        _ command: Command,
        item: String
    ) -> String {
        output("You \(command.verb) \(item) in a lazy arc. It lands nearby with little fanfare.")
    }

    open func throwToCharacter(
        _ command: Command,
        item: String,
        character: String,
        value: Item.RoughValue
    ) -> String {
        switch value {
        case .worthless, .low:
            return output(
                """
                You \(command.verb) \(item) to \(character), who catches it with mild puzzlement
                before tucking it away.
                """
            )
        case .medium:
            return output(
                """
                You \(command.verb) \(item) to \(character), who catches it deftly and nods
                with appreciation before pocketing it.
                """
            )
        case .high, .priceless:
            return output(
                """
                You \(command.verb) \(item) to \(character), who snatches it from the air
                with obvious delight, examining the prize before securing it carefully.
                """
            )
        }
    }

    open func throwToEnemy(
        _ command: Command,
        item: String,
        enemy: String,
        value: Item.RoughValue
    ) -> String {
        switch value {
        case .worthless, .low:
            return output(
                """
                You \(command.verb) \(item) toward \(enemy), who catches it with mild confusion
                before shrugging and keeping it anyway.
                """
            )
        case .medium:
            return output(
                """
                You \(command.verb) \(item) toward \(enemy), who catches it with sudden interest.
                A calculating look crosses their features as they secure their new weapon.
                """
            )
        case .high, .priceless:
            return output(
                """
                You \(command.verb) \(item) toward \(enemy), who snatches it eagerly from the air.
                Armed with your gift, they regard you with savage anticipation.
                """
            )
        }
    }

    open func throwToObject(
        _ command: Command,
        item: String,
        target: String
    ) -> String {
        output(
            """
            You \(command.verb) \(item) toward \(target), but inanimate objects make poor catchers.
            The \(item) drops to the ground.
            """
        )
    }

    open func tieCharacter(_ command: Command, character: String) -> String {
        oneOf(
            "Binding \(character) would transform you from adventurer to kidnapper.",
            "\(character)'s freedom is not yours to restrict with rope.",
            "Your bondage aspirations regarding \(character) must remain unfulfilled."
        )
    }

    open func tieEnemy(_ command: Command, enemy: String) -> String {
        oneOf(
            "\(enemy) would resist binding with extreme prejudice.",
            "Your rope would need to overcome \(enemy)'s violent objections first.",
            "Attempting to tie \(enemy) would escalate this conflict dramatically."
        )
    }

    open func tieItem(_ command: Command, item: String) -> String {
        output("You can't tie \(item).")
    }

    open func tieItemTo(
        _ command: Command,
        item: String,
        to target: String
    ) -> String {
        output("You can't tie \(item) to \(target).")
    }

    open func tieItemToItself(_ command: Command, item: String) -> String {
        output("You can't tie \(item) to itself.")
    }

    open func tieItemWith(
        _ command: Command,
        item: String,
        with apparatus: String
    ) -> String {
        output("You can't tie \(item) with \(apparatus).")
    }

    open func tieItemWithItself(_ command: Command, item: String) -> String {
        output("You can't tie \(item) with itself.")
    }

    open func timePasses() -> String {
        oneOf(
            "Time flows onward, indifferent to your concerns.",
            "Moments slip away like sand through fingers.",
            "The universe's clock ticks inexorably forward."
        )
    }

    open func touchCharacter(_ verb: Verb, character: String) -> String {
        oneOf(
            "Your hands must respect \(character)'s personal boundaries.",
            "\(character) has not invited your touch.",
            "Physical contact with \(character) requires permission not yet granted."
        )
    }

    open func touchEnemy(_ verb: Verb, enemy: String) -> String {
        oneOf(
            "Reaching toward \(enemy) invites violent retaliation.",
            "Your fingers approaching \(enemy) would likely return fewer in number.",
            "Touch is not the sense to explore where \(enemy) is concerned."
        )
    }

    open func touchObject(_ verb: Verb, item: String) -> String {
        oneOf(
            "Your fingers explore \(item)'s surface, finding it satisfyingly tangible.",
            "\(item) feels exactly as it looks--solidly real and utterly ordinary.",
            "Your tactile investigation of \(item) yields no surprises."
        )
    }

    open func touchSelf(_ verb: Verb) -> String {
        oneOf(
            "You confirm your continued corporeal existence with a reassuring self-touch.",
            "Your hand meets your body. You remain stubbornly solid.",
            "A quick tactile self-check confirms you haven't become ethereal."
        )
    }

    open func transcriptAlreadyOn(_ path: String) -> String {
        output("Transcript recording is already active at '\(path)'.", capitalize: false)
    }

    open func transcriptEnded(_ path: String) -> String {
        output("Transcript recording ended at '\(path)'.", capitalize: false)
    }

    open func transcriptError(_ error: String) -> String {
        output("Unable to start transcript: \(error)", capitalize: false)
    }

    open func transcriptNotOn() -> String {
        output("Scripting is not currently on.")
    }

    open func transcriptStarted(_ path: String) -> String {
        output("Transcript recording started at '\(path)'.", capitalize: false)
    }

    open func turnCharacter(_ character: String) -> String {
        oneOf(
            "\(character) is not a crank to be turned at your whim.",
            "Rotating \(character) would serve no purpose and strain relations.",
            "\(character) maintains their chosen orientation without your assistance."
        )
    }

    open func turnFixedObject(_ item: String) -> String {
        oneOf(
            "\(item) remains fixed in its orientation, defying rotation.",
            "No amount of effort will turn \(item).",
            "\(item) stubbornly maintains its current facing."
        )
    }

    open func turnItem(_ item: String) -> String {
        oneOf(
            "You rotate \(item) experimentally. Nothing of consequence occurs.",
            "\(item) turns in your hands, revealing nothing new.",
            "You give \(item) a spin. The universe remains unimpressed."
        )
    }

    open func turnSelf() -> String {
        oneOf(
            "You execute a graceless pirouette.",
            "You spin about, achieving mild vertigo.",
            "You rotate in place, the world blurring momentarily."
        )
    }

    open func undescribedLocation() -> String {
        oneOf(
            "You've reached the fabled Lorem Ipsum, where descriptions await their author.",
            "This location is still under construction. The game developers apologize for any inconvenience.",
            "[INSERT ROOM DESCRIPTION HERE] You stand in a placeholder, wondering what might have been.",
            "Error 404: Room description not found. But you're definitely somewhere.",
            "You find yourself in a place so obscure even its creator forgot to describe it."
        )
    }

    open func unexpectedWordsAfterCommand(_ unexpectedWords: String) -> String {
        oneOf(
            "The phrase '\(unexpectedWords)' eludes my comprehension.",
            "I'm stumped by '\(unexpectedWords)' in this context.",
            "'\(unexpectedWords)' doesn't parse in any way I understand."
        )
    }

    open func unknownItem(_ item: ItemID) -> String {
        oneOf(
            "No such thing graces your field of vision.",
            "That particular item remains stubbornly absent from reality.",
            "You search in vain for any such object."
        )
    }

    open func unknownLocation(_ location: LocationID) -> String {
        oneOf(
            "That place exists only in imagination, not in your current geography.",
            "No such location presents itself to your searching gaze.",
            "That destination remains undiscovered in your current realm."
        )
    }

    open func verbDoesNotSupportMultipleIndirectObjects(_ verb: Verb) -> String {
        output("The verb '\(verb)' doesn't support multiple indirect objects.")
    }

    open func verbDoesNotSupportMultipleObjects(_ verb: Verb) -> String {
        output("The verb '\(verb)' doesn't support multiple objects.")
    }

    open func verbSyntaxRulesAllFailed(_ verb: String) -> String {
        output(
            """
            I understood '\(verb)' but couldn't parse the rest
            of the sentence with its known grammar rules.
            """
        )
    }

    open func verbUnderstoodButSyntaxFailed(_ verb: String) -> String {
        output("I understand the verb '\(verb)', but not the rest of that sentence.")
    }

    open func verbUnknown(_ verbPhrase: String) -> String {
        oneOf(
            "The art of \(verbPhrase)-ing remains a mystery to me.",
            "I lack the knowledge necessary to \(verbPhrase) anything.",
            "'\(verbPhrase)' doesn't appear in my extensive vocabulary of actions."
        )
    }

    open func wave() -> String {
        oneOf(
            "You wave your hands with theatrical flourish.",
            "Your arms describe meaningless patterns in the air.",
            "You gesticulate wildly at nothing in particular."
        )
    }

    open func waveAtCharacter(_ character: String) -> String {
        output("You wave at \(character).")
    }

    open func waveAtEnemy(_ enemy: String) -> String {
        output("You wave at \(enemy). They respond with violence.")
    }

    open func waveAtObject(_ item: String) -> String {
        oneOf(
            "\(item) remains unimpressed by your enthusiastic gesticulation.",
            "Your wave passes by \(item) without acknowledgment or effect.",
            "You wave at \(item), which maintains its steadfast inanimacy."
        )
    }

    open func waveObject(_ item: String) -> String {
        oneOf(
            "You brandish \(item) with theatrical enthusiasm.",
            "\(item) cuts through the air in your gesticulating grasp.",
            "You wave \(item) about like a conductor's baton."
        )
    }

    open func waveObjectAt(_ item: String, target: String) -> String {
        oneOf(
            "You flourish \(item) in the general direction of \(target).",
            "\(item) describes elaborate patterns as you wave it at \(target).",
            "You brandish \(item) at \(target) with meaningful emphasis."
        )
    }

    open func whichEntrance() -> String {
        oneOf(
            "Multiple entrances present themselves. Which calls to you?",
            "Several passages beckon. Which would you choose?",
            "The abundance of entrances requires clarification."
        )
    }

    open func wrongKey(_ key: String, lock: String) -> String {
        oneOf(
            "\(key) and \(lock) were never meant to be together.",
            "The teeth of \(key) find no purchase in \(lock)'s mechanism.",
            "\(key) refuses all attempts at intimacy with \(lock)."
        )
    }

    open func xyzzyResponse() -> String {
        oneOf(
            "A hollow voice says 'Fool.'",
            "The ancient magic fails to respond to your call.",
            "Nothing happens. Perhaps you're in the wrong cave.",
            "The universe briefly considers your request, then politely declines."
        )
    }

    open func yell() -> String {
        oneOf(
            "Your voice tears through the silence like a blade.",
            "You release a primal cry that would make your ancestors proud.",
            "Sound erupts from your throat with impressive volume."
        )
    }

    open func yellAtCharacter(_ character: String) -> String {
        oneOf(
            "Your sudden vocal eruption leaves \(character) momentarily stunned.",
            "\(character) recoils from the unexpected force of your voice.",
            "Your shout catches \(character) off-guard, leaving them visibly shaken."
        )
    }

    open func yellAtEnemy(_ enemy: String) -> String {
        oneOf(
            "\(enemy) meets your vocal fury with cold indifference.",
            "Your battle cry washes over \(enemy) like a gentle breeze.",
            "\(enemy) regards your shouting as merely another irritation to endure."
        )
    }

    open func yellAtObject(_ object: String) -> String {
        oneOf(
            "Your vocal assault on \(object) achieves nothing but mild hoarseness.",
            "\(object) weathers your shouting with inanimate patience.",
            "You unleash your fury upon \(object), which remains supremely unbothered."
        )
    }

    open func yesNoFumble() -> String {
        oneOf(
            "Your response defies binary interpretation. I'll take that as a 'no'.",
            "That's neither yes nor no, so I'll err on the side of caution.",
            "Ambiguity in the face of such questions defaults to negation."
        )
    }

    open func yesWhat() -> String {
        oneOf(
            "Your affirmation lacks context. Yes to what, exactly?",
            "Agreement requires a subject. What are you saying yes to?",
            "That 'yes' floats without anchor. Care to elaborate?"
        )
    }

    open func you() -> String {
        output("you", capitalize: false)
    }

    open func youAlreadyHaveThat() -> String {
        oneOf(
            "That already resides among your possessions.",
            "You need not acquire what you already possess.",
            "Check your inventory--you already have that."
        )
    }

    open func youAreCarrying() -> String {
        output("You are carrying:")
    }

    open func youAreEmptyHanded() -> String {
        oneOf(
            "Your hands are as empty as your pockets.",
            "You carry nothing but your own thoughts.",
            "You are unburdened by material possessions."
        )
    }

    open func youCannotAct() -> String {
        output("You are unable to act right now.")
    }

    open func youDo(_ command: Command, item: String) -> String {
        oneOf(
            "You \(command.verbPhrase) \(item).",
            "With practiced efficiency, you \(command.verbPhrase) \(item).",
            "You successfully \(command.verbPhrase) \(item)."
        )
    }

    open func youDoMultipleItems(_ command: Command, items: [ItemProxy]) async -> String {
        let itemList = await items.listWithDefiniteArticles() ?? ""
        return output(
            items.isEmpty
                ? "You have nothing to \(command.verbPhrase)."
                : "You \(command.verbPhrase) \(itemList)."
        )
    }

    open func youDontHave(_ item: String) -> String {
        oneOf(
            "\(item) is not among your current possessions.",
            "Your inventory lacks \(item).",
            "You search in vain for \(item) among your belongings."
        )
    }

    open func youHaveDied() -> String {
        oneOf(
            #"""
            \*\*\*\*  You have died  \*\*\*\*

            Your story ends here, but death is merely
            an intermission in the grand performance.

            """#,
            #"""
            \*\*\*\*  You have died  \*\*\*\*

            The curtain falls on this particular act
            of your existence. But all good stories
            deserve another telling...

            """#,
            #"""
            \*\*\*\*  You have died  \*\*\*\*

            Death, that most permanent of inconveniences,
            has claimed you. Yet in these tales, even
            death offers second chances.

            """#,
        )
    }

    open func youHaveIt() -> String {
        oneOf(
            "It rests securely in your possession.",
            "You have it already.",
            "That's yours, safe and sound."
        )
    }

    open func youHaveNothingToPutIn(_ container: String) -> String {
        oneOf(
            "Your possessions offer nothing suitable for placement in \(container).",
            "\(container) must remain empty, as you lack items to fill it.",
            "You search your inventory in vain for something to put in \(container)."
        )
    }

    open func youPutItemInContainer(_ item: String, container: String) -> String {
        oneOf(
            "You carefully place \(item) within \(container).",
            "\(item) finds a new home inside \(container).",
            "With practiced ease, you deposit \(item) in \(container)."
        )
    }

    open func youPutItemOnSurface(_ verb: Verb, item: String, surface: String) -> String {
        oneOf(
            "You \(verb) \(item) on \(surface) with careful precision.",
            "\(item) comes to rest upon \(surface).",
            "You successfully \(verb) \(item) on \(surface)."
        )
    }

    open func youPutOn(_ item: String) -> String {
        oneOf(
            "You don \(item) with practiced ease.",
            "\(item) settles into place upon your person.",
            "You wear \(item) now."
        )
    }

    open func youScored(final: Int, max: Int, moves: Int) -> String {
        output(
            """
            You scored \(final) out of a possible \(max) points,
            in \(moves) moves.

            """
        )
    }

    open func your(_ item: String) -> String {
        output("your \(item)", capitalize: false)
    }

    // MARK: - Helper functions

    /// Returns one of a collection of responses at random.
    ///
    /// For testing purposes, a deterministic random number generator can specified when
    /// initializing the StandardMessenger. By default the SystemRandomNumberGenerator is used.
    ///
    /// - Parameters:
    ///   - responses: A collection of responses.
    ///   - logLevel: The logging level for debug output (defaults to .debug).
    ///   - capitalize: Whether to capitalize the first letter of the response (defaults to true).
    ///   - function: The calling function name for debugging (defaults to #function).
    /// - Returns: A randomly selected response.
    open func oneOf(
        _ responses: String...,
        logLevel: Logger.Level = .debug,
        capitalize: Bool = true,
        function: String = #function
    ) -> String {
        oneOf(
            responses: responses,
            logLevel: logLevel,
            capitalize: capitalize,
            function: function
        )
    }

    open func oneOf(
        responses: [String],
        logLevel: Logger.Level = .debug,
        capitalize: Bool = true,
        function: String = #function
    ) -> String {
        let index = Int.random(
            in: 0..<responses.count,
            using: &randomNumberGenerator
        )
        return output(
            capitalize ? responses[index].capitalizedSentences : responses[index],
            logLevel,
            capitalize: capitalize,
            function: function
        )
    }

    open func output(
        _ gameOutput: @autoclosure () -> String,
        _ logLevel: Logger.Level = .debug,
        capitalize: Bool = true,
        function: String = #function
    ) -> String {
        let icon =
            switch logLevel {
            case .trace: "🔍"
            case .debug: "🐛"
            case .info: "🎯"
            case .notice: "📣"
            case .warning: "⚠️ "
            case .error: "🛑 "
            case .critical: "💀"
            }

        logger.log(
            level: logLevel,
            Logger.Message(stringLiteral: "\(icon) \(function)")
        )

        return capitalize ? gameOutput().capitalizedSentences : gameOutput()
    }
}

// swiftlint:enable file_length
