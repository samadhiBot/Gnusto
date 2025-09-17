import GnustoEngine

/// A game world representing the classic tutorial game "Cloak of Darkness".
///
/// This struct contains all the locations, items, and event handlers that make up
/// the simple adventure game where the player must navigate an opera house,
/// hang up their cloak, and read a message in the bar.
struct OperaHouse {

    // MARK: - Foyer of the Opera House

    let foyer = Location(
        id: .foyer,
        .name("Foyer of the Opera House"),
        .description(
            """
            You are standing in a spacious hall, splendidly decorated in red
            and gold, with glittering chandeliers overhead. The entrance from
            the street is to the north, and there are doorways south and west.
            """
        ),
        .exits(
            .south(.bar),
            .west(.cloakroom),
            .north(
                blocked: """
                    You've only just arrived, and besides, the weather outside
                    seems to be getting worse.
                    """
            )
        ),
        .inherentlyLit
    )

    // MARK: - Cloakroom

    let cloakroom = Location(
        id: .cloakroom,
        .name("Cloakroom"),
        .description(
            """
            The walls of this small room were clearly once lined with hooks,
            though now only one remains. The exit is a door to the east.
            """
        ),
        .exits(.east(.foyer)),
        .inherentlyLit
    )

    let hook = Item(
        id: .hook,
        .adjectives("small", "brass"),
        .in(.cloakroom),
        .omitDescription,
        .isSurface,
        .name("small brass hook"),
        .synonyms("peg"),
    )

    // MARK: - Bar

    let bar = Location(
        id: .bar,
        .name("Bar"),
        .description(
            """
            The bar, much rougher than you'd have guessed after the opulence
            of the foyer to the north, is completely empty. There seems to
            be some sort of message scrawled in the sawdust on the floor.
            """
        ),
        .exits(.north(.foyer))
    )

    let message = Item(
        id: .message,
        .name("scrawled message"),
        .in(.bar),
        .synonyms("sawdust", "floor"),
        .isReadable,
        .omitDescription
    )

    // MARK: - Items

    let cloak = Item(
        id: .cloak,
        .name("velvet cloak"),
        .description(
            """
            A handsome cloak, of velvet trimmed with satin, and slightly
            spattered with raindrops. Its blackness is so deep that it
            almost seems to suck light from the room.
            """
        ),
        .adjectives("handsome", "dark", "black", "velvet", "satin"),
        .in(.player),
        .isTakable,
        .isWearable,
        .isWorn,
    )

    // MARK: - Location event handlers

    let barHandler = LocationEventHandler(for: .bar) {
        // First: if location is lit, yield to normal processing
        beforeTurn { context, _ in
            if try await context.location.isLit {
                return ActionResult.yield
            }
            return nil  // not handled, try next matcher
        }

        // Second: handle north movement in dark
        beforeTurn(.move) { context, command in
            if command.direction == .north {
                return ActionResult.yield
            } else {
                return ActionResult(
                    "Blundering around in the dark isn't a good idea!",
                    await context.engine.adjustGlobal(.barMessageDisturbances, by: 2)
                )
            }
        }

        // Third: handle meta commands in dark
        beforeTurn(.meta) { _, _ in
            return ActionResult.yield
        }

        // Fourth: catch-all for other commands in dark
        beforeTurn { context, _ in
            return ActionResult(
                "In the dark? You could easily disturb something!",
                await context.engine.adjustGlobal(.barMessageDisturbances, by: 1)
            )
        }
    }

    // MARK: - Item event handlers

    let cloakHandler = ItemEventHandler(for: .cloak) {
        before(.drop, .insert) { context, _ in
            guard try await context.player.location.id == .cloakroom else {
                throw ActionResponse.feedback(
                    "This isn't the best place to leave a smart cloak lying around."
                )
            }
            return nil
        }

        after { context, command in
            guard try await context.player.location.id == .cloakroom else {
                return nil
            }

            if command.hasIntent(.drop, .insert) {
                var changes = [
                    try await context.engine.location(.bar).setFlag(.isLit)
                ]
                if await context.player.score < 1 {
                    changes.append(await context.player.updateScore(by: 1))
                }
                return ActionResult(changes: changes)
            }

            if command.hasIntent(.take) {
                return ActionResult(
                    try await context.engine.location(.bar).clearFlag(.isLit)
                )
            }

            return nil
        }
    }

    let hookHandler = ItemEventHandler(for: .hook) {
        before(.examine) { context, _ in
            let hookDetail =
                if try await context.item.isHolding(.cloak) {
                    "with a cloak hanging on it"
                } else {
                    "screwed to the wall"
                }
            return ActionResult("It's just a small brass hook, \(hookDetail).")
        }
    }

    let messageHandler = ItemEventHandler(for: .message) {
        before(.examine, .read) { context, _ in
            guard try await context.player.location.id == .bar else {
                return nil
            }

            let bar = try await context.engine.location(.bar)
            guard await bar.hasFlag(.isLit) else {
                throw ActionResponse.feedback("It's too dark to do that.")
            }

            let disturbedCount = await context.engine.global(.barMessageDisturbances)?.toInt ?? 0

            await context.engine.requestQuit()

            if disturbedCount < 2 {
                return ActionResult(
                    """
                    The message, neatly marked in the sawdust, reads...

                    "You win."
                    """,
                    await context.player.updateScore(by: 1)
                )
            } else {
                throw ActionResponse.feedback(
                    """
                    The message has been carelessly trampled, making it
                    difficult to read. You can just distinguish the words...

                    "You lose."
                    """)
            }
        }
    }
}
