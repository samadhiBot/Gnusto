import GnustoEngine

// MARK: - Forest Area

enum Forest {
    // MARK: - Locations

    static let canyonView = Location(
        id: .canyonView,
        .name("Canyon View"),
        .description(
            """
            You are in a clearing, with a forest surrounding you on all
            sides. A path leads south.
            """
        ),
        .exits(
            .down(blocked: "GRATING PUZZLE"),
            .east(.forest2),
            .south(.forestPath),
            .west(.forest1),
        ),
        .inherentlyLit,
        .localGlobals(.forest)
    )

    static let clearing = Location(
        id: .clearing,
        .name("Clearing"),
        .description(
            """
            You are in a small clearing in a well marked forest path that
            extends to the east and west.
            """
        ),
        .exits(
            .east(.canyonView),
            .north(.forest2),
            .south(.forest3),
            .west(.eastOfHouse),
            .up(blocked: "There is no tree here suitable for climbing."),
        ),
        .inherentlyLit,
        .localGlobals(.songbird, .whiteHouse, .forest)
    )

    static let forest1 = Location(
        id: .forest1,
        .name("Forest"),
        .description(
            """
            This is a forest, with trees in all directions. To the east,
            there appears to be sunlight.
            """
        ),
        .exits(
            .north(.gratingClearing),
            .east(.forestPath),
            .south(.forest3),
            // Note: UP and WEST exits have custom messages
        ),
        .inherentlyLit,
        .localGlobals(.songbird, .whiteHouse, .forest)
    )

    static let forest2 = Location(
        id: .forest2,
        .name("Forest"),
        .description(
            """
            This is a dimly lit forest, with large trees all around.
            """
        ),
        .exits(
            .east(.mountains),
            .south(.clearing),
            .west(.forestPath),
            // Note: UP and NORTH exits have custom messages
        ),
        .inherentlyLit,
        .localGlobals(.songbird, .whiteHouse, .forest)
    )

    static let forest3 = Location(
        id: .forest3,
        .name("Forest"),
        .description(
            """
            This is a dimly lit forest, with large trees all around.
            """
        ),
        .exits(
            .north(.clearing),
            .west(.forest1),
            .northwest(.southOfHouse),
            // Note: UP, EAST, and SOUTH exits have custom messages
        ),
        .inherentlyLit,
        .localGlobals(.songbird, .whiteHouse, .forest)
    )

    static let forestPath = Location(
        id: .forestPath,
        .name("Forest Path"),
        .description(
            """
            This is a path winding through a dimly lit forest. The path heads
            north-south here. One particularly large tree with some low branches
            stands at the edge of the path.
            """
        ),
        .exits(
            .up(.upATree),
            .north(.gratingClearing),
            .east(.forest2),
            .south(.northOfHouse),
            .west(.forest1),
        ),
        .inherentlyLit,
        .localGlobals(.songbird, .whiteHouse, .forest)
    )

    static let gratingClearing = Location(
        id: .gratingClearing,
        .name("Clearing"),
        .exits(
            .east(.forest2),
            .west(.forest1),
            .south(.forestPath),
            .north(blocked: "The forest becomes impenetrable to the north."),
            // Note: DOWN exit has special condition handling via GRATING-EXIT
        ),
        .inherentlyLit,
        .localGlobals(.whiteHouse, .forest, .grate)
    )

    static let mountains = Location(
        id: .mountains,
        .name("Forest"),
        .description("The forest thins out, revealing impassable mountains."),
        .exits(
            .east(blocked: "The mountains are impassable."),
            .north(.forest2),
            .south(.forest2),
            .up(blocked: "The mountains are impassable."),
            .west(.forest2),
        ),
        .inherentlyLit,
        .localGlobals(.whiteHouse)
    )

