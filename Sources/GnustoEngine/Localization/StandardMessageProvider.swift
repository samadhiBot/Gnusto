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
        }
    }
}
