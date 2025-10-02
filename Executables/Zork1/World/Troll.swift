import GnustoEngine

enum Troll {
    static let troll = Item(.troll)
        .name("troll")
        .synonyms("troll")
        .adjectives("nasty", "pathetic")
        .characterSheet(
            CharacterSheet(
                strength: 12,
                dexterity: 8,
                constitution: 12,
                intelligence: 6,
                wisdom: 5,
                charisma: 1,
                bravery: 12,
                perception: 8,
                luck: 6,
                morale: 12,
                accuracy: 10,
                intimidation: 12,
                stealth: 4,
                level: 1,
                classification: .masculine,
                alignment: .neutralEvil,
                armorClass: 10
            )
        )
        .in(.trollRoom)
        .isOpen
        .requiresTryTake

    static let trollRoom = Location(.trollRoom)
        .name("Troll Room")
        .description(
            """
            This is a small room with passages to the east and south and a forbidding hole
            leading west. Bloodstains and deep scratches (perhaps made by an axe) mar the
            walls.
            """
        )
        .east(.eastWestPassage)
        .south(.cellar)
        .west(.maze1)

    // MARK: - Computers

    static let trollComputer = ItemComputer(for: .troll) {
        itemProperty(.description, .firstDescription) { context in
            let troll = context.item

            // Check if troll is unconscious
            return if await troll.isUnconscious {
                .string(
                    """
                    An unconscious troll is sprawled on the floor. All passages
                    out of the room are open.
                    """
                )
            }

            // Check if troll has the axe
            else if await troll.isHolding(.axe) {
                .string(
                    """
                    A nasty-looking troll, brandishing a bloody axe, blocks all
                    passages out of the room.
                    """
                )
            }

            // Disarmed troll
            else {
                .string("A pathetically babbling troll is here.")
            }
        }
    }

    // MARK: - Event Handlers

    static let trollHandler = ItemEventHandler(for: .troll) {
        before(.tell) { _, _ in
            ActionResult("The troll isn't much of a conversationalist.")
        }

        //        before(.examine) { context, command in
        //            let description = await context.item.description
        //            return ActionResult(description)
        //        }

        before(.attack) { context, _ in
            // Wake the troll first if unconscious
            await wakeTroll(engine: context.engine)
        }

        before(.give, .throw) { context, command in
            await handleTrollGiveOrThrow(
                engine: context.engine,
                command: command
            )
        }

        before(.take, .move) { context, _ in
            await ActionResult(
                """
                The troll spits in your face, grunting "Better luck next time"
                in a rather barbarous accent.
                """
            ).prepended(
                by: wakeTroll(engine: context.engine)
            )
        }

        before(.mung, .pull, .push) { context, command in
            // Non-attack mung verbs include `rip`, `break`, etc.
            if !command.hasIntent(.attack) {
                return await ActionResult(
                    "The troll laughs at your puny gesture.",
                ).prepended(
                    by: wakeTroll(engine: context.engine)
                )
            }
            return nil
        }

        before(.listen) { context, _ in
            if await context.item.isAwake {
                return ActionResult(
                    """
                    Every so often the troll says something, probably uncomplimentary, in
                    his guttural tongue.
                    """
                )
            }
            return nil
        }

        before(.ask, .tell) { context, _ in
            if await !context.item.isAwake {
                return ActionResult("Unfortunately, the troll can't hear you.")
            }
            return nil
        }
    }

    static let trollRoomHandler = LocationEventHandler(for: .trollRoom) {
        beforeTurn(.move) { context, command in
            let troll = await context.item(.troll)

            // Troll blocks the way if here in the room, alive, and conscious
            if await context.location.items.contains(troll),
               await troll.isAwake,
               let direction = command.direction,
               [.east, .west].contains(direction)
            {
                return ActionResult("The troll fends you off with a menacing gesture.")
            }
            return nil
        }
    }

    /// Handles the troll's periodic behavior (picking up axe, etc.)
    static let trollDaemon = Daemon(frequency: 2) { engine, _ in
        let troll = await engine.item(.troll)
        let axe = await engine.item(.axe)

        // Don't do anything if troll is dead
        guard await !troll.isDead else { return .yield }

        // Don't do anything if troll already has axe
        if await troll.isHolding(axe.id) { return .yield }

        // If troll is unconscious, don't pick up axe
        guard await !troll.isUnconscious else { return .yield }

        // Check if axe is in the troll room and troll should pick it up
        if case .location(let axeLocationProxy) = await axe.parent,
           axeLocationProxy.id == LocationID.trollRoom,
           case .location(let trollLocationProxy) = await troll.parent,
           trollLocationProxy.id == LocationID.trollRoom
        {
            // 75-90% chance (using 80% as middle ground)
            let shouldPickUp = await engine.randomPercentage(chance: 80)

            if shouldPickUp {
                return await ActionResult(
                    """
                    The troll, angered and humiliated, recovers his weapon. He appears to have
                    an axe to grind with you.
                    """,
                    axe.setFlag(.omitDescription),
                    axe.clearFlag(.isWeapon),
                    axe.move(to: .item(.troll))
                )
                .appending(
                    engine.enemyAttacks(enemy: troll)
                )
            }
        }

        return nil
    }
}

// MARK: - Troll State Management