    static let upATree = Location(
        id: .upATree,
        .name("Up a Tree"),
        .description(
            """
            You are about 10 feet above the ground nestled among some large branches.
            The nearest branch above you is above your reach.
            """
        ),
        .exits(
            .down(.forestPath),
        ),
        // Note: UP exit has custom message
        .inherentlyLit,
        .localGlobals(.forest, .songbird, .whiteHouse)
    )

    // MARK: - Items

    static let egg = Item(
        id: .egg,
        .name("jewel-encrusted egg"),
        .description(
            """
            The egg is about the size of a large duck egg. It is covered with fine gold and
            inlaid with lapis lazuli and mother-of-pearl. Unlike most eggs, this one is hinged
            and can be opened and closed. The egg appears to be closed.
            """
        ),
        .adjectives("jewel", "encrusted", "gold", "fine"),
        .synonyms("egg"),
        .in(.item(.nest)),
        .isTakable,
        .isOpenable,
        .isContainer
    )

    static let forest = Item(
        id: .forest,
        .name("forest"),
        .description("The forest is all around you, with trees in every direction."),
        .synonyms("trees", "pines", "hemlocks"),
        .omitDescription
    )

    static let grate = Item(
        id: .grate,
        .name("grating"),
        .synonyms("grate", "grating"),
        .isInvisible,
        .omitDescription
    )

    static let nest = Item(
        id: .nest,
        .name("bird's nest"),
        .synonyms("nest"),
        .adjectives("birds"),
        .isTakable,
        .isFlammable,
        .isContainer,
        .isOpen,
        .isSearchable,
        .firstDescription("Beside you on the branch is a small bird's nest."),
        .capacity(20),
        .in(.upATree)
    )

    static let pileOfLeaves = Item(
        id: .pileOfLeaves,
        .name("pile of leaves"),
        .synonyms("leaves", "leaf", "pile"),
        .firstDescription("On the ground is a pile of leaves."),
        .isTakable,
        .isFlammable,
        .requiresTryTake,
        .size(25),
        .in(.gratingClearing)
    )

    static let songbird = Item(
        id: .songbird,
        .name("songbird"),
        .synonyms("bird", "songbird"),
        .adjectives("song"),
        .omitDescription
        // Note: Has action handler SONGBIRD-F
    )

    static let tree = Item(
        id: .tree,
        .name("tree"),
        .description(
            "The tree is large and appears to have some low branches. It might be climbable."
        ),
        .adjectives("large", "storm", "tossed"),
        .synonyms("branch", "branches"),
        .in(.forestPath),
        .isClimbable,
        .omitDescription
    )
}

// MARK: - Event handlers

extension Forest {
    static let forestHandler = ItemEventHandler(for: .forest) {
        before(.listen) { context, command in
            // For ZIL FOREST-F functionality:
            ActionResult("The pines and the hemlocks seem to be murmuring.")
        }
    }

    static let gratingClearingComputer = LocationComputer(for: .gratingClearing) {
        locationProperty(.description) { context in
            let grate = try await context.engine.item(.grate)
            var description = [
                """
                You are in a clearing, with a forest surrounding you on all sides.
                A path leads south.
                """
            ]
            if await !grate.hasFlag(.isInvisible) {
                if await grate.isOpen {
                    description.append("There is an open grating, descending into darkness.")
                } else {
                    description.append("There is a grating securely fastened into the ground.")
                }
            }
            return .string(
                description.compactMap(\.self).joined(separator: .paragraph)
            )
        }
    }

    static let gratingClearingHandler = LocationEventHandler(for: .gratingClearing) {
        onEnter { context in
            // ZIL M-ENTER: If grate is not revealed, set it invisible
            let isGrateInvisible = try await context.engine.item(.grate).hasFlag(.isInvisible)
            if !isGrateInvisible {
                // Check if we need to hide it again (this would be unusual but following ZIL)
                // In ZIL, this sets INVISIBLE if GRATE-REVEALED is false
                // We'll interpret "not revealed" as "should be invisible"
                // This logic may need adjustment based on actual game flow
                return nil
            }
            return nil
        }
    }

