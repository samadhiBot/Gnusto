import GnustoEngine

enum BeneathHouse {
    static let cellar = Location(
        id: .cellar,
        .name("Cellar"),
        .description("""
            You are in a dark and damp cellar with a narrow passageway leading north and a crawlway to the south. On the west is the bottom of a narrow ramp which is too steep to climb.
            """),
        .exits([
            .north: .to(.trollRoom),
            .south: .to(.eastOfChasm),
            // Note: UP exit to living room conditional on trap door being open
            // Note: WEST exit has custom message about sliding back down
        ]),
        .isLand,
        .localGlobals(.trapDoor, .slide, .stairs)
    )

    static let eastOfChasm = Location(
        id: .eastOfChasm,
        .name("East of Chasm"),
        .description("""
            You are on the east edge of a chasm, the bottom of which cannot be
            seen. A narrow passage goes north, and the path you are on continues
            to the east.
            """),
        .exits([
            .north: .to(.cellar),
            .east: .to(.gallery),
            // Note: DOWN exit has custom message about chasm leading to infernal regions
        ]),
        .isLand
    )

    static let gallery = Location(
        id: .gallery,
        .name("Gallery"),
        .description("""
            This is an art gallery. Most of the paintings have been stolen by
            vandals with exceptional taste. The vandals left through either the
            north or west exits.
            """),
        .exits([
            .west: .to(.eastOfChasm),
            .north: .to(.studio)
        ]),
        .isLand,
        .inherentlyLit
    )

    static let studio = Location(
        id: .studio,
        .name("Studio"),
        .description("""
            This appears to have been an artist's studio. The walls and floors are
            splattered with paints of 69 different colors. Strangely enough, nothing
            of value is hanging here. At the south end of the room is an open door
            (also covered with paint). A dark and narrow chimney leads up from a
            fireplace; although you might be able to get up it, it seems unlikely
            you could get back down.
            """),
        .exits([
            .south: .to(.gallery),
            // Note: UP exit has special condition handling via UP-CHIMNEY-FUNCTION
        ]),
        .isLand,
        .localGlobals(.chimney)
    )

    static let trollRoom = Location(
        id: .trollRoom,
        .name("The Troll Room"),
        .description("""
            This is a small room with passages to the east and south and a
            forbidding hole leading west. Bloodstains and deep scratches
            (perhaps made by an axe) mar the walls.
            """),
        .exits([
            .south: .to(.cellar),
            // Note: EAST exit to EW-PASSAGE conditional on TROLL-FLAG
            // Note: WEST exit to MAZE-1 conditional on TROLL-FLAG
        ]),
        .isLand
    )
}

// MARK: - Items

extension BeneathHouse {
    static let axe = Item(
        id: .axe,
        .name("bloody axe"),
        .synonyms("axe", "ax"),
        .adjectives("bloody"),
        .isWeapon,
        .requiresTryTake,
        .isTakable,
        .suppressDescription,
        .size(25),
        .in(.item(.troll))
        // Note: Has action handler AXE-F
    )

    static let ownersManual = Item(
        id: .ownersManual,
        .name("ZORK owner's manual"),
        .synonyms("manual", "piece", "paper"),
        .adjectives("zork", "owners", "small"),
        .isReadable,
        .isTakable,
        .firstDescription("Loosely attached to a wall is a small piece of paper."),
        .readText("""
            Congratulations!

            You are the privileged owner of ZORK I: The Great Underground Empire,
            a self-contained and self-maintaining universe. If used and maintained
            in accordance with normal operating practices for small universes, ZORK
            will provide many months of trouble-free operation.
            """),
        .in(.location(.studio))
    )

    static let painting = Item(
        id: .painting,
        .name("painting"),
        .synonyms("painting", "art", "canvas", "treasure"),
        .adjectives("beautiful"),
        .isTakable,
        .isFlammable,
        .firstDescription("""
            Fortunately, there is still one chance for you to be a vandal, for on
            the far wall is a painting of unparalleled beauty.
            """),
        .description("A painting by a neglected genius is here."),
        .size(15),
        .in(.location(.gallery))
        // Note: VALUE 4, TVALUE 6, has action handler PAINTING-FCN
    )

    static let troll = Item(
        id: .troll,
        .name("troll"),
        .synonyms("troll"),
        .adjectives("nasty"),
        .isCharacter,  // ACTORBIT
        .isOpen,  // OPENBIT
        .requiresTryTake,
        .description("""
            A nasty-looking troll, brandishing a bloody axe, blocks all passages
            out of the room.
            """),
        .in(.location(.trollRoom))
        // Note: Has action handler TROLL-FCN, STRENGTH 2
    )
}
