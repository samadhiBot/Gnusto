import GnustoEngine

/// The notorious thief of Zork 1, a sophisticated character with stealth, theft, and combat abilities.
///
/// Based on the original ZIL `ROBBER-FUNCTION`, this implementation captures the thief's complex behaviors:
/// - Movement throughout the dungeon via daemon
/// - Sophisticated theft mechanics for valuable items
/// - Combat abilities with his deadly stiletto
/// - Treasure interactions and enhanced AI
enum Thief {
    // MARK: - Core Items

    static let thief = Item(
        id: .thief,
        .name("suspicious-looking individual"),
        .synonyms("thief", "individual", "person", "man"),
        .adjectives("suspicious", "suspicious-looking", "sneaky"),
        .isCharacter,
        .strength(3), // Stronger than the troll
        .in(.location(.roundRoom))
    )

    static let stiletto = Item(
        id: .stiletto,
        .name("stiletto"),
        .synonyms("stiletto", "knife", "blade"),
        .adjectives("vicious", "deadly", "sharp"),
        .isWeapon,
        .requiresTryTake,
        .isTakable,
        .omitDescription,
        .size(10),
        .in(.item(.thief))
    )

    static let largeBag = Item(
        id: .largeBag,
        .name("thief's bag"),
        .synonyms("bag", "sack"),
        .adjectives("large", "thiefs", "thief's"),
        .requiresTryTake,
        .omitDescription,
        .isContainer,
        .capacity(1000), // Large capacity for stolen treasures
        .in(.item(.thief))
    )

    // MARK: - Movement Locations

    /// Movement locations the thief can travel to
    static let thiefMovementLocations: [LocationID] = [
        .roundRoom, .northSouthPassage, .deepCanyon, .reservoirSouth,
        .damRoom, .reservoir, .streamView, .mirrorRoomSouth, .windingPassage, .tinyCave,
        .egyptRoom, .maze1, .maze2, .maze3, .maze4, .maze5
    ]

    // MARK: - Event Handlers

    /// Main thief character handler with sophisticated AI behavior
    static let thiefHandler = ItemEventHandler { engine, event -> ActionResult? in
        switch event {
        case .beforeTurn(let command):
            return try await handleThiefCommand(engine: engine, command: command)

        case .afterTurn:
            // Check for post-turn behavior (theft attempts, state changes)
            return try await handleThiefAfterTurn(engine: engine)
        }
    }

    /// Stiletto weapon handler with thief protection
    static let stilettoHandler = ItemEventHandler { engine, event -> ActionResult? in
        switch event {
        case .beforeTurn(let command):
            switch command.verb {
            case .take:
                // Stiletto is protected while thief is alive and present
                if await engine.playerCanReach(.thief) {
                    return ActionResult(
                        """
                        The thief is armed and dangerous. You'd have to defeat him first
                        before attempting to take his stiletto.
                        """
                    )
                }
                return nil

            case .examine:
                return ActionResult(
                    """
                    It's a vicious-looking stiletto with a razor-sharp blade. The thief
                    grips it expertly, clearly experienced in its use.
                    """
                )

            default:
                return nil
            }

        case .afterTurn:
            return nil
        }
    }

    /// Large bag handler with treasure integration
    static let largeBagHandler = ItemEventHandler { engine, event -> ActionResult? in
        switch event {
        case .beforeTurn(let command):
            switch command.verb {
            case .take, .open:
                // Bag is protected while thief is alive and present
                if await engine.playerCanReach(.thief) {
                    return ActionResult(
                        """
                        The thief clutches his bag protectively. You'd need to defeat him
                        first before you could get at his stolen treasures.
                        """
                    )
                }
                return nil

            case .examine:
                if await engine.playerCanReach(.thief) {
                    return ActionResult(
                        """
                        The thief's large bag bulges with what are obviously stolen goods.
                        He watches you carefully, ready to defend his ill-gotten gains.
                        """
                    )
                } else {
                    // When thief is defeated, show bag contents
                    let bagContents = await engine.items(in: .item(.largeBag))
                    if bagContents.isEmpty {
                        return ActionResult("The thief's bag lies empty on the ground.")
                    } else {
                        let contentsList = bagContents.map(\.name).joined(separator: ", ")
                        return ActionResult(
                            """
                            The thief's bag lies open, spilling its stolen contents:
                            \(contentsList).
                            """
                        )
                    }
                }

            default:
                return nil
            }

        case .afterTurn:
            return nil
        }
    }

