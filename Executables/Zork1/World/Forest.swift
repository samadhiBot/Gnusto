import GnustoEngine

// MARK: - Forest Area

enum Forest {
    // MARK: - Locations

    static let canyonView = Location(
        id: .canyonView,
        .name("Canyon View"),
        .description("""
            You are in a clearing, with a forest surrounding you on all
            sides. A path leads south.
            """),
//        .exits([:]),
//            .down: .blocked("GRATING PUZZLE"),
//            .east: .to(.forest2),
//            .south: .to(.forestPath),
//            .west: .to(.forest1),
        .inherentlyLit,
        .localGlobals(.forest)
    )

    static let clearing = Location(
        id: .clearing,
        .name("Clearing"),
        .description("""
            You are in a small clearing in a well marked forest path that
            extends to the east and west.
            """),
        .exits([
            .east: .to(.canyonView),
            .north: .to(.forest2),
            .south: .to(.forest3),
            .west: .to(.eastOfHouse),
            .up: .blocked("There is no tree here suitable for climbing."),
        ]),
        .inherentlyLit,
        .localGlobals(.songbird, .whiteHouse, .forest)
    )

    static let forest1 = Location(
        id: .forest1,
        .name("Forest"),
        .description("""
            This is a forest, with trees in all directions. To the east,
            there appears to be sunlight.
            """),
        .exits([
            .north: .to(.gratingClearing),
            .east: .to(.forestPath),
            .south: .to(.forest3),
            // Note: UP and WEST exits have custom messages
        ]),
        .inherentlyLit,
        .localGlobals(.songbird, .whiteHouse, .forest)
    )

    static let forest2 = Location(
        id: .forest2,
        .name("Forest"),
        .description("""
            This is a dimly lit forest, with large trees all around.
            """),
        .exits([
            .east: .to(.mountains),
            .south: .to(.clearing),
            .west: .to(.forestPath),
            // Note: UP and NORTH exits have custom messages
        ]),
        .inherentlyLit,
        .localGlobals(.songbird, .whiteHouse, .forest)
    )

    static let forest3 = Location(
        id: .forest3,
        .name("Forest"),
        .description("""
            This is a dimly lit forest, with large trees all around.
            """),
        .exits([
            .north: .to(.clearing),
            .west: .to(.forest1),
            .northwest: .to(.southOfHouse),
            // Note: UP, EAST, and SOUTH exits have custom messages
        ]),
        .inherentlyLit,
        .localGlobals(.songbird, .whiteHouse, .forest)
    )

    static let forestPath = Location(
        id: .forestPath,
        .name("Forest Path"),
        .description("""
            This is a path winding through a dimly lit forest. The path heads
            north-south here. One particularly large tree with some low branches
            stands at the edge of the path.
            """),
        .exits([
            .up: .to(.upATree),
            .north: .to(.gratingClearing),
            .east: .to(.forest2),
            .south: .to(.northOfHouse),
            .west: .to(.forest1)
        ]),
        .inherentlyLit,
        .localGlobals(.songbird, .whiteHouse, .forest)
    )

    static let gratingClearing = Location(
        id: .gratingClearing,
        .name("Clearing"),
//        .description("""
//            You are in a clearing, with a forest surrounding you on all sides.
//            A path leads south.
//            """),
        .exits([
            .east: .to(.forest2),
            .west: .to(.forest1),
            .south: .to(.forestPath),
            // Note: NORTH exit has custom message
            // Note: DOWN exit has special condition handling via GRATING-EXIT
        ]),
        .inherentlyLit,
        .localGlobals(.whiteHouse, .forest, .grate)
    )

    static let mountains = Location(
        id: .mountains,
        .name("Forest"),
        .description("The forest thins out, revealing impassable mountains."),
        .exits([
            .east: .blocked("The mountains are impassable."),
            .north: .to(.forest2),
            .south: .to(.forest2),
            .up: .blocked("The mountains are impassable."),
            .west: .to(.forest2),
        ]),
        .inherentlyLit,
        .localGlobals(.whiteHouse)
    )

    static let upATree = Location(
        id: .upATree,
        .name("Up a Tree"),
        .description("""
            You are about 10 feet above the ground nestled among some large branches.
            The nearest branch above you is above your reach.
            """),
        .exits([
            .down: .to(.forestPath),
            // Note: UP exit has custom message
        ]),
        .inherentlyLit,
        .localGlobals(.forest, .songbird, .whiteHouse)
    )

