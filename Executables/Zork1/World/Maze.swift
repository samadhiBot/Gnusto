import GnustoEngine

enum Maze {
    static let maze1 = Location(
        id: .maze1,
        .name("Maze"),
        .description("""
            This is part of a maze of twisty little passages, all alike.
            """),
        .exits([
            .east: .to(.trollRoom),
            .north: .to(.maze1),
            .south: .to(.maze2),
            .west: .to(.maze4)
        ]),
        .isLand
    )

    static let maze2 = Location(
        id: .maze2,
        .name("Maze"),
        .description("""
            This is part of a maze of twisty little passages, all alike.
            """),
        .exits([
            .south: .to(.maze1),
            .east: .to(.maze3),
            // Note: DOWN exit has special condition handling via MAZE-DIODES to MAZE-4
        ]),
        .isLand
    )

    static let maze3 = Location(
        id: .maze3,
        .name("Maze"),
        .description("""
            This is part of a maze of twisty little passages, all alike.
            """),
        .exits([
            .west: .to(.maze2),
            .north: .to(.maze4),
            .up: .to(.maze5)
        ]),
        .isLand
    )

    static let maze4 = Location(
        id: .maze4,
        .name("Maze"),
        .description("""
            This is part of a maze of twisty little passages, all alike.
            """),
        .exits([
            .west: .to(.maze3),
            .north: .to(.maze1),
            .east: .to(.deadEnd1)
        ]),
        .isLand
    )

    static let deadEnd1 = Location(
        id: .deadEnd1,
        .name("Dead End"),
        .description("""
            You have come to a dead end in the maze.
            """),
        .exits([
            .south: .to(.maze4)
        ]),
        .isLand
    )

    static let maze5 = Location(
        id: .maze5,
        .name("Maze"),
        .description("""
            This is part of a maze of twisty little passages, all alike.
            A skeleton, probably the remains of a luckless adventurer, lies here.
            """),
        .exits([
            .east: .to(.deadEnd2),
            .north: .to(.maze3),
            .southwest: .to(.maze6)
        ]),
        .isLand
    )

    static let deadEnd2 = Location(
        id: .deadEnd2,
        .name("Dead End"),
        .description("""
            You have come to a dead end in the maze.
            """),
        .exits([
            .west: .to(.maze5)
        ]),
        .isLand
    )

    static let maze6 = Location(
        id: .maze6,
        .name("Maze"),
        .description("""
            This is part of a maze of twisty little passages, all alike.
            """),
        .exits([
            .down: .to(.maze5),
            .east: .to(.maze7),
            .west: .to(.maze6),
            .up: .to(.maze9)
        ]),
        .isLand
    )

    static let maze7 = Location(
        id: .maze7,
        .name("Maze"),
        .description("""
            This is part of a maze of twisty little passages, all alike.
            """),
        .exits([
            .up: .to(.maze14),
            .west: .to(.maze6),
            .east: .to(.maze8),
            .south: .to(.maze15),
            // Note: DOWN exit has special condition handling via MAZE-DIODES to DEAD-END-1
        ]),
        .isLand
    )

    static let maze8 = Location(
        id: .maze8,
        .name("Maze"),
        .description("""
            This is part of a maze of twisty little passages, all alike.
            """),
        .exits([
            .northeast: .to(.maze7),
            .west: .to(.maze8),
            .southeast: .to(.deadEnd3)
        ]),
        .isLand
    )

    static let deadEnd3 = Location(
        id: .deadEnd3,
        .name("Dead End"),
        .description("""
            You have come to a dead end in the maze.
            """),
        .exits([
            .north: .to(.maze8)
        ]),
        .isLand
    )

    static let maze9 = Location(
        id: .maze9,
        .name("Maze"),
        .description("""
            This is part of a maze of twisty little passages, all alike.
            """),
        .exits([
            .north: .to(.maze6),
            .east: .to(.maze10),
            .south: .to(.maze13),
            .west: .to(.maze12),
            .northwest: .to(.maze9),
            // Note: DOWN exit has special condition handling via MAZE-DIODES to MAZE-11
        ]),
        .isLand
    )

