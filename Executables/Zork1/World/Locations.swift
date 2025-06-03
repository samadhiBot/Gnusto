import GnustoEngine

// MARK: - Zork World

enum ZorkWorld {
    static let westOfHouse = Location(
        id: .westOfHouse,
        .name("West of House"),
        .description("""
            You are standing in an open field west of a white house, with a boarded front door.
            """),
        .exits([
            .north: .to(.northOfHouse),
            .south: .to(.southOfHouse),
            .northeast: .to(.northOfHouse),
            .southeast: .to(.southOfHouse),
            .west: .to(.forest1),
            .east: Exit(
                destination: .blockedExit,
                blockedMessage: "The door is boarded and you can't remove the boards."
            ),
        ]),
        .inherentlyLit
    )

    static let northOfHouse = Location(
        id: .northOfHouse,
        .name("North of House"),
        .description("""
            You are facing the north side of a white house. There is no door here, and all the
            windows are boarded up. To the north a narrow path winds through the trees.
            """),
        .exits([
            .southwest: .to(.westOfHouse),
            .southeast: .to(.eastOfHouse),
            .west: .to(.westOfHouse),
            .east: .to(.eastOfHouse),
            .north: .to(.path),
            .south: Exit(
                destination: .blockedExit,
                blockedMessage: "The windows are all boarded."
            ),
        ]),
        .inherentlyLit
    )

    static let southOfHouse = Location(
        id: .southOfHouse,
        .name("South of House"),
        .description("""
            You are facing the south side of a white house. There is no door here, and all the
            windows are boarded.
            """),
        .exits([
            .west: .to(.westOfHouse),
            .east: .to(.eastOfHouse),
            .northeast: .to(.eastOfHouse),
            .northwest: .to(.westOfHouse),
            .south: .to(.forest3),
            .north: Exit(
                destination: .blockedExit,
                blockedMessage: "The windows are all boarded."
            ),
        ]),
        .inherentlyLit
    )

    static let eastOfHouse = Location(
        id: .eastOfHouse,
        .name("Behind House"),
        .description("""
            You are behind the white house. A path leads into the forest to the east. In one
            corner of the house there is a small window which is slightly ajar.
            """),
        .exits([
            .north: .to(.northOfHouse),
            .south: .to(.southOfHouse),
            .southwest: .to(.southOfHouse),
            .northwest: .to(.northOfHouse),
            .east: .to(.clearing),
        ]),
        .inherentlyLit
    )

    static let forest1 = Location(
        id: .forest1,
        .name("Forest"),
        .description("""
            This is a forest, with trees in all directions. To the east, there appears to be
            sunlight.
            """),
        .exits([
            .north: .to(.gratingClearing),
            .east: .to(.path),
            .south: .to(.forest3),
            .west: Exit(
                destination: .blockedExit,
                blockedMessage: "You would need a machete to go further west."
            ),
            .up: Exit(
                destination: .blockedExit,
                blockedMessage: "There is no tree here suitable for climbing."
            ),
        ]),
        .inherentlyLit
    )

    static let forest2 = Location(
        id: .forest2,
        .name("Forest"),
        .description("This is a dimly lit forest, with large trees all around."),
        .exits([
            .east: .to(.mountains),
            .south: .to(.clearing),
            .west: .to(.path),
            .north: Exit(
                destination: .blockedExit,
                blockedMessage: "The forest becomes impenetrable to the north."
            ),
            .up: Exit(
                destination: .blockedExit,
                blockedMessage: "There is no tree here suitable for climbing."
            ),
        ]),
        .inherentlyLit
    )

    static let forest3 = Location(
        id: .forest3,
        .name("Forest"),
        .description("This is a dimly lit forest, with large trees all around."),
        .exits([
            .north: .to(.clearing),
            .west: .to(.forest1),
            .northwest: .to(.southOfHouse),
            .east: Exit(
                destination: .blockedExit,
                blockedMessage: "The rank undergrowth prevents eastward movement."
            ),
            .south: Exit(
                destination: .blockedExit,
                blockedMessage: "Storm-tossed trees block your way."
            ),
            .up: Exit(
                destination: .blockedExit,
                blockedMessage: "There is no tree here suitable for climbing."
            ),
        ]),
        .inherentlyLit
    )

    static let path = Location(
        id: .path,
        .name("Forest Path"),
        .description("""
            This is a path winding through a dimly lit forest. The path heads north-south here.
            One particularly large tree with some low branches stands at the edge of the path.
            """),
        .exits([
            .north: .to(.gratingClearing),
            .east: .to(.forest2),
            .south: .to(.northOfHouse),
            .west: .to(.forest1),
            .up: .to(.upATree),
        ]),
        .inherentlyLit
    )

    static let clearing = Location(
        id: .clearing,
        .name("Clearing"),
        .description("""
            You are in a clearing in the forest. The forest surrounds you on all sides. There
            appears to be a grating in the ground.
            """),
        .exits([
            .north: .to(.forest2),
            .east: .to(.forest3),
            .south: .to(.forest3),
            .west: .to(.eastOfHouse),
        ]),
        .inherentlyLit
    )

    static let gratingClearing = Location(
        id: .gratingClearing,
        .name("Clearing"),
        .description("""
            You are in a clearing, with a forest surrounding you on all sides. A path leads
            south.
            """),
        .exits([
            .east: .to(.forest2),
            .west: .to(.forest1),
            .south: .to(.path),
            .north: Exit(
                destination: .blockedExit,
                blockedMessage: "The forest becomes impenetrable to the north."
            ),
        ]),
        .inherentlyLit
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
            .up: Exit(
                destination: .blockedExit,
                blockedMessage: "You cannot climb any higher."
            ),
        ]),
        .inherentlyLit
    )

    static let stoneBarrow = Location(
        id: .stoneBarrow,
        .name("Stone Barrow"),
        .description("""
            You are standing in front of a massive barrow of stone. In the east face is a huge
            stone door which is open. You cannot see into the dark of the tomb.
            """),
        .exits([
            .northeast: .to(.westOfHouse),
        ]),
        .inherentlyLit
    )

    static let mountains = Location(
        id: .mountains,
        .name("Forest"),
        .description("The forest thins out, revealing impassable mountains."),
        .exits([
            .north: .to(.forest2),
            .south: .to(.forest2),
            .west: .to(.forest2),
            .east: Exit(
                destination: .blockedExit,
                blockedMessage: "The mountains are impassable."
            ),
            .up: Exit(
                destination: .blockedExit,
                blockedMessage: "The mountains are impassable."
            ),
        ]),
        .inherentlyLit
    )

    // Virtual blocked destination location
    static let blockedExit = Location(
        id: .blockedExit,
        .name("Blocked"),
        .description("This location should never be reached.")
    )
}