    // MARK: - Items

    static let egg = Item(
        id: .egg,
        .name("jewel-encrusted egg"),
        .description("""
            The egg is about the size of a large duck egg. It is covered with fine gold and
            inlaid with lapis lazuli and mother-of-pearl. Unlike most eggs, this one is hinged
            and can be opened and closed. The egg appears to be closed.
            """),
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
        .isDoor,
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
        .in(.location(.upATree))
    )

    static let pileOfLeaves = Item(
        id: .pileOfLeaves,
        .name("pile of leaves"),
        .synonyms("leaves", "leaf", "pile"),
        .isTakable,
        .isFlammable,
        .requiresTryTake,
        .description("On the ground is a pile of leaves."),
        .size(25),
        .in(.location(.gratingClearing))
        // Note: Has action handler LEAF-PILE
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
        .in(.location(.forestPath)),
        .isClimbable,
        .omitDescription
    )
}

// MARK: - Event handlers

extension Forest {
    static let forestHandler = ItemEventHandler { engine, event in
        switch event {
        case .beforeTurn(let command):
            switch command.verb {
            // For ZIL FOREST-F functionality:
            case .listen:
                return ActionResult("The pines and the hemlocks seem to be murmuring.")
            default:
                return nil
            }
        case .afterTurn:
            return nil
        }
    }

    /*
    <ROUTINE CLEARING-FCN (RARG)
         <COND (<EQUAL? .RARG ,M-ENTER>
            <COND (<NOT ,GRATE-REVEALED>
                   <FSET ,GRATE ,INVISIBLE>)>)
               (<EQUAL? .RARG ,M-LOOK>
            <TELL
    "You are in a clearing, with a forest surrounding you on all sides. A
    path leads south.">
            <COND (<FSET? ,GRATE ,OPENBIT>
                   <CRLF>
                   <TELL
    "There is an open grating, descending into darkness.">)
                  (,GRATE-REVEALED
                   <CRLF>
                   <TELL
    "There is a grating securely fastened into the ground.">)>
            <CRLF>)>>

     */

    static let gratingClearingComputer = LocationComputer { attributeID, gameState in
        switch attributeID {
        case .description:
            let isGrateInvisible = try gameState.hasFlag(.isInvisible, on: .grate)
            let isGrateOpen = try gameState.hasFlag(.isOpen, on: .grate)
            var description = [
                """
                You are in a clearing, with a forest surrounding you on all sides.
                A path leads south.
                """
            ]
            if !isGrateInvisible {
                if isGrateOpen {
                    description.append("There is an open grating, descending into darkness.")
                } else {
                    description.append("There is a grating securely fastened into the ground.")
                }
            }
            return .string(description.joined(separator: "\n\n"))

        default:
            return nil
        }
    }

    static let gratingClearingHandler = LocationEventHandler { engine, event in
        switch event {
        case .onEnter:
            // ZIL M-ENTER: If grate is not revealed, set it invisible
            let isGrateInvisible = try await engine.hasFlag(.isInvisible, on: .grate)
            if !isGrateInvisible {
                // Check if we need to hide it again (this would be unusual but following ZIL)
                // In ZIL, this sets INVISIBLE if GRATE-REVEALED is false
                // We'll interpret "not revealed" as "should be invisible"
                // This logic may need adjustment based on actual game flow
                return nil
            }
            return nil

        case .beforeTurn(let command):
            if command.verb == .look {
                // ZIL M-LOOK: Custom description based on grate state
                let isGrateInvisible = try await engine.hasFlag(.isInvisible, on: .grate)
                let isGrateOpen = try await engine.hasFlag(.isOpen, on: .grate)

                var description = """
                    You are in a clearing, with a forest surrounding you on all sides.
                    A path leads south.
                    """

                if !isGrateInvisible {
                    if isGrateOpen {
                        description += "\n\nThere is an open grating, descending into darkness."
                    } else {
                        description += "\n\nThere is a grating securely fastened into the ground."
                    }
                }

                return ActionResult(description)
            }
            return nil

        case .afterTurn:
            return nil
        }
    }

