import GnustoEngine

struct Reservoir {
    let inStream = Location(.inStream)
        .name("Stream")
        .description(
            """
            You are on the gently flowing stream. The upstream route is too narrow
            to navigate, and the downstream route is invisible due to twisting
            walls. There is a narrow beach to land on.
            """
        )
        // Note: UP and WEST exits have custom messages about narrow channel
        // Note: LAND exit to stream view
        .down(.reservoir)
        .east(.reservoir)
        // Note: This is NONLANDBIT in ZIL
        .localGlobals(.globalWater)

    let reservoir = Location(.reservoir)
        .name("Reservoir")
        .description(
            """
            This is a large reservoir of water.
            """
        )
        .north(.reservoirNorth)
        .south(.reservoirSouth)
        .up(.inStream)
        .west(.inStream)
        // Note: DOWN exit has custom message about dam blocking way
        // Note: This is NONLANDBIT in ZIL
        .localGlobals(.globalWater)

    let reservoirNorth = Location(.reservoirNorth)
        .name("Reservoir North")
        .description(
            """
            You are in the northern end of the reservoir.
            """
        )
        .north(.atlantisRoom)
        // Note: SOUTH exit to reservoir conditional on LOW-TIDE
        .localGlobals(.globalWater, .stairs)

    let reservoirSouth = Location(.reservoirSouth)
        .name("Reservoir South")
        .description(
            """
            You are in a large chamber with water flowing from the north.
            """
        )
        .southeast(.deepCanyon)
        .southwest(.chasmRoom)
        .east(.damRoom)
        .west(.streamView)
        // Note: NORTH exit to reservoir conditional on LOW-TIDE
        .localGlobals(.globalWater)

    let streamView = Location(.streamView)
        .name("Stream View")
        .description(
            """
            You are standing on a path beside a gently flowing stream. The path
            follows the stream, which flows from west to east.
            """
        )
        .east(.reservoirSouth)
        // Note: WEST exit has custom message about stream being too small
        .localGlobals(.globalWater)

    // MARK: - Items

    let globalWater = Item(
        id: .globalWater
    )

    let pump = Item(.pump)
        .name("hand-held air pump")
        .synonyms("pump", "air-pump", "tool", "tools")
        .adjectives("small", "hand-held")
        .isTakable
        .isTool
        .in(.reservoirNorth)

    let trunk = Item(.trunk)
        .name("trunk of jewels")
        .synonyms("trunk", "chest", "jewels", "treasure")
        .adjectives("old")
        .isTakable
        .isInvisible
        .firstDescription("Lying half buried in the mud is an old trunk, bulging with jewels.")
        .description("There is an old trunk here, bulging with assorted jewels.")
        .size(35)
        .in(.reservoir)
        .value(15)
        // Note: VALUE 15, TVALUE 5, has action handler TRUNK-F
}
