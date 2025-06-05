import GnustoEngine

// MARK: - Forest Area

enum Forest {
    // MARK: - Locations

    static let forest1 = Location(
        id: .forest1,
        .name("Forest"),
        .description("This is a forest, with trees in all directions. To the east, there appears to be sunlight."),
        .exits([
            .south: .to(.path),
            .east: .to(.westOfHouse),
            .north: .to(.forest2),
        ]),
        .inherentlyLit,
        .localGlobals(.forest)
    )

    static let forest2 = Location(
        id: .forest2,
        .name("Forest"),
        .description("This is a dimly lit forest, with large trees all around."),
        .exits([
            .south: .to(.forest1),
            .east: .to(.forest3),
        ]),
        .inherentlyLit,
        .localGlobals(.forest)
    )

    static let forest3 = Location(
        id: .forest3,
        .name("Forest"),
        .description("This is a dimly lit forest, with large trees all around."),
        .exits([
            .west: .to(.forest2),
            .north: .to(.mountains),
        ]),
        .inherentlyLit,
        .localGlobals(.forest)
    )

    static let mountains = Location(
        id: .mountains,
        .name("Forest"),
        .description("The forest thins out, revealing impassable mountains."),
        .exits([
            .south: .to(.forest3),
            .east: .blocked("The mountains are impassable."),
            .north: .blocked("The forest becomes impenetrable to the north."),
            .west: .blocked("The mountains are impassable."),
        ]),
        .inherentlyLit,
        .localGlobals(.forest)
    )

    static let path = Location(
        id: .path,
        .name("Forest Path"),
        .description("""
            This is a path winding through a dimly lit forest. The path heads north-south here.
            One particularly large tree with some low branches stands at the edge of the path.
            """),
        .exits([
            .north: .to(.forest1),
            .south: .to(.northOfHouse),
            .up: .to(.upATree),
        ]),
        .inherentlyLit,
        .localGlobals(.forest)
    )

    static let upATree = Location(
        id: .upATree,
        .name("Up a Tree"),
        .description("""
            You are about 10 feet above the ground nestled among some large branches. The
            nearest branch above you is above your reach.
            """),
        .exits([
            .down: .to(.path),
        ]),
        .inherentlyLit,
        .localGlobals(.forest)
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
        .isScenery
    )

    static let leaves = Item(
        id: .leaves,
        .name("leaves"),
        .description("These are the leaves of the tree. The tree is large."),
        .synonyms("leaf"),
        .in(.location(.upATree))
    )

    static let nest = Item(
        id: .nest,
        .name("bird's nest"),
        .description("The bird's nest is skillfully woven of twigs and leaves."),
        .adjectives("bird", "birds"),
        .synonyms("nest"),
        .in(.location(.upATree)),
        .isTakable,
        .isContainer,
        .isOpenable
    )

    static let tree = Item(
        id: .tree,
        .name("tree"),
        .description("The tree is large and appears to have some low branches. It might be climbable."),
        .adjectives("large", "storm", "tossed"),
        .synonyms("branch", "branches"),
        .in(.location(.path)),
        .isClimbable
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