    // MARK: - Movement Daemon

    /// Advanced movement daemon that makes the thief wander throughout the dungeon
    static let thiefMovementDaemon = Daemon(frequency: 3) { engine in
        // Only move if thief is alive
        let thief = try await engine.item(.thief)
        guard case .location(let thiefLocation) = thief.parent else {
            return nil
        }

        // Choose a new location to move to
        let availableLocations = thiefMovementLocations.filter { $0 != thiefLocation }
        guard let newLocationID = availableLocations.randomElement() else {
            return nil
        }

        // Move thief to new location
        let moveResult = try await engine.move(.thief, to: .location(newLocationID))

        // Determine if player sees the movement
        let playerLocation = await engine.playerLocationID
        var message: String?

        if playerLocation == thiefLocation {
            // Player sees thief leaving
            message = "The thief, looking furtively about, slips away into the shadows."
        } else if playerLocation == newLocationID {
            // Player sees thief arriving
            message = "A suspicious-looking individual emerges from the shadows, eyeing you warily."
        }

        return ActionResult(
            message: message,
            changes: [moveResult]
        )
    }

    // MARK: - Theft Daemon

    /// Sophisticated theft daemon with treasure evaluation
    static let thiefTheftDaemon = Daemon(frequency: 1) { engine in
        // Only attempt theft if thief is in same location as player
        let thief = try await engine.item(.thief)
        let playerLocationID = await engine.playerLocationID
        guard
            case .location(let thiefLocationID) = thief.parent,
            thiefLocationID == playerLocationID
        else {
            return nil
        }
        return try await attemptSophisticatedTheft(engine: engine)
    }
}

// MARK: - Command Handling

private func handleThiefCommand(engine: GameEngine, command: Command) async throws -> ActionResult? {
    switch command.verb {
    case .tell:
        return ActionResult(
            """
            The thief ignores you completely, his attention focused on scanning
            the area for valuables and potential threats.
            """
        )

    case .attack:
        return try await handleAttackThief(engine: engine, command: command)

    case .give:
        return try await handleGiveToThief(engine: engine, command: command)

    case .examine:
        return try await examineThief(engine: engine)

    case .take:
        return ActionResult(
            """
            The thief is armed and quite dangerous. You'd be wise to keep your
            distance unless you're prepared for a fight.
            """
        )

    default:
        return nil
    }
}

private func handleThiefAfterTurn(engine: GameEngine) async throws -> ActionResult? {
    // Simple post-turn processing - could be expanded later
    return nil
}

// MARK: - Give/Drop Handling

private func handleGiveToThief(engine: GameEngine, command: Command) async throws -> ActionResult? {
    guard case .item(let itemID) = command.directObject else {
        return nil
    }

    let item = try await engine.item(itemID)

    // Enhanced treasure evaluation
    let treasureValue = evaluateTreasureValue(of: item)

    if treasureValue > 0 {
        return ActionResult(
            message: """
                The thief examines the \(item.name) with obvious delight and
                carefully places it in his bag, giving you a grudging nod of
                acknowledgment.
                """,
            changes: [
                try await engine.move(itemID, to: .item(.largeBag))
            ].compactMap { $0 }
        )
    } else {
        return ActionResult(
            """
            The thief examines the \(item.name) briefly, then shakes his head
            with obvious disdain. "I only deal in quality merchandise," he mutters.
            """
        )
    }
}

// MARK: - Combat System

private func handleAttackThief(engine: GameEngine, command: Command) async throws -> ActionResult? {
    let outcome = try await evaluateThiefCombat(engine: engine)
    return try await handleThiefCombatResponse(engine: engine, outcome: outcome)
}