extension Troll {
    /// If the troll is unconscious, wake up and
    private static func wakeTroll(engine: GameEngine) async -> ActionResult? {
        let troll = await engine.item(.troll)

        // Small chance to start fighting on first encounter
        if await !troll.isAwake {
            return await ActionResult(
                "The troll stirs, quickly resuming a fighting stance.",
                troll.setCharacterAttributes(isFighting: true),
            )
        }

        return nil
    }

    /// Handles troll death
    static func handleTrollDeath(engine: GameEngine) async -> ActionResult {
        let troll = await engine.item(.troll)
        let axe = await engine.item(.axe)

        // If troll had axe, drop it and restore weapon properties
        var changes: [StateChange?] = await [
            troll.setCharacterAttributes(
                consciousness: .dead,
                isFighting: false,
            ),
            troll.remove(),  // Remove from game
        ]

        if await troll.isHolding(axe.id) {
            await changes.append(contentsOf: [
                axe.move(to: .location(.trollRoom)),
                axe.clearFlag(.omitDescription),
                axe.setFlag(.isWeapon),
            ])
        }

        return ActionResult(
            message: """
                Almost as soon as the troll breathes his last breath, a cloud
                of sinister black fog envelops him, and when the fog lifts,
                the carcass has disappeared.
                """,
            changes: changes
        )
    }

    /// Handles troll becoming unconscious
    static func handleTrollUnconscious(engine: GameEngine) async -> ActionResult {
        let troll = await engine.item(.troll)
        let axe = await engine.item(.axe)

        var changes: [StateChange?] = await [
            troll.setCharacterAttributes(
                consciousness: .unconscious,
                isFighting: false
            ),
        ]

        // If troll had axe, drop it and restore weapon properties
        if case .item(let axeParent) = await axe.parent,
           axeParent.id == .troll
        {
            await changes.append(contentsOf: [
                axe.move(to: .location(.trollRoom)),
                axe.clearFlag(.omitDescription),
                axe.setFlag(.isWeapon),
            ])
        }

        return ActionResult(
            message: """
                The troll, disarmed, cowers in terror, pleading for his life in
                the guttural tongue of the trolls.
                """,
            changes: changes
        )
    }

    /// Handles troll waking up
    static func handleTrollConscious(engine: GameEngine) async -> ActionResult? {
        let troll = await engine.item(.troll)

        guard
            case .location(let trollLocationProxy) = await troll.parent,
            trollLocationProxy.id == LocationID.trollRoom
        else { return nil }

        let axe = await engine.item(.axe)
        var changes: [StateChange?] = await [
            troll.setCharacterAttributes(
                consciousness: .unconscious,
                isFighting: false
            ),
        ]

        // Check if axe is available to pick up
        if case .location(let axeLocationProxy) = await axe.parent,
           axeLocationProxy.id == LocationID.trollRoom
        {
            await changes.append(contentsOf: [
                axe.setFlag(.omitDescription),
                axe.clearFlag(.isWeapon),
                axe.move(to: .item(.troll)),
            ])
        }

        return ActionResult(
            message: "The troll stirs, quickly resuming a fighting stance.",
            changes: changes
        )
    }
}

// MARK: - Give/Throw Handling

extension Troll {
    private static func handleTrollGiveOrThrow(
        engine: GameEngine,
        command: Command
    ) async -> ActionResult? {
        guard case .item(let item) = command.directObject else { return nil }
        let axe = await engine.item(.axe)
        let theItem = await item.withDefiniteArticle
        let troll = await engine.item(.troll)
        let wakeChange = await wakeTroll(engine: engine)

        // Special case: giving/throwing the axe to the troll
        if item == axe {
            return if await engine.player.isHolding(axe.id) {
                ActionResult(
                    "The troll scratches his head in confusion, then takes \(theItem).",
                    axe.move(to: .item(.troll))
                )
                .prepended(by: wakeChange)
            } else {
                ActionResult(
                    "You would have to get \(theItem) first, and that seems unlikely."
                )
                .prepended(by: wakeChange)
            }
        }

        // Build base message
        let baseMessage =
        if command.hasIntent(.throw) {
            "The troll, who is remarkably coordinated, catches \(theItem)"
        } else {
            // otherwise intent was .give
            "The troll, who is not overly proud, graciously accepts the gift"
        }

        if await item.isWeapon {
            // 20% chance the troll eats the weapon and dies
            if await engine.randomPercentage(chance: 20) {
                return await ActionResult(
                    """
                    \(baseMessage) and eats it hungrily. Poor troll,
                    he dies from an internal hemorrhage and his carcass
                    disappears in a sinister black fog.
                    """,
                    troll.setCharacterAttributes(consciousness: .dead),
                    troll.remove(),
                    item.remove(),
                )
                .prepended(by: wakeChange)
            } else {
                // Troll throws it back and gets angry
                return ActionResult(
                    """
                    \(baseMessage) and, being for the moment sated, throws it back.
                    Fortunately, the troll has poor control, and \(theItem) falls
                    to the floor. He does not look pleased.
                    """,
                    item.move(to: .location(.trollRoom))
                )
                .prepended(by: wakeChange)
            }
        } else {
            // Non-weapon: troll eats it
            return ActionResult(
                """
                \(baseMessage) and not having the most discriminating
                tastes, gleefully eats it.
                """,
                item.remove()
            )
            .prepended(by: wakeChange)
        }
    }
}
