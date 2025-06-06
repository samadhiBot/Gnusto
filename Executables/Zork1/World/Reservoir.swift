import GnustoEngine

enum Reservoir {
    static let inStream = Location(
        id: .inStream,
        .name("Stream"),
        .description("""
            You are on the gently flowing stream. The upstream route is too narrow
            to navigate, and the downstream route is invisible due to twisting
            walls. There is a narrow beach to land on.
            """),
        .exits([
            // Note: UP and WEST exits have custom messages about narrow channel
            // Note: LAND exit to stream view
            .down: .to(.reservoir),
            .east: .to(.reservoir)
        ]),
        // Note: This is NONLANDBIT in ZIL
        .localGlobals(.globalWater)
    )

    static let reservoir = Location(
        id: .reservoir,
        .name("Reservoir"),
        .description("""
            This is a large reservoir of water.
            """),
        .exits([
            .north: .to(.reservoirNorth),
            .south: .to(.reservoirSouth),
            .up: .to(.inStream),
            .west: .to(.inStream),
            // Note: DOWN exit has custom message about dam blocking way
        ]),
        // Note: This is NONLANDBIT in ZIL
        .localGlobals(.globalWater)
    )

    static let reservoirNorth = Location(
        id: .reservoirNorth,
        .name("Reservoir North"),
        .description("""
            You are in the northern end of the reservoir.
            """),
        .exits([
            .north: .to(.atlantisRoom),
            // Note: SOUTH exit to reservoir conditional on LOW-TIDE
        ]),
        .isLand,
        .localGlobals(.globalWater, .stairs)
    )

    static let reservoirSouth = Location(
        id: .reservoirSouth,
        .name("Reservoir South"),
        .description("""
            You are in a large chamber with water flowing from the north.
            """),
        .exits([
            .southeast: .to(.deepCanyon),
            .southwest: .to(.chasmRoom),
            .east: .to(.damRoom),
            .west: .to(.streamView),
            // Note: NORTH exit to reservoir conditional on LOW-TIDE
        ]),
        .isLand,
        .localGlobals(.globalWater)
    )

    static let streamView = Location(
        id: .streamView,
        .name("Stream View"),
        .description("""
            You are standing on a path beside a gently flowing stream. The path
            follows the stream, which flows from west to east.
            """),
        .exits([
            .east: .to(.reservoirSouth),
            // Note: WEST exit has custom message about stream being too small
        ]),
        .isLand,
        .localGlobals(.globalWater)
    )
}
