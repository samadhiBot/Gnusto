import GnustoEngine

enum OperaHouse {
    // MARK: - Foyer of the Opera House

    static let foyer = Location(
        id: .foyer,
        .name("Foyer of the Opera House"),
        .description("""
                You are standing in a spacious hall, splendidly decorated in red
                and gold, with glittering chandeliers overhead. The entrance from
                the street is to the north, and there are doorways south and west.
                """),
        .exits([
            .south: .to(.bar),
            .west: .to(.cloakroom),
            .north: Exit(
                destination: .street,
                blockedMessage: """
                    You've only just arrived, and besides, the weather outside
                    seems to be getting worse.
                    """
            )
        ]),
        .inherentlyLit
    )

    static let street = Location(
        id: .street,
        .description("The street outside the Opera House (not accessible in this demo)")
    )

    // MARK: - Cloakroom

    static let cloakroom = Location(
        id: .cloakroom,
        .name("Cloakroom"),
        .description("""
            The walls of this small room were clearly once lined with hooks,
            though now only one remains. The exit is a door to the east.
            """),
        .exits([
            .east: .to(.foyer),
        ]),
        .inherentlyLit
    )

    static let hook = Item(
        id: .hook,
        .adjectives("small", "brass"),
        .in(.location(.cloakroom)),
        .isScenery,
        .isSurface,
        .name("small brass hook"),
        .synonyms("peg"),
    )

    // MARK: - Bar

    static let bar = Location(
        id: .bar,
        .name("Bar"),
        .description("""
            The bar, much rougher than you'd have guessed after the opulence
            of the foyer to the north, is completely empty. There seems to
            be some sort of message scrawled in the sawdust on the floor.
            """),
        .exits([
            .north: .to(.foyer),
        ])
    )

    static let message = Item(
        id: .message,
        .name("scrawled message"),
        .in(.location(.bar)),
        .synonyms("sawdust", "floor"),
        .isReadable,
    )

    // MARK: - Items

    static let cloak = Item(
        id: .cloak,
        .name("velvet cloak"),
        .description("""
            A handsome cloak, of velvet trimmed with satin, and slightly
            spattered with raindrops. Its blackness is so deep that it
            almost seems to suck light from the room.
            """),
        .adjectives("handsome", "dark", "black", "velvet", "satin"),
        .in(.player),
        .isTakable,
        .isWearable,
        .isWorn,
    )

    // MARK: - Location event handlers

    static let barHandler = LocationEventHandler { engine, event in
        guard
            case .beforeTurn(let command) = event,
            await engine.playerLocationIsLit() == false
        else {
            return nil
        }
        return switch command.verb {
        case .go:
            if command.direction == .north {
                nil
            } else {
                ActionResult(
                    message: "Blundering around in the dark isn't a good idea!",
                    stateChange: await engine.adjustGlobal(.barMessageDisturbances, by: 2)
                )
            }
        case .look, .inventory:
            nil
        default:
            ActionResult(
                message: "In the dark? You could easily disturb something!",
                stateChange: await engine.adjustGlobal(.barMessageDisturbances, by: 1)
            )
        }
    }

    // MARK: - Item event handlers

    static let cloakHandler = ItemEventHandler { engine, event in
        switch event {
        case .beforeTurn(let command):
            switch command.verb {
            case .drop, .putOn:
                guard await engine.playerLocationID == .cloakroom else {
                    throw ActionResponse.prerequisiteNotMet(
                        "This isn't the best place to leave a smart cloak lying around."
                    )
                }
            default:
                break
            }

        case .afterTurn(let command):
            guard await engine.playerLocationID == .cloakroom else {
                return nil
            }
            switch command.verb {
            case .drop, .putOn:
                var stateChanges = [StateChange]()
                if await engine.playerScore < 1 {
                    stateChanges.append(await engine.updatePlayerScore(by: 1))
                }
                if let lightenBar = try await engine.setFlag(.isLit, on: engine.location(.bar)) {
                    stateChanges.append(lightenBar)
                }
                return ActionResult(stateChanges: stateChanges)
            case .take:
                if let darkenBar = try await engine.clearFlag(.isLit, on: engine.location(.bar)) {
                    return ActionResult(stateChange: darkenBar)
                }
            default:
                break
            }
        }
        return nil
    }

    static let hookHandler = ItemEventHandler { engine, event in
        guard case .beforeTurn(let command) = event, command.verb == .examine else {
            return nil
        }
        let cloak = try await engine.item(.cloak)
        let hookDetail = if cloak.parent == .item(.hook) {
            "with a cloak hanging on it"
        } else {
            "screwed to the wall"
        }
        throw ActionResponse.custom("It's just a small brass hook, \(hookDetail).")
    }

    static let messageHandler = ItemEventHandler { engine, event in
        guard
            case .beforeTurn(let command) = event,
            [.examine, .read].contains(command.verb),
            await engine.playerLocationID == .bar
        else {
            return nil
        }
        // Fix: Check location exists before accessing properties
        let bar = try await engine.location(.bar)
        guard bar.hasFlag(.isLit) else {
            throw ActionResponse.prerequisiteNotMet("It's too dark to do that.")
        }

        let disturbedCount = await engine.global(.barMessageDisturbances) ?? 0
        await engine.requestQuit()
        if disturbedCount < 2 {
            return ActionResult(
                message: """
                    The message, neatly marked in the sawdust, reads...

                    "You win."
                    """,
                stateChanges: [await engine.updatePlayerScore(by: 1)]
            )

        } else {
            throw ActionResponse.custom("""
                The message has been carelessly trampled, making it
                difficult to read. You can just distinguish the words...

                "You lose."
                """)
        }
    }
}
