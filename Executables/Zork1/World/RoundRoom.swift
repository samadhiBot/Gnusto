import GnustoEngine

enum RoundRoom {
    static let chasmRoom = Location(
        id: .chasmRoom,
        .name("Chasm"),
        .description("""
            A chasm runs southwest to northeast and the path follows it. You are
            on the south side of the chasm, where a crack opens into a passage.
            """),
        .exits([
            .northeast: .to(.reservoirSouth),
            .southwest: .to(.ewPassage),
            .up: .to(.ewPassage),
            .south: .to(.nsPassage),
            // Note: DOWN exit has custom message
        ]),
        .isLand,
        .localGlobals(.crack, .stairs)
    )

    static let dampCave = Location(
        id: .dampCave,
        .name("Damp Cave"),
        .description("""
            This cave has exits to the west and east, and narrows to a crack toward
            the south. The earth is particularly damp here.
            """),
        .exits([
            .west: .to(.loudRoom),
            .east: .to(.whiteCliffsNorth),
            // Note: SOUTH exit has custom message about being too narrow
        ]),
        .isLand,
        .localGlobals(.crack)
    )

    static let deepCanyon = Location(
        id: .deepCanyon,
        .name("Deep Canyon"),
        .description("""
            You are on the south side of a deep canyon.
            """),
        .exits([
            .northwest: .to(.reservoirSouth),
            .east: .to(.damRoom),
            .southwest: .to(.nsPassage),
            .down: .to(.loudRoom)
        ]),
        .isLand,
        .localGlobals(.stairs)
    )

    static let ewPassage = Location(
        id: .ewPassage,
        .name("East-West Passage"),
        .description("""
            This is a narrow east-west passageway. There is a narrow stairway
            leading down at the north end of the room.
            """),
        .exits([
            .east: .to(.roundRoom),
            .west: .to(.trollRoom),
            .down: .to(.chasmRoom),
            .north: .to(.chasmRoom)
        ]),
        .isLand,
        .localGlobals(.stairs)
    )

    static let loudRoom = Location(
        id: .loudRoom,
        .name("Loud Room"),
        .description("""
            This is a room where every sound is amplified.
            """),
        .exits([
            .east: .to(.dampCave),
            .west: .to(.roundRoom),
            .up: .to(.deepCanyon)
        ]),
        .isLand,
        .localGlobals(.stairs)
    )

    static let nsPassage = Location(
        id: .nsPassage,
        .name("North-South Passage"),
        .description("""
            This is a high north-south passage, which forks to the northeast.
            """),
        .exits([
            .north: .to(.chasmRoom),
            .northeast: .to(.deepCanyon),
            .south: .to(.roundRoom)
        ]),
        .isLand
    )

    static let roundRoom = Location(
        id: .roundRoom,
        .name("Round Room"),
        .description("""
            This is a circular stone room with passages in all directions. Several
            of them have unfortunately been blocked by cave-ins.
            """),
        .exits([
            .east: .to(.loudRoom),
            .west: .to(.ewPassage),
            .north: .to(.nsPassage),
            .south: .to(.narrowPassage),
            .southeast: .to(.engravingsCave)
        ]),
        .isLand
    )
}
