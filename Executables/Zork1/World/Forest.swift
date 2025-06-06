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
        .exits([:]),
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
        .localGlobals(.tree, .songbird, .whiteHouse, .forest)
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
        .localGlobals(.tree, .songbird, .whiteHouse, .forest)
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
        .localGlobals(.tree, .songbird, .whiteHouse, .forest)
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
        .localGlobals(.tree, .songbird, .whiteHouse, .forest)
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
        .localGlobals(.tree, .songbird, .whiteHouse, .forest)
    )

    static let gratingClearing = Location(
        id: .gratingClearing,
        .name("Clearing"),
        .description("""
            You are in a clearing, with a forest surrounding you on all sides.
            A path leads south.
            """),
        .exits([
            .east: .to(.forest2),
            .west: .to(.forest1),
            .south: .to(.forestPath),
            // Note: NORTH exit has custom message
            // Note: DOWN exit has special condition handling via GRATING-EXIT
        ]),
        .inherentlyLit,
        .localGlobals(.whiteHouse, .grate)
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
        .localGlobals(.tree, .whiteHouse)
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
        .localGlobals(.tree, .forest, .songbird, .whiteHouse)
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

    static let leaves = Item(
        id: .leaves,
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

    static let tree = Item(
        id: .tree,
        .name("tree"),
        .description("""
            The tree is large and appears to have some low branches. It might be climbable.
            """),
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
}