private func examineThief(engine: GameEngine) async throws -> ActionResult {
    return ActionResult(
        """
        There is a suspicious-looking individual, holding a large bag, leaning
        against one wall. He is armed with a deadly stiletto. He eyes you warily
        and seems ready for trouble.
        """
    )
}

/// Enhanced combat evaluation considering thief's skill
private func evaluateThiefCombat(engine: GameEngine) async throws -> ThiefCombatOutcome {
    let baseOutcome = await engine.randomCombatOutcome()
    let playerWeapon = await getPlayerBestWeapon(engine: engine)

    // Adjust odds based on player's weapon
    let weaponModifier = if let weapon = playerWeapon {
        await getWeaponEffectiveness(engine: engine, weapon: weapon)
    } else {
        -15 // Unarmed penalty
    }

    let adjustedOutcome = baseOutcome + weaponModifier

    // Thief is more skilled than troll - player has worse base odds
    return switch adjustedOutcome {
    case 0...15:
        .victory("Your superior tactics overwhelm the thief!")
    case 16...35:
        .partialVictory("You wound the thief severely!")
    case 36...55:
        .draw("You and the thief circle each other, both seeking an opening.")
    case 56...80:
        .defeat("The thief's superior skill and agility overwhelm you!")
    default:
        .ineffective("The thief easily parries your clumsy attack.")
    }
}

/// Enhanced combat outcomes with more nuanced results for thief combat
enum ThiefCombatOutcome {
    case victory(String)
    case partialVictory(String)
    case draw(String)
    case defeat(String)
    case ineffective(String)
}

/// Handles the result of combat with the thief
private func handleThiefCombatResponse(engine: GameEngine, outcome: ThiefCombatOutcome) async throws -> ActionResult {
    switch outcome {
    case .victory(let message):
        return ActionResult(
            message: """
                \(message)

                Almost as soon as the thief breathes his last breath, a cloud
                of sinister black fog envelops him, and when the fog lifts,
                the carcass has disappeared.

                His possessions lie scattered on the ground.
                """,
            changes: [
                try await engine.remove(.thief),
                try await dropThiefPossessions(engine: engine),
                await updateTreasureScoring(engine: engine)
            ].compactMap { $0 }
        )

    case .partialVictory(let message):
        return ActionResult(
            message: """
                \(message)

                The thief staggers, blood flowing from his wounds, but he's
                far from finished. His grip on the stiletto remains firm.
                """,
            changes: [
                try await engine.setFlag(.isFighting, on: .thief)
            ].compactMap { $0 }
        )

    case .defeat(let message):
        return ActionResult(
            message: """
                \(message)

                The thief stands over your fallen form, breathing heavily.
                He quickly rifles through your belongings with professional efficiency.
                """,
            changes: [
                try await engine.setFlag(.isFighting, on: .thief),
                try await thiefStealsRandomItem(engine: engine)
            ].compactMap { $0 }
        )

    case .draw(let message):
        return ActionResult(
            message: message,
            changes: [
                try await engine.setFlag(.isFighting, on: .thief)
            ].compactMap { $0 }
        )

    case .ineffective(let message):
        return ActionResult(message)
    }
}

// MARK: - Advanced Theft Mechanics

/// Sophisticated theft system with treasure evaluation and targeting
private func attemptSophisticatedTheft(engine: GameEngine) async throws -> ActionResult? {
    let playerItems = await engine.items(in: .player)
    guard !playerItems.isEmpty else { return nil }

    // Enhanced theft targeting - prioritize most valuable items
    let targetableItems = playerItems.compactMap { item -> (ItemID, Int)? in
        let value = evaluateTreasureValue(of: item)
        return value > 0 ? (item.id, value) : nil
    }.sorted { $0.1 > $1.1 } // Sort by value, highest first

    guard !targetableItems.isEmpty else { return nil }

    // 25% base chance, increased if player has very valuable items
    let hasHighValueItems = targetableItems.contains { $0.1 >= 5 }
    let theftChance = hasHighValueItems ? 35 : 25

    let outcome = await engine.randomCombatOutcome()
    guard outcome <= theftChance else { return nil }

    // Target the most valuable item
    let (targetItemID, _) = targetableItems.first!
    let targetItem = try await engine.item(targetItemID)

    return ActionResult(
        message: """
            With lightning-quick reflexes, the thief snatches the \(targetItem.name)
            from your possession and stuffs it into his bag!

            "A fine addition to my collection," he says with a sly grin.
            """,
        changes: [
            try await engine.move(targetItemID, to: .item(.largeBag))
        ].compactMap { $0 }
    )
}

