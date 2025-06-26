import Foundation

/// Demo showing the new Intent-based event handling system
/// This file demonstrates how event handlers can now check for conceptual
/// intents rather than specific verbs, making them more flexible and maintainable.

// MARK: - Example Item Event Handlers

/// OLD APPROACH: Had to check for each specific verb
let oldRopeHandler = ItemEventHandler { engine, event in
    // Had to enumerate every possible cutting verb
    switch event {
    case .beforeTurn(let command):
        switch command.verb.rawValue {
        case "cut", "chop", "slice", "snip", "sever":
            return ActionResult("The rope is cut in half!")
        default:
            return nil
        }
    default:
        return nil
    }
}

/// NEW APPROACH: Check for conceptual intent
let newRopeHandler = ItemEventHandler { engine, event in
    // Much simpler - catches ANY verb with cutting intent
    return event.whenBeforeTurn(intent: .cut) {
        ActionResult("The rope is cut in half!")
    }
}

/// ADVANCED: Handle multiple intents
let advancedRopeHandler = ItemEventHandler { engine, event in
    // Handle both cutting and burning (rope can be cut OR burned)
    return event.whenBeforeTurn(intents: [.cut, .burn]) {
        switch event {
        case .beforeTurn(let command):
            if command.verb.intents.contains(.cut) {
                return ActionResult("The rope is cut in half!")
            } else if command.verb.intents.contains(.burn) {
                return ActionResult("The rope burns away!")
            }
        default:
            break
        }
        return nil
    }
}

// MARK: - Example Location Event Handlers

/// Location that responds to any vocal expression
let echoingChamberHandler = LocationEventHandler { engine, event in
    return event.whenBeforeTurn(intent: .tell) {
        ActionResult("Your voice echoes through the chamber.")
    }
}

/// Location that responds to multiple movement-related intents
let unstableFloorHandler = LocationEventHandler { engine, event in
    return event.whenBeforeTurn(intents: [.move, .jump, .climb]) {
        ActionResult("The floor creaks ominously under your movement!")
    }
}

// MARK: - Usage Examples

/// Example showing how verbs with intents work
func demonstrateIntentSystem() {
    // These verbs all have the .cut intent:
    let cutVerb = Verb.cut  // intents: [.cut]
    let chopVerb = Verb.chop  // intents: [.cut, .attack]
    let sliceVerb = Verb.slice  // intents: [.cut, .attack]

    // A rope handler checking for .cut intent will trigger for:
    // - "cut rope" (cut verb)
    // - "chop rope" (chop verb)
    // - "slice rope" (slice verb)
    // - "snip rope" (snip verb, if it has .cut intent)

    // But a creature handler checking for .attack intent will trigger for:
    // - "attack troll" (attack verb)
    // - "chop troll" (chop verb)
    // - "slice troll" (slice verb)
    // - "hit troll" (hit verb, if it has .attack intent)

    print("Intent-based system allows flexible, context-aware event handling!")
}

// MARK: - Migration Benefits

/// Benefits of the new Intent system:
///
/// 1. **Flexibility**: Add new cutting verbs (like "snip", "sever") and existing
///    rope handlers automatically work without modification
///
/// 2. **Maintainability**: No need to update every event handler when adding
///    new verb synonyms
///
/// 3. **Context Awareness**: Same verb can have different intents in different
///    contexts (e.g., "slice rope" vs "slice troll")
///
/// 4. **Declarative**: Intent definitions are centralized in Verb definitions
///    rather than scattered across event handlers
///
/// 5. **Backward Compatible**: Old verb-based checking still works alongside
///    new intent-based checking

// MARK: - Example Game Integration

struct ExampleGame {
    static func createRope() -> Item {
        return Item(
            id: "rope",
            .name("coiled rope"),
            .description("A strong hemp rope."),
            .isTakable,
            .in(.location("startingRoom")),
            // Event handler using new intent system
            .eventHandler(newRopeHandler)
        )
    }

    static func createEchoingChamber() -> Location {
        return Location(
            id: "echoingChamber",
            .name("Echoing Chamber"),
            .description("A vast chamber where sounds reverberate endlessly."),
            .inherentlyLit,
            // Event handler using new intent system
            .eventHandler(echoingChamberHandler)
        )
    }
}