    static let maze10 = Location(
        id: .maze10,
        .name("Maze"),
        .description("""
            This is part of a maze of twisty little passages, all alike.
            """),
        .exits([
            .east: .to(.maze9),
            .west: .to(.maze13),
            .up: .to(.maze11)
        ]),
        .isLand
    )

    static let maze11 = Location(
        id: .maze11,
        .name("Maze"),
        .description("""
            This is part of a maze of twisty little passages, all alike.
            """),
        .exits([
            .northeast: .to(.gratingRoom),
            .down: .to(.maze10),
            .northwest: .to(.maze13),
            .southwest: .to(.maze12)
        ]),
        .isLand
    )

    static let gratingRoom = Location(
        id: .gratingRoom,
        .name("Grating Room"),
        .description("""
            You are in a small room near the maze. There is a grating overhead, but it is closed.
            """),
        .exits([
            .southwest: .to(.maze11),
            // Note: UP exit to grating clearing conditional on grate being open
        ]),
        .isLand,
        .localGlobals(.grate)
    )

    static let maze12 = Location(
        id: .maze12,
        .name("Maze"),
        .description("""
            This is part of a maze of twisty little passages, all alike.
            """),
        .exits([
            .southwest: .to(.maze11),
            .east: .to(.maze13),
            .up: .to(.maze9),
            .north: .to(.deadEnd4),
            // Note: DOWN exit has special condition handling via MAZE-DIODES to MAZE-5
        ]),
        .isLand
    )

    static let deadEnd4 = Location(
        id: .deadEnd4,
        .name("Dead End"),
        .description("""
            You have come to a dead end in the maze.
            """),
        .exits([
            .south: .to(.maze12)
        ]),
        .isLand
    )

    static let maze13 = Location(
        id: .maze13,
        .name("Maze"),
        .description("""
            This is part of a maze of twisty little passages, all alike.
            """),
        .exits([
            .east: .to(.maze9),
            .down: .to(.maze12),
            .south: .to(.maze10),
            .west: .to(.maze11)
        ]),
        .isLand
    )

    static let maze14 = Location(
        id: .maze14,
        .name("Maze"),
        .description("""
            This is part of a maze of twisty little passages, all alike.
            """),
        .exits([
            .west: .to(.maze15),
            .northwest: .to(.maze14),
            .northeast: .to(.maze7),
            .south: .to(.maze7)
        ]),
        .isLand
    )

    static let maze15 = Location(
        id: .maze15,
        .name("Maze"),
        .description("""
            This is part of a maze of twisty little passages, all alike.
            """),
        .exits([
            .west: .to(.maze14),
            .south: .to(.maze7),
            .southeast: .to(.cyclopsRoom)
        ]),
        .isLand
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
        .in(.location(.maze5))
        // Note: VALUE 10, TVALUE 5, has action handler BAG-OF-COINS-F
    )

    static let bones = Item(
        id: .bones,
        .name("skeleton"),
        .synonyms("bones", "skeleton", "body"),
        .requiresTryTake,
        .omitDescription,
        .in(.location(.maze5))
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
        .in(.location(.maze5))
    )

    static let grate = Item(
        id: .grate,
        .name("grating"),
        .synonyms("grate", "grating"),
        .isDoor,
        .omitDescription,
        .isInvisible
        // Note: Has action handler GRATE-FUNCTION
    )

    static let keys = Item(
        id: .keys,
        .name("skeleton key"),
        .synonyms("key"),
        .adjectives("skeleton"),
        .isTakable,
        .isTool,
        .size(10),
        .in(.location(.maze5))
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
        .in(.location(.maze5))
        // Note: Has action handler RUSTY-KNIFE-FCN
    )
}