/// Steals a random item when thief defeats player in combat
private func thiefStealsRandomItem(engine: GameEngine) async throws -> StateChange? {
    let playerItems = await engine.items(in: .player)
    guard !playerItems.isEmpty else { return nil }

    // Prefer valuable items, but will take anything in combat
    let valuableItems = playerItems.filter { item in
        evaluateTreasureValue(of: item) > 0
    }

    let targetItems = valuableItems.isEmpty ? playerItems : valuableItems
    let randomItem = targetItems.randomElement()!

    return try await engine.move(randomItem.id, to: .item(.largeBag))
}

// MARK: - Treasure Scoring Integration

/// Evaluates the treasure value of an item for thief interest and scoring
private func evaluateTreasureValue(of item: Item) -> Int {
    // High-value treasures (worth 10+ points in trophy case)
    let highValueTreasures: [ItemID] = [
        .skull, .potOfGold, .diamond, .bracelet, .platinumBar
    ]

    // Medium-value treasures (worth 5-9 points in trophy case)
    let mediumValueTreasures: [ItemID] = [
        .sceptre, .torch, .painting, .chalice, .trident
    ]

    // Low-value treasures (worth 1-4 points in trophy case)
    let lowValueTreasures: [ItemID] = [
        .egg, .bagOfCoins, .jade, .bauble
    ]

    // Weapons are always interesting to thieves
    let valuableWeapons: [ItemID] = [
        .sword, .knife, .axe, .stiletto
    ]

    return switch true {
    case highValueTreasures.contains(item.id): 10
    case mediumValueTreasures.contains(item.id): 6
    case lowValueTreasures.contains(item.id): 3
    case valuableWeapons.contains(item.id): 4
    case item.hasFlag(.isWeapon): 2
    case item.name.lowercased().contains("treasure"): 5
    default: 0
    }
}

/// Updates treasure scoring when thief is defeated and treasures recovered
private func updateTreasureScoring(engine: GameEngine) async -> StateChange? {
    // When thief dies, player gets bonus points for recovered treasures
    let bagContents = await engine.items(in: .item(.largeBag))
    var totalValue = 0

    for item in bagContents {
        totalValue += evaluateTreasureValue(of: item)
    }

    if totalValue > 0 {
        return await engine.updatePlayerScore(by: totalValue)
    }

    return nil
}

/// Drops thief possessions when defeated
private func dropThiefPossessions(engine: GameEngine) async throws -> StateChange? {
    let currentLocation = await engine.playerLocationID

    // Move thief's possessions to current location
    return try await engine.move(.largeBag, to: .location(currentLocation))
}

// MARK: - Weapon Evaluation

/// Finds the player's best weapon for combat calculations
private func getPlayerBestWeapon(engine: GameEngine) async -> ItemID? {
    let playerItems = await engine.items(in: .player)
    let weapons = playerItems.filter { $0.hasFlag(.isWeapon) }

    // Prioritize specific weapons by effectiveness
    let weaponPriority: [ItemID] = [.sword, .knife, .axe, .stiletto]

    for weaponID in weaponPriority {
        if weapons.contains(where: { $0.id == weaponID }) {
            return weaponID
        }
    }

    return weapons.first?.id
}

/// Gets weapon effectiveness modifier for combat
private func getWeaponEffectiveness(engine: GameEngine, weapon: ItemID) async -> Int {
    return switch weapon {
    case .sword: 15      // Best weapon against thief
    case .knife: 10      // Good for close combat
    case .axe: 5         // Heavy but slow
    case .stiletto: 12   // Similar weapon to thief's
    default: 0
    }
}