    static let pileOfLeavesHandler = ItemEventHandler { engine, event in
        switch event {
        case .beforeTurn(let command):
            if command.verb == .move {
                // Check if grate is already revealed
                let isGrateInvisible = try await engine.hasFlag(.isInvisible, on: .grate)

                if isGrateInvisible {
                    // Reveal the grate - this is the LEAVES-APPEAR functionality
                    let grate = try await engine.item(.grate)
                    let change = await engine.clearFlag(.isInvisible, on: grate)
                    return ActionResult(
                        message: "In disturbing the pile of leaves, a grating is revealed.",
                        stateChange: change
                    )
                } else {
                    return ActionResult("Done.")
                }
            }
            return nil
        case .afterTurn:
            return nil
        }
    }

    static let grateHandler = ItemEventHandler { engine, event in
        switch event {
        case .beforeTurn(let command):
            switch command.verb {
            case .close:
                let isLocked = try await engine.hasFlag(.isLocked, on: .grate)
                if !isLocked {
                    let grate = try await engine.item(.grate)
                    if grate.hasFlag(.isOpen) {
                        return ActionResult(
                            message: "The grating is closed.",
                            stateChange: try await engine.clearFlag(.isOpen, on: .grate)
                        )
                    } else {
                        return ActionResult("The grating is already closed.")
                    }
                } else {
                    return ActionResult("The grating is locked.")
                }

            case .lock:
                let currentLocation = await engine.playerLocationID
                if currentLocation == .gratingRoom {
                    let changes = await engine.setFlag(.isLocked, on: try await engine.item(.grate))
                    return ActionResult(message: "The grate is locked.", stateChange: changes)
                } else if currentLocation == .gratingClearing {
                    return ActionResult("You can't lock it from this side.")
                } else {
                    return nil
                }

            case .open:
                if let indirectObject = command.indirectObject,
                   case .item(let keyItemID) = indirectObject,
                   keyItemID == .keys {
                    // OPEN GRATE WITH KEYS -> handle as unlock
                    let currentLocation = await engine.playerLocationID
                    let playerHasKeys = await engine.items(in: .player).contains { $0.id == .keys }

                    guard playerHasKeys else {
                        return ActionResult("You don't have the keys.")
                    }

                    if currentLocation == .gratingRoom {
                        let changes = await engine.clearFlag(.isLocked, on: try await engine.item(.grate))
                        return ActionResult(message: "The grate is unlocked.", stateChange: changes)
                    } else if currentLocation == .gratingClearing {
                        return ActionResult("You can't reach the lock from here.")
                    } else {
                        return nil
                    }
                }

                // Check if grate is unlocked before allowing open/close
                let isLocked = try await engine.hasFlag(.isLocked, on: .grate)
                let currentLocation = await engine.playerLocationID

                if !isLocked {
                    let isOpen = try await engine.hasFlag(.isOpen, on: .grate)
                    if !isOpen {
                        let changes = await engine.setFlag(.isOpen, on: try await engine.item(.grate))
                        let message = if currentLocation == .gratingClearing {
                            "The grating opens."
                        } else {
                            "The grating opens to reveal trees above you."
                        }
                        return ActionResult(message: message, stateChange: changes)
                    } else {
                        return ActionResult("The grating is already open.")
                    }
                } else {
                    return ActionResult("The grating is locked.")
                }

            case .unlock:
                guard let indirectObject = command.indirectObject,
                      case .item(let keyItemID) = indirectObject,
                      keyItemID == .keys else {
                    if let indirectObject = command.indirectObject {
                        return ActionResult("Can you unlock a grating with that?")
                    }
                    return nil
                }

                let currentLocation = await engine.playerLocationID
                let playerHasKeys = await engine.items(in: .player).contains { $0.id == .keys }

                guard playerHasKeys else {
                    return ActionResult("You don't have the keys.")
                }

                if currentLocation == .gratingRoom {
                    let changes = await engine.clearFlag(.isLocked, on: try await engine.item(.grate))
                    return ActionResult(message: "The grate is unlocked.", stateChange: changes)
                } else if currentLocation == .gratingClearing {
                    return ActionResult("You can't reach the lock from here.")
                } else {
                    return nil
                }

            default:
                return nil
            }
        case .afterTurn:
            return nil
        }
    }
}
