import GnustoEngine

@GameArea
enum OperaHouse {
    
    // MARK: - Locations
    
    enum Locations {
        static let foyer = Location(
            id: OperaHouse.foyer,
            .name("Foyer of the Opera House"),
            .description("""
                    You are standing in a spacious hall, splendidly decorated in red
                    and gold, with glittering chandeliers overhead. The entrance from
                    the street is to the north, and there are doorways south and west.
                    """),
            .exits([
                .south: .to(OperaHouse.bar),
                .west: .to(OperaHouse.cloakroom),
                .north: Exit(
                    destination: OperaHouse.street,
                    blockedMessage: """
                        You've only just arrived, and besides, the weather outside
                        seems to be getting worse.
                        """
                )
            ]),
            .inherentlyLit
        )

        static let cloakroom = Location(
            id: OperaHouse.cloakroom,
            .name("Cloakroom"),
            .description("""
                The walls of this small room were clearly once lined with hooks,
                though now only one remains. The exit is a door to the east.
                """),
            .exits([
                .east: .to(OperaHouse.foyer),
            ]),
            .inherentlyLit
        )

        static let bar = Location(
            id: OperaHouse.bar,
            .name("Bar"),
            .description("""
                The bar, much rougher than you'd have guessed after the opulence
                of the foyer to the north, is completely empty. There seems to
                be some sort of message scrawled in the sawdust on the floor.
                """),
            .exits([
                .north: .to(OperaHouse.foyer),
            ])
        )

        static let street = Location(
            id: OperaHouse.street,
            .name("Street"),
            .description("Rain-soaked November street."),
            .exits([
                .south: .to(OperaHouse.foyer),
            ]),
            .inherentlyLit
        )
    }
    
    // MARK: - Items

    enum Items {
        static let hook = Item(
            id: OperaHouse.hook,
            .adjectives("small", "brass"),
            .in(.location(OperaHouse.cloakroom)),
            .isScenery,
            .isSurface,
            .name("small brass hook"),
            .synonyms("peg"),
        )

        static let message = Item(
            id: OperaHouse.message,
            .name("scrawled message"),
            .in(.location(OperaHouse.bar)),
            .synonyms("sawdust", "floor"),
            .isReadable,
        )

        static let cloak = Item(
            id: OperaHouse.cloak,
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
    }

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
                await ActionResult(
                    message: "Blundering around in the dark isn't a good idea!",
                    stateChange: engine.adjustGlobal(.barMessageDisturbances, by: 2)
                )
            }
        case .look, .inventory:
            nil
        default:
            await ActionResult(
                message: "In the dark? You could easily disturb something!",
                stateChange: engine.adjustGlobal(.barMessageDisturbances, by: 1)
            )
        }
    }

    // MARK: - Item event handlers

    static let cloakHandler = ItemEventHandler { engine, event in
        switch event {
        case .beforeTurn(let command):
            switch command.verb {
            case .drop, .putOn:
                guard await engine.playerLocationID == OperaHouse.cloakroom else {
                    throw ActionResponse.prerequisiteNotMet(
                        "This isn't the best place to leave a smart cloak lying around."
                    )
                }
            default:
                break
            }

        case .afterTurn(let command):
            guard await engine.playerLocationID == OperaHouse.cloakroom else {
                return nil
            }
            switch command.verb {
            case .drop, .putOn:
                var stateChanges = [StateChange]()
                if await engine.playerScore < 1 {
                    stateChanges.append(await engine.updatePlayerScore(by: 1))
                }
                if let lightenBar = try await engine.setFlag(.isLit, on: engine.location(OperaHouse.bar)) {
                    stateChanges.append(lightenBar)
                }
                return ActionResult(stateChanges: stateChanges)
            case .take:
                if let darkenBar = try await engine.clearFlag(.isLit, on: engine.location(OperaHouse.bar)) {
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
        let cloak = try await engine.item(OperaHouse.cloak)
        let hookDetail = if cloak.parent == .item(OperaHouse.hook) {
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
            await engine.playerLocationID == OperaHouse.bar
        else {
            return nil
        }
        // Fix: Check location exists before accessing properties
        let bar = try await engine.location(OperaHouse.bar)
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
            return ActionResult(
                message: """
                    The message has been carelessly trampled, making it difficult to read.
                    You can just distinguish the words...

                    "You lose."
                    """,
                stateChanges: []
            )
        }
    }
}
