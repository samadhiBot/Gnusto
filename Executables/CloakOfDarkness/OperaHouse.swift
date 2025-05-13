import GnustoEngine

struct OperaHouse: AreaContents {
    // MARK: - Foyer of the Opera House

    let foyer = Location(
        id: .foyer,
        .name("Foyer of the Opera House"),
        .description("""
                You are standing in a spacious hall, splendidly decorated in red
                and gold, with glittering chandeliers overhead. The entrance from
                the street is to the north, and there are doorways south and west.
                """),
        .exits([
            .south: Exit(destination: "bar"),
            .west: Exit(destination: "cloakroom"),
            .north: Exit(
                destination: "street",
                blockedMessage: """
                    You've only just arrived, and besides, the weather outside
                    seems to be getting worse.
                    """
            )
        ]),
        .inherentlyLit
    )

    // MARK: - Cloakroom

    let cloakroom = Location(
        id: .cloakroom,
        .name("Cloakroom"),
        .description("""
            The walls of this small room were clearly once lined with hooks,
            though now only one remains. The exit is a door to the east.
            """),
        .exits([
            .east: Exit(destination: "foyer"),
        ]),
        .inherentlyLit
    )

    let hook = Item(
        id: .hook,
        .adjectives("small", "brass"),
        .in(.location("cloakroom")),
        .isScenery,
        .isSurface,
        .name("small brass hook"),
        .synonyms("peg"),
    )

    // MARK: - Bar

    let bar = Location(
        id: .bar,
        .name("Bar"),
        .description("""
            The bar, much rougher than you'd have guessed after the opulence
            of the foyer to the north, is completely empty. There seems to
            be some sort of message scrawled in the sawdust on the floor.
            """),
        .exits([
            .north: Exit(destination: "foyer"),
        ])
        // Note: Bar lighting is handled dynamically by hooks
    )

    let message = Item(
        id: .message,
        .name("crumpled message"),
        .in(.location("bar")),
        .isReadable,
    )

    // MARK: - Items

    let cloak = Item(
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
}

// MARK: - Location action handlers

extension OperaHouse {
    static func barHandler(
        _ engine: GameEngine,
        _ action: LocationEvent
    ) async throws -> ActionResult? {
        guard
            case .beforeTurn(let command) = action,
            await engine.isPlayerLocationLit() == false
        else {
            return nil
        }
        let disturbances = await engine.gameState.globalState[.barMessageDisturbances]?.toInt ?? 0

        return switch command.verbID {
        case .go:
            if command.direction == .north {
                nil
            } else {
                ActionResult(
                    message: "Blundering around in the dark isn't a good idea!",
                    stateChanges: [
                        StateChange(
                            entityID: .global,
                            attributeKey: .globalState(key: .barMessageDisturbances),
                            oldValue: .int(disturbances),
                            newValue: .int(disturbances + 2)
                        ),
                    ]
                )
            }
        case .look, .inventory:
            nil
        default:
            ActionResult(
                message: "In the dark? You could easily disturb something!",
                stateChanges: [
                    StateChange(
                        entityID: .global,
                        attributeKey: .globalState(key: .barMessageDisturbances),
                        oldValue: .int(disturbances),
                        newValue: .int(disturbances + 1)
                    ),
                ]
            )
        }
    }
}

// MARK: - Object action handlers

extension OperaHouse {
    static func cloakHandler(_ engine: GameEngine, _ event: ItemEvent) async throws -> ActionResult? {
        switch event {
        case .beforeTurn(let command):
            switch command.verbID {
            case .drop:
                if await engine.playerLocationID == "cloakroom", await engine.playerScore < 1 {
                    return ActionResult(
                        stateChanges: [
                            await engine.scoreChange(by: 1),
                        ]
                    )
                } else {
                    throw ActionResponse.prerequisiteNotMet(
                        "This isn't the best place to leave a smart cloak lying around."
                    )
                }
            case .putOn:
                let score = await engine.playerScore
                guard
                    score < 2,
                    command.indirectObject == .hook,
                    await engine.playerLocationID == "cloakroom"
                else {
                    return nil
                }
                return ActionResult(
                    stateChanges: [
                        await engine.scoreChange(by: 2 - score),
                        await engine.flag(engine.location(.bar), with: .isLit),
                    ]
                )
            case .take:
                guard let bar = await engine.location("bar") else {
                    throw ActionResponse.internalEngineError("Location 'bar' not found.")
                }
                if let removeLit = await engine.flag(engine.location(.bar), remove: .isLit) {
                    return ActionResult(stateChanges: [removeLit])
                }
            default:
                break
            }
        case .afterTurn, .onInitialize, .onDestroy:
            break
        }
        return nil
    }

    static func hookHandler(_ engine: GameEngine, _ event: ItemEvent) async throws -> ActionResult? {
        guard case .beforeTurn(let command) = event,
              command.verbID == "examine",
              let cloak = await engine.item("cloak")
        else {
            return nil
        }
        let hookDetail = if cloak.parent == .item("hook") {
            "with a cloak hanging on it"
        } else {
            "screwed to the wall"
        }
        throw ActionResponse.custom("It's just a small brass hook, \(hookDetail).")
    }

    static func messageHandler(_ engine: GameEngine, _ event: ItemEvent) async throws -> ActionResult? {
        guard case .beforeTurn(let command) = event,
              command.verbID == "examine",
              await engine.gameState.player.currentLocationID == "bar"
        else {
            return nil
        }
        // Fix: Check location exists before accessing properties
        guard let bar = await engine.location("bar") else {
            throw ActionResponse.internalEngineError("Location 'bar' not found.")
        }
        guard bar.hasFlag(.isLit) else {
            throw ActionResponse.prerequisiteNotMet("It's too dark to do that.")
        }

        let disturbedCount = await engine.getStateValue(key: "disturbedCounter")?.toInt ?? 0
        let finalMessage: String
        if disturbedCount > 1 {
            finalMessage = "The message simply reads: \"You lose.\""
            await engine.requestQuit()
        } else {
            finalMessage = "The message simply reads: \"You win.\""
            await engine.requestQuit()
        }
        // Throw error to display the message via engine reporting
        throw ActionResponse.custom(finalMessage)
    }
}
