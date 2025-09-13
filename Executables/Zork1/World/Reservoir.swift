import GnustoEngine

enum Reservoir {
    static let inStream = Location(
        id: .inStream,
        .name("Stream"),
        .description(
            """
            You are on the gently flowing stream. The upstream route is too narrow
            to navigate, and the downstream route is invisible due to twisting
            walls. There is a narrow beach to land on.
            """
        ),
        .exits(
            // Note: UP and WEST exits have custom messages about narrow channel
            // Note: LAND exit to stream view
            .down(.reservoir),
            .east(.reservoir)
        ),
        // Note: This is NONLANDBIT in ZIL
        .localGlobals(.globalWater)
    )

    static let reservoir = Location(
        id: .reservoir,
        .name("Reservoir"),
        .description(
            """
            This is a large reservoir of water.
            """
        ),
        .exits(
            .north(.reservoirNorth),
            .south(.reservoirSouth),
            .up(.inStream),
            .west(.inStream)
            // Note: DOWN exit has custom message about dam blocking way
        ),
        // Note: This is NONLANDBIT in ZIL
        .localGlobals(.globalWater)
    )

    static let reservoirNorth = Location(
        id: .reservoirNorth,
        .name("Reservoir North"),
        .description(
            """
            You are in the northern end of the reservoir.
            """
        ),
        .exits(
            .north(.atlantisRoom)
            // Note: SOUTH exit to reservoir conditional on LOW-TIDE
        ),
        .localGlobals(.globalWater, .stairs)
    )

    static let reservoirSouth = Location(
        id: .reservoirSouth,
        .name("Reservoir South"),
        .description(
            """
            You are in a large chamber with water flowing from the north.
            """
        ),
        .exits(
            .southeast(.deepCanyon),
            .southwest(.chasmRoom),
            .east(.damRoom),
            .west(.streamView)
            // Note: NORTH exit to reservoir conditional on LOW-TIDE
        ),
        .localGlobals(.globalWater)
    )

    static let streamView = Location(
        id: .streamView,
        .name("Stream View"),
        .description(
            """
            You are standing on a path beside a gently flowing stream. The path
            follows the stream, which flows from west to east.
            """
        ),
        .exits(
            .east(.reservoirSouth)
            // Note: WEST exit has custom message about stream being too small
        ),
        .localGlobals(.globalWater)
    )
}

// MARK: - Items

extension Reservoir {
    static let pump = Item(
        id: .pump,
        .name("hand-held air pump"),
        .synonyms("pump", "air-pump", "tool", "tools"),
        .adjectives("small", "hand-held"),
        .isTakable,
        .isTool,
        .in(.reservoirNorth)
    )

    static let trunk = Item(
        id: .trunk,
        .name("trunk of jewels"),
        .synonyms("trunk", "chest", "jewels", "treasure"),
        .adjectives("old"),
        .isTakable,
        .isInvisible,
        .firstDescription("Lying half buried in the mud is an old trunk, bulging with jewels."),
        .description("There is an old trunk here, bulging with assorted jewels."),
        .size(35),
        .in(.reservoir),
        .value(15)
        // Note: VALUE 15, TVALUE 5, has action handler TRUNK-F
    )
}
