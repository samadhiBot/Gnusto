import GnustoEngine

enum Maze {
    static let maze1 = Location(
        id: .maze1,
        .name("Maze"),
        .description(
            """
            This is part of a maze of twisty little passages, all alike.
            """
        ),
        .exits(
            .east(.trollRoom),
            .north(.maze1),
            .south(.maze2),
            .west(.maze4)
        )
    )

    static let maze2 = Location(
        id: .maze2,
        .name("Maze"),
        .description(
            """
            This is part of a maze of twisty little passages, all alike.
            """
        ),
        .exits(
            .south(.maze1),
            .east(.maze3)
            // Note: DOWN exit has special condition handling via MAZE-DIODES to MAZE-4
        )
    )

    static let maze3 = Location(
        id: .maze3,
        .name("Maze"),
        .description(
            """
            This is part of a maze of twisty little passages, all alike.
            """
        ),
        .exits(
            .west(.maze2),
            .north(.maze4),
            .up(.maze5)
        )
    )

    static let maze4 = Location(
        id: .maze4,
        .name("Maze"),
        .description(
            """
            This is part of a maze of twisty little passages, all alike.
            """
        ),
        .exits(
            .west(.maze3),
            .north(.maze1),
            .east(.deadEnd1)
        )
    )

    static let deadEnd1 = Location(
        id: .deadEnd1,
        .name("Dead End"),
        .description(
            """
            You have come to a dead end in the maze.
            """
        ),
        .exits(
            .south(.maze4)
        )
    )

    static let maze5 = Location(
        id: .maze5,
        .name("Maze"),
        .description(
            """
            This is part of a maze of twisty little passages, all alike.
            A skeleton, probably the remains of a luckless adventurer, lies here.
            """
        ),
        .exits(
            .east(.deadEnd2),
            .north(.maze3),
            .southwest(.maze6)
        )
    )

    static let deadEnd2 = Location(
        id: .deadEnd2,
        .name("Dead End"),
        .description(
            """
            You have come to a dead end in the maze.
            """
        ),
        .exits(
            .west(.maze5)
        )
    )

    static let maze6 = Location(
        id: .maze6,
        .name("Maze"),
        .description(
            """
            This is part of a maze of twisty little passages, all alike.
            """
        ),
        .exits(
            .down(.maze5),
            .east(.maze7),
            .west(.maze6),
            .up(.maze9)
        )
    )

    static let maze7 = Location(
        id: .maze7,
        .name("Maze"),
        .description(
            """
            This is part of a maze of twisty little passages, all alike.
            """
        ),
        .exits(
            .up(.maze14),
            .west(.maze6),
            .east(.maze8),
            .south(.maze14)
        )
    )

    static let maze8 = Location(
        id: .maze8,
        .name("Maze"),
        .description(
            """
            This is part of a maze of twisty little passages, all alike.
            """
        ),
        .exits(
            .northeast(.maze7),
            .west(.maze8),
            .southeast(.deadEnd3)
        )
    )

    static let deadEnd3 = Location(
        id: .deadEnd3,
        .name("Dead End"),
        .description(
            """
            You have come to a dead end in the maze.
            """
        ),
        .exits(
            .north(.maze8)
        )
    )

    static let maze9 = Location(
        id: .maze9,
        .name("Maze"),
        .description(
            """
            This is part of a maze of twisty little passages, all alike.
            """
        ),
        .exits(
            .north(.maze6),
            .east(.maze10),
            .south(.maze13),
            .west(.maze12),
            .northwest(.maze9)
            // Note: DOWN exit has special condition handling via MAZE-DIODES to MAZE-11
        )
    )

    static let maze10 = Location(
        id: .maze10,
        .name("Maze"),
        .description(
            """
            This is part of a maze of twisty little passages, all alike.
            """
        ),
        .exits(
            .east(.maze9),
            .west(.maze13),
            .up(.maze11)
        )
    )

