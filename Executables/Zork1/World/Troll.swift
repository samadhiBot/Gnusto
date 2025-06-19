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
        .description("""
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
            .string("""
                A nasty-looking troll, brandishing a bloody axe, blocks all
                passages out of the room.
                """)
        default:
            nil
        }
    }

    static let trollHandler = ItemEventHandler { engine, event -> ActionResult? in
        guard case .beforeTurn(let command) = event else { return nil }
        
        switch command.verb {
        case .tell:
            return ActionResult("The troll isn't much of a conversationalist.")
            
        case .attack:
            guard let outcome = try await evaluateWeaponAttack(
                engine: engine,
                command: command
            ) else { return nil }

            return try await handleTrollCombatResponse(
                engine: engine,
                outcome: outcome
            )

        case .give, .drop:
            return try await handleTrollGiveOrDrop(
                engine: engine,
                command: command
            )
            
        case .take, .move:
            return ActionResult("""
                The troll spits in your face, grunting "Better luck next time"
                in a rather barbarous accent.
                """)

        case .push:
            return ActionResult("The troll laughs at your puny gesture.")

        case .listen:
            return ActionResult("""
                Every so often the troll says something, probably
                uncomplimentary, in his guttural tongue.
                """)

        default:
            return nil
        }
    }

    static let trollRoomHandler = LocationEventHandler { engine, event -> ActionResult? in
        let troll = try await engine.item(.troll)
        guard
            case .beforeTurn(let command) = event,
            troll.parent == .location(.trollRoom),
            command.verb == .go,
            let direction = command.direction,
            [.east, .west].contains(direction)
        else { return nil }

        // Block east and west movement when troll is alive; Allow other directions (south to cellar)
        return ActionResult("The troll fends you off with a menacing gesture.")
    }
}

// MARK: - Give/Drop Handling

extension Troll {
    private static func handleTrollGiveOrDrop(
        engine: GameEngine,
        command: Command
    ) async throws -> ActionResult? {
        guard case .item(let itemID) = command.directObject else {
            return nil
        }
        let item = try await engine.item(itemID)

        // Handle giving/throwing the axe to the troll
        let isPlayerHoldingAxe = await engine.playerIsHolding(.axe)

        if itemID == .axe && isPlayerHoldingAxe {
            return ActionResult(
                "The troll scratches his head in confusion, then takes the axe.",
                try await engine.setFlag(.isFighting, on: .troll),
                try await engine.move(.axe, to: .item(.troll)),
            )
        }

        // Handle giving/throwing the troll or axe itself
        if itemID == .troll || itemID == .axe {
            return ActionResult(
                "You would have to get the \(item.name) first, and that seems unlikely."
            )
        }

        // Handle other objects
        let baseMessage = if command.verb == .drop {
            "The troll, who is remarkably coordinated, catches the \(item.name)"
        } else {
            "The troll, who is not overly proud, graciously accepts the gift"
        }

        // Handle weapons using engine helper
        if await engine.isEffectiveWeapon(item) {
            let outcome = await engine.randomPercentage()
            return if outcome <= 20 {
                ActionResult(
                    """
                    \(baseMessage) and eats it hungrily. Poor troll,
                    he dies from an internal hemorrhage and his carcass
                    disappears in a sinister black fog.
                    """,
                    try await engine.remove(.troll),
                    try await engine.remove(itemID),
                )
            } else {
                ActionResult(
                    """
                    \(baseMessage) and, being for the moment sated, throws it back.
                    Fortunately, the troll has poor control, and the \(item.name)
                    falls to the floor. He does not look pleased.
                    """,
                    try await engine.move(itemID, to: .location(.trollRoom)),
                    try await engine.setFlag(.isFighting, on: .troll),
                )
            }
        } else {
            return ActionResult(
                """
                \(baseMessage) and not having the most discriminating
                tastes, gleefully eats it.
                """,
                try await engine.remove(itemID)
            )
        }
    }
}

// MARK: - Enhanced Combat Mechanics

/// Enhanced troll combat system with more sophisticated mechanics
extension Troll {
    /// Determines the outcome of a weapon attack on the troll
    static func evaluateWeaponAttack(
        engine: GameEngine,
        command: Command
    ) async throws -> CombatOutcome? {
        guard let weapon = try await engine.indirectObject(in: command) else {
            return nil
        }
        let isEffectiveWeapon = await engine.isEffectiveWeapon(weapon)
        let outcome = await engine.randomPercentage()
        return switch (isEffectiveWeapon, outcome) {
        case (true, 0...30):
            .victory("The troll succumbs to your superior weaponry!")
        case (true, 31...60):
            .draw("The troll blocks your attack with his axe!")
        case (true, _):
            .defeat("The troll's axe finds its mark. You are defeated!")
        case (false, _):
            .ineffective("Your \(weapon.name) proves ineffective against the troll.")
        }
    }

    /// Handles troll reaction to being attacked
    static func handleTrollCombatResponse(
        engine: GameEngine,
        outcome: CombatOutcome
    ) async throws -> ActionResult {
        switch outcome {
        case .victory(let message):
            ActionResult(
                """
                \(message)
                
                Almost as soon as the troll breathes his last breath, a cloud
                of sinister black fog envelops him, and when the fog lifts,
                the carcass has disappeared.
                """,
                try await engine.remove(.troll),
                // Clear fighting state from any weapons
                try await engine.clearFlag(.isFighting, on: .sword),
            )

        case .defeat(let message):
            ActionResult(
                """
                \(message)
                
                The troll stands over your fallen form, grunting what might
                be satisfaction in his guttural tongue.
                """,
                try await engine.setFlag(.isFighting, on: .troll),
                // Set player to wounded state (game-specific mechanic)
            )

        case .draw(let message):
            ActionResult(
                """
                \(message)
                
                You both circle each other warily, weapons at the ready.
                """,
                try await engine.setFlag(.isFighting, on: .troll),
            )

        case .ineffective(let message):
            ActionResult(message)
        }
    }
}

/// Combat outcome types for the enhanced fighting system
enum CombatOutcome {
    case victory(String)
    case defeat(String)
    case draw(String)
    case ineffective(String)
}