    static let pileOfLeavesHandler = ItemEventHandler(for: .pileOfLeaves) {
        before(.move) { context, command in
            let grate = try await context.engine.item(.grate)

            // Check if grate is invisible
            let isGrateInvisible = await grate.hasFlag(.isInvisible)

            // Update the leaves description to show they've been disturbed
            let leaves = try await context.engine.item(.pileOfLeaves)

            let message =
                if isGrateInvisible {
                    "In disturbing the pile of leaves, a grating is revealed."
                } else {
                    "Done."
                }

            return try await ActionResult(
                message,
                grate.clearFlag(.isInvisible),
                context.item.setProperty(
                    .description,
                    to: .string("On the ground is a pile of leaves.")
                )
            )
        }
    }

    static let grateHandler = ItemEventHandler(for: .grate) {
        before(.examine) { context, command in
            if await context.item.hasFlag(.isInvisible) {
                nil
            } else {
                ActionResult("The grating is \(await context.item.isOpen ? "open" : "closed").")
            }
        }

        before(.close) { context, command in
            if await context.item.hasFlag(.isOpen) {
                ActionResult(
                    "The grating is closed.",
                    try await context.engine.item(.grate).clearFlag(.isOpen)
                )
            } else {
                ActionResult("The grating is already closed.")
            }
        }

        before(.lock) { context, command in
            let currentLocation = try await context.engine.player.location
            return if currentLocation.id == .gratingRoom {
                ActionResult(
                    "The grate is locked.",
                    try await context.engine.item(.grate).setFlag(.isLocked)
                )
            } else {
                ActionResult("You can't lock it from this side.")
            }
        }

        before(.open) { context, command in
            if let indirectObject = command.indirectObject,
                case .item(let keys) = indirectObject,
                keys.id == .keys
            {
                // OPEN GRATE WITH KEYS -> handle as unlock
                let currentLocation = try await context.engine.player.location

                guard try await context.engine.player.isHolding(keys.id) else {
                    return ActionResult("You don't have the keys.")
                }

                if currentLocation.id == .gratingRoom {
                    return ActionResult(
                        "The grate is unlocked.",
                        try await context.engine.item(.grate).clearFlag(.isLocked)
                    )
                } else if currentLocation.id == .gratingClearing {
                    return ActionResult("You can't reach the lock from here.")
                } else {
                    return nil
                }
            }

            // Check if grate is unlocked before allowing open/close
            let isLocked = try await context.engine.item(.grate).hasFlag(.isLocked)
            let currentLocation = try await context.engine.player.location

            if !isLocked {
                let isOpen = try await context.engine.item(.grate).hasFlag(.isOpen)
                if !isOpen {
                    let message =
                        if currentLocation.id == .gratingClearing {
                            "The grating opens."
                        } else {
                            "The grating opens to reveal trees above you."
                        }
                    return ActionResult(
                        message,
                        try await context.engine.item(.grate).setFlag(.isOpen)
                    )
                } else {
                    return ActionResult("The grating is already open.")
                }
            } else {
                return ActionResult("The grating is locked.")
            }
        }

        before(.unlock) { context, command in
            guard let indirectObject = command.indirectObject,
                case .item(let keys) = indirectObject
            else {
                if let indirectObject = command.indirectObject {
                    return ActionResult("Can you unlock a grating with that?")
                }
                return nil
            }

            let currentLocation = try await context.engine.player.location

            guard try await context.engine.player.isHolding(keys.id) else {
                return ActionResult("You don't have the keys.")
            }

            if currentLocation.id == .gratingRoom {
                return ActionResult(
                    "The grate is unlocked.",
                    try await context.engine.item(.grate).clearFlag(.isLocked)
                )
            } else if currentLocation.id == .gratingClearing {
                return ActionResult("You can't reach the lock from here.")
            } else {
                return nil
            }
        }
    }
}
