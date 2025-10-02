import GnustoEngine

enum Maze {
    static let maze1 = Location(.maze1)
        .name("Maze")
        .description(
            """
            This is part of a maze of twisty little passages, all alike.
            """
        )
        .east(.trollRoom)
        .north(.maze1)
        .south(.maze2)
        .west(.maze4)

    static let maze2 = Location(.maze2)
        .name("Maze")
        .description(
            """
            This is part of a maze of twisty little passages, all alike.
            """
        )
        .south(.maze1)
        .east(.maze3)
        // Note: DOWN exit has special condition handling via MAZE-DIODES to MAZE-4

    static let maze3 = Location(.maze3)
        .name("Maze")
        .description(
            """
            This is part of a maze of twisty little passages, all alike.
            """
        )
        .west(.maze2)
        .north(.maze4)
        .up(.maze5)

    static let maze4 = Location(.maze4)
        .name("Maze")
        .description(
            """
            This is part of a maze of twisty little passages, all alike.
            """
        )
        .west(.maze3)
        .north(.maze1)
        .east(.deadEnd1)

    static let deadEnd1 = Location(.deadEnd1)
        .name("Dead End")
        .description(
            """
            You have come to a dead end in the maze.
            """
        )
        .south(.maze4)

    static let maze5 = Location(.maze5)
        .name("Maze")
        .description(
            """
            This is part of a maze of twisty little passages, all alike.
            A skeleton, probably the remains of a luckless adventurer, lies here.
            """
        )
        .east(.deadEnd2)
        .north(.maze3)
        .southwest(.maze6)

    static let deadEnd2 = Location(.deadEnd2)
        .name("Dead End")
        .description(
            """
            You have come to a dead end in the maze.
            """
        )
        .west(.maze5)

    static let maze6 = Location(.maze6)
        .name("Maze")
        .description(
            """
            This is part of a maze of twisty little passages, all alike.
            """
        )
        .down(.maze5)
        .east(.maze7)
        .west(.maze6)
        .up(.maze9)

    static let maze7 = Location(.maze7)
        .name("Maze")
        .description(
            """
            This is part of a maze of twisty little passages, all alike.
            """
        )
        .up(.maze14)
        .west(.maze6)
        .east(.maze8)
        .south(.maze14)

    static let maze8 = Location(.maze8)
        .name("Maze")
        .description(
            """
            This is part of a maze of twisty little passages, all alike.
            """
        )
        .northeast(.maze7)
        .west(.maze8)
        .southeast(.deadEnd3)

    static let deadEnd3 = Location(.deadEnd3)
        .name("Dead End")
        .description(
            """
            You have come to a dead end in the maze.
            """
        )
        .north(.maze8)

    static let maze9 = Location(.maze9)
        .name("Maze")
        .description(
            """
            This is part of a maze of twisty little passages, all alike.
            """
        )
        .north(.maze6)
        .east(.maze10)
        .south(.maze13)
        .west(.maze12)
        .northwest(.maze9)
        // Note: DOWN exit has special condition handling via MAZE-DIODES to MAZE-11

    static let maze10 = Location(.maze10)
        .name("Maze")
        .description(
            """
            This is part of a maze of twisty little passages, all alike.
            """
        )
        .east(.maze9)
        .west(.maze13)
        .up(.maze11)

    static let maze11 = Location(.maze11)
        .name("Maze")
        .description(
            """
            This is part of a maze of twisty little passages, all alike.
            """
        )
        .northeast(.gratingRoom)
        .down(.maze10)
        .northwest(.maze13)
        .southwest(.maze12)

    static let gratingRoom = Location(.gratingRoom)
        .name("Grating Room")
        .description(
            """
            You are in a small room near the maze. There is a grating overhead, but it is closed.
            """
        )
        .southwest(.maze11)
        // Note: UP exit to grating clearing conditional on grate being open
        .localGlobals(.grate)

    static let maze12 = Location(.maze12)
        .name("Maze")
        .description(
            """
            This is part of a maze of twisty little passages, all alike.
            """
        )
        .southwest(.maze11)
        .east(.maze13)
        .up(.maze9)
        .north(.deadEnd4)

    static let deadEnd4 = Location(.deadEnd4)
        .name("Dead End")
        .description(
            """
            You have come to a dead end in the maze.
            """
        )
        .south(.maze12)

    static let maze13 = Location(.maze13)
        .name("Maze")
        .description(
            """
            This is part of a maze of twisty little passages, all alike.
            """
        )
        .east(.maze9)
        .down(.maze12)
        .south(.maze10)
        .west(.maze11)

    static let maze14 = Location(.maze14)
        .name("Maze")
        .description(
            """
            This is part of a maze of twisty little passages, all alike.
            """
        )
        .west(.maze15)
        .northwest(.maze14)
        .northeast(.maze7)
        .south(.maze7)

    static let maze15 = Location(.maze15)
        .name("Maze")
        .description(
            """
            This is part of a maze of twisty little passages, all alike.
            """
        )
        .west(.maze14)
        .south(.maze7)
        .southeast(.cyclopsRoom)
}

// MARK: - Items

extension Maze {
    static let bagOfCoins = Item(.bagOfCoins)
        .name("leather bag of coins")
        .synonyms("bag", "coins", "treasure")
        .adjectives("old", "leather")
        .isTakable
        .description("An old leather bag, bulging with coins, is here.")
        .size(15)
        .in(.maze5)
        .value(10)
        // Note: VALUE 10, TVALUE 5, has action handler BAG-OF-COINS-F

    static let bones = Item(.bones)
        .name("skeleton")
        .synonyms("bones", "skeleton", "body")
        .requiresTryTake
        .omitDescription
        .in(.maze5)
        // Note: Has action handler SKELETON

    static let burnedOutLantern = Item(.burnedOutLantern)
        .name("burned-out lantern")
        .synonyms("lantern", "lamp")
        .adjectives("rusty", "burned", "dead", "useless")
        .isTakable
        .firstDescription("The deceased adventurer's useless lantern is here.")
        .size(20)
        .in(.maze5)

    static let keys = Item(.keys)
        .name("skeleton key")
        .synonyms("key")
        .adjectives("skeleton")
        .isTakable
        .isTool
        .size(10)
        .in(.maze5)

    static let rustyKnife = Item(.rustyKnife)
        .name("rusty knife")
        .synonyms("knives", "knife")
        .adjectives("rusty")
        .isTakable
        .requiresTryTake
        .isWeapon
        .isTool
        .firstDescription("Beside the skeleton is a rusty knife.")
        .size(20)
        .in(.maze5)
        // Note: Has action handler RUSTY-KNIFE-FCN
}