    static let maze11 = Location(
        id: .maze11,
        .name("Maze"),
        .description(
            """
            This is part of a maze of twisty little passages, all alike.
            """
        ),
        .exits(
            .northeast(.gratingRoom),
            .down(.maze10),
            .northwest(.maze13),
            .southwest(.maze12)
        )
    )

    static let gratingRoom = Location(
        id: .gratingRoom,
        .name("Grating Room"),
        .description(
            """
            You are in a small room near the maze. There is a grating overhead, but it is closed.
            """
        ),
        .exits(
            .southwest(.maze11)
            // Note: UP exit to grating clearing conditional on grate being open
        ),
        .localGlobals(.grate)
    )

    static let maze12 = Location(
        id: .maze12,
        .name("Maze"),
        .description(
            """
            This is part of a maze of twisty little passages, all alike.
            """
        ),
        .exits(
            .southwest(.maze11),
            .east(.maze13),
            .up(.maze9),
            .north(.deadEnd4)
        )
    )

    static let deadEnd4 = Location(
        id: .deadEnd4,
        .name("Dead End"),
        .description(
            """
            You have come to a dead end in the maze.
            """
        ),
        .exits(
            .south(.maze12)
        )
    )

    static let maze13 = Location(
        id: .maze13,
        .name("Maze"),
        .description(
            """
            This is part of a maze of twisty little passages, all alike.
            """
        ),
        .exits(
            .east(.maze9),
            .down(.maze12),
            .south(.maze10),
            .west(.maze11)
        )
    )

    static let maze14 = Location(
        id: .maze14,
        .name("Maze"),
        .description(
            """
            This is part of a maze of twisty little passages, all alike.
            """
        ),
        .exits(
            .west(.maze15),
            .northwest(.maze14),
            .northeast(.maze7),
            .south(.maze7)
        )
    )

    static let maze15 = Location(
        id: .maze15,
        .name("Maze"),
        .description(
            """
            This is part of a maze of twisty little passages, all alike.
            """
        ),
        .exits(
            .west(.maze14),
            .south(.maze7),
            .southeast(.cyclopsRoom)
        )
    )
}

// MARK: - Items

extension Maze {
    static let bagOfCoins = Item(
        id: .bagOfCoins,
        .name("leather bag of coins"),
        .synonyms("bag", "coins", "treasure"),
        .adjectives("old", "leather"),
        .isTakable,
        .description("An old leather bag, bulging with coins, is here."),
        .size(15),
        .in(.maze5),
        .value(10)
        // Note: VALUE 10, TVALUE 5, has action handler BAG-OF-COINS-F
    )

    static let bones = Item(
        id: .bones,
        .name("skeleton"),
        .synonyms("bones", "skeleton", "body"),
        .requiresTryTake,
        .omitDescription,
        .in(.maze5)
        // Note: Has action handler SKELETON
    )

    static let burnedOutLantern = Item(
        id: .burnedOutLantern,
        .name("burned-out lantern"),
        .synonyms("lantern", "lamp"),
        .adjectives("rusty", "burned", "dead", "useless"),
        .isTakable,
        .firstDescription("The deceased adventurer's useless lantern is here."),
        .size(20),
        .in(.maze5)
    )

    static let keys = Item(
        id: .keys,
        .name("skeleton key"),
        .synonyms("key"),
        .adjectives("skeleton"),
        .isTakable,
        .isTool,
        .size(10),
        .in(.maze5)
    )

    static let rustyKnife = Item(
        id: .rustyKnife,
        .name("rusty knife"),
        .synonyms("knives", "knife"),
        .adjectives("rusty"),
        .isTakable,
        .requiresTryTake,
        .isWeapon,
        .isTool,
        .firstDescription("Beside the skeleton is a rusty knife."),
        .size(20),
        .in(.maze5)
        // Note: Has action handler RUSTY-KNIFE-FCN
    )
}
