import GnustoEngine

enum Troll {
    static let troll = Item(
        id: .troll,
        .name("troll"),
        .synonyms("troll"),
        .adjectives("nasty"),
        .in(.location(.trollRoom)),
        .isCharacter,
        .isOpen,
        .requiresTryTake,
        .strength(2)
    )

    static let trollRoom = Location(
        id: .trollRoom,
        .name("Troll Room"),
        .description(
            """
            This is a small room with passages to the east and south and a forbidding hole
            leading west. Bloodstains and deep scratches (perhaps made by an axe) mar the
            walls.
            """),
        .exits([
            .east: .to(.eastWestPassage),
            .south: .to(.cellar),
            .west: .to(.maze1),
        ])
    )

    static let trollComputer = ItemComputer { attribute, state in
        switch attribute {
        case .description, .firstDescription:
            .string(
                """
                A nasty-looking troll, brandishing a bloody axe, blocks all
                passages out of the room.
                """)
        default:
            nil
        }
    }

    static let trollHandler = ItemEventHandler { engine, event -> ActionResult? in
        switch event {
        case .beforeTurn(let command):
            return try await handleTrollCommand(engine: engine, command: command)

        case .afterTurn:
            return nil


        }
    }
}

    static let trollRoomHandler = LocationEventHandler { engine, event -> ActionResult? in
        guard case .beforeTurn(let command) = event else { return nil }

        // Only block movement if the troll is alive (not removed)
        guard let troll = try? await engine.item(.troll),
            troll.parent == .location(.trollRoom)
        else {
            return nil  // Troll is dead/gone, allow movement
        }

        switch command.verb {
        case .go:
            // Block east and west movement when troll is alive
            if let direction = command.direction, [.east, .west].contains(direction) {
                return ActionResult("The troll fends you off with a menacing gesture.")
            }
            return nil  // Allow other directions (south to cellar)
        default:
            return nil
        }
    }
}

// MARK: - Troll Command Handling

private func handleTrollCommand(engine: GameEngine, command: Command) async throws -> ActionResult?
{
    switch command.verb {
    case .tell:
        return ActionResult("The troll isn't much of a conversationalist.")

    case .attack:
        // Handle attacking the troll - it dies (simplified version)
        return ActionResult(
            message: """
                The troll takes a fatal blow and slumps to the floor dead.

                Almost as soon as the troll breathes his last breath, a cloud
                of sinister black fog envelops him, and when the fog lifts,
                the carcass has disappeared.

                Your sword is no longer glowing.
                """,
            changes: [
                try await engine.remove(.troll),
            ].compactMap { $0 }
        )

    case .give, .drop:
        guard case .item(let object) = command.directObject else {
            return nil
        }
        let objectName = try await engine.item(object).name

        return try await handleTrollGiveOrDrop(
            engine: engine, object: object, objectName: objectName,
            isDropCommand: command.verb == .drop)

    case .take, .move:
        return ActionResult(
            """
            The troll spits in your face, grunting "Better luck next time"
            in a rather barbarous accent.
            """)

    case .push:
        return ActionResult("The troll laughs at your puny gesture.")

    case .listen:
        return ActionResult(
            """
            Every so often the troll says something, probably
            uncomplimentary, in his guttural tongue.
            """)

    case .thinkAbout:
        // Simplified - just return nil for now since trollFlag isn't auto-generated
        return nil

    default:
        return nil
    }
}

// MARK: - Fighting System Implementation (Simplified)

// This demonstrates the core troll behavior from ZIL without full character mode system

// MARK: - Give/Drop Handling

private func handleTrollGiveOrDrop(
    engine: GameEngine,
    object: ItemID,
    objectName: String,
    isDropCommand: Bool
) async throws -> ActionResult? {
    // Handle giving/throwing the axe to the troll
    let isPlayerHoldingAxe = await engine.playerIsHolding(.axe)

    if object == .axe && isPlayerHoldingAxe {
        return ActionResult(
            message: "The troll scratches his head in confusion, then takes the axe.",
            changes: [
                try await engine.setFlag(.isFighting, on: .troll),
                try await engine.move(.axe, to: .item(.troll)),
            ].compactMap { $0 }
        )
    }

    // Handle giving/throwing the troll or axe itself
    if object == .troll || object == .axe {
        return ActionResult(
            "You would have to get the \(objectName) first, and that seems unlikely."
        )
    }

    // Handle other objects
    let baseMessage =
        if isDropCommand {
            "The troll, who is remarkably coordinated, catches the \(objectName)"
        } else {
            "The troll, who is not overly proud, graciously accepts the gift"
        }

    // Handle weapons
    let weaponItems: [ItemID] = [.knife, .sword, .axe]
    if weaponItems.contains(object) {
        if await engine.randomPercentage() <= 20 {
            return ActionResult(
                message: """
                    \(baseMessage) and eats it hungrily. Poor troll,
                    he dies from an internal hemorrhage and his carcass
                    disappears in a sinister black fog.
                    """,
                changes: [
                    try await engine.remove(.troll),
                    try await engine.remove(object),
                ].compactMap { $0 }
            )
        } else {
            return ActionResult(
                message: """
                    \(baseMessage) and, being for the moment sated, throws it back.
                    Fortunately, the troll has poor control, and the \(objectName)
                    falls to the floor. He does not look pleased.
                    """,
                changes: [
                    try await engine.move(object, to: .location(.trollRoom)),
                    try await engine.setFlag(.isFighting, on: .troll),
                ].compactMap { $0 }
            )
        }
    } else {
        return ActionResult(
            """
            \(baseMessage) and not having the most discriminating
            tastes, gleefully eats it.
            """,
            try await engine.remove(object)
        )
    }
}
