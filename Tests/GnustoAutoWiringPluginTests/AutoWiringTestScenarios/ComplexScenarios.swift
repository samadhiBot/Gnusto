import GnustoEngine

/// Complex test scenarios for comprehensive auto-wiring plugin testing.
/// This file contains patterns that test edge cases and advanced functionality.

// MARK: - Event Handler Test Area

enum EventTestArea {
    static let doorHandler = ItemEventHandler { engine, event in
        switch event {
        case .afterTurn(let command):
            ActionResult("You pick up the mysterious door.")
        default:
            nil
        }
    }

    static let mysticalRoomHandler = LocationEventHandler { engine, event in
        switch event {
        case .beforeTurn(let command):
            ActionResult("The room shimmers with magical energy.")
        default:
            nil
        }
    }

    static let door = Item(
        id: .mysticalDoor,
        .name("mystical door"),
        .description("A door that defies explanation."),
        .in(.location(.mysticalRoom)),
        .isTakable
    )

    static let mysticalRoom = Location(
        id: .mysticalRoom,
        .name("Mystical Room"),
        .description("A room filled with mystical energy."),
        .exits([.outside: .to(.normalRoom)]),
        .inherentlyLit
    )

    static let normalRoom = Location(
        id: .normalRoom,
        .name("Normal Room"),
        .description("A perfectly ordinary room."),
        .exits([.inside: .to(.mysticalRoom)]),
        .inherentlyLit
    )
}

// MARK: - Timer Test Area (Fuses and Daemons)

enum TimerTestArea {
    // Fuse definitions for testing - now return ActionResult?
    static let explosiveDevice = FuseDefinition(
        id: FuseID("bombFuse"),
        initialTurns: 5
    ) { engine in
        // Handle explosion logic and return ActionResult
        return ActionResult("BOOM! The explosive device detonates!")
    }

    static let timedPuzzle = FuseDefinition(
        id: FuseID("puzzleTimer"),
        initialTurns: 10
    ) { engine in
        // Reset puzzle state and return ActionResult
        return ActionResult("Time's up! The puzzle resets itself.")
    }

    // Daemon definitions for testing - now return ActionResult?
    static let randomEvents = DaemonDefinition(
        id: DaemonID("randomEventDaemon"),
        frequency: 15
    ) { engine in
        let events = [
            "You hear a distant sound.",
            "A cool breeze passes by.",
            "Something rustles in the shadows."
        ]
        return ActionResult(events.randomElement()!)
    }

    static let atmosphericEffects = DaemonDefinition(
        id: DaemonID("atmosphereDaemon"),
        frequency: 8
    ) { engine in
        return ActionResult("The atmosphere grows more tense.")
    }

    // Items related to timing
    static let bomb = Item(
        id: .timeBomb,
        .name("time bomb"),
        .description("A ticking device. Handle with care!"),
        .in(.location(.dangerRoom)),
        .isTakable
    )

    static let dangerRoom = Location(
        id: .dangerRoom,
        .name("Danger Room"),
        .description("This room feels dangerous."),
        .inherentlyLit
    )
}

// MARK: - Global State Test Area

enum GlobalTestArea {
    // Test various global state patterns
    static let scoreKeeper = Item(
        id: .scoreBoard,
        .name("score board"),
        .description("Shows your current score."),
        .in(.location(.scoreRoom)),
        .isReadable
    )

    static let scoreRoom = Location(
        id: .scoreRoom,
        .name("Score Room"),
        .description("A room for tracking progress."),
        .inherentlyLit
    )

    // These would typically be used in game logic with patterns like:
    // - GlobalID("playerScore")
    // - GlobalID("levelComplete")
    // - setFlag(.hasVisitedScoreRoom)
    // - adjustGlobal(.playerScore, by: 10)
}

// MARK: - Custom Action Handler Test Area

enum CustomActionTestArea {
    static let danceFloor = Location(
        id: .danceFloor,
        .name("Dance Floor"),
        .description("A shiny dance floor perfect for dancing."),
        .inherentlyLit
    )

    static let musicBox = Item(
        id: .musicBox,
        .name("music box"),
        .description("A beautiful music box."),
        .in(.location(.danceFloor)),
        .isTakable
    )

    // Custom action handlers would be defined in the game blueprint with patterns like:
    // - VerbID("dance")
    // - VerbID("sing")
    // - customActionHandlers: [.dance: danceHandler, .sing: singHandler]
}

// MARK: - Mixed Static/Instance Test Area (for comparison)

struct InstanceTestArea {
    let dynamicRoom = Location(
        id: .dynamicRoom,
        .name("Dynamic Room"),
        .description("A room created at runtime."),
        .inherentlyLit
    )

    let dynamicItem = Item(
        id: .dynamicItem,
        .name("dynamic item"),
        .description("An item that changes."),
        .in(.location(.dynamicRoom)),
        .isTakable
    )

    // Instance-based event handler
    let dynamicHandler = ItemEventHandler { engine, event in
        switch event {
        case .afterTurn:
            return ActionResult("The dynamic item responds to your touch.")
        default:
            return nil
        }
    }
}

// MARK: - Complex Nested Patterns Test Area

enum NestedTestArea {
    static let complexLocation: Location = Location(
        id: .complexLocation,
        .name("Complex Location"),
        .description("""
            A location with many interconnected elements and complex relationships.
            """),
        .exits([
            .north: .to(.northWing),
            .south: .to(.southWing),
            .east: .to(.eastWing),
            .west: .to(.westWing),
            .up: .to(.upperLevel),
            .down: .to(.lowerLevel)
        ]),
        .localGlobals(.compartmentKey, .hiddenDocument),
        .inherentlyLit
    )

    static let containerItem: Item = Item(
        id: .complexContainer,
        .name("complex container"),
        .description("A container with multiple compartments."),
        .in(.location(.complexLocation)),
        .isContainer,
        .isTakable
    )

    // Child items that would be contained in the container
    static let compartmentKey: Item = Item(
        id: .compartmentKey,
        .name("compartment key"),
        .in(.item(.complexContainer))
    )

    static let hiddenDocument: Item = Item(
        id: .hiddenDocument,
        .name("hidden document"),
        .in(.item(.complexContainer))
    )

    static let mysteriousOrb: Item = Item(
        id: .mysteriousOrb,
        .name("mysterious orb"),
        .in(.item(.complexContainer))
    )

    // These IDs would be discovered through cross-references
    static let northWing: Location = Location(id: .northWing, .name("North Wing"))
    static let southWing: Location = Location(id: .southWing, .name("South Wing"))
    static let eastWing: Location = Location(id: .eastWing, .name("East Wing"))
    static let westWing: Location = Location(id: .westWing, .name("West Wing"))
    static let upperLevel: Location = Location(id: .upperLevel, .name("Upper Level"))
    static let lowerLevel: Location = Location(id: .lowerLevel, .name("Lower Level"))
}
