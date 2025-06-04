import GnustoEngine

// MARK: - Underground Area

enum Underground {
    // MARK: - Locations

    static let cellar = Location(
        id: .cellar,
        .name("Cellar"),
        .description("""
            You are in a dark and damp cellar with a narrow passageway leading north, and a \
            crawlway to the south. On the west is the bottom of a steep metal ramp which is \
            unclimbable.
            """),
        .exits([
            .north: .to(.troll),
            .south: .to(.eastOfChasm),
            .west: .to(.steepRamp),
            .up: Exit(
                destination: .livingRoom,
                blockedMessage: "The trap door is locked from above.",
                doorID: .trapDoor
            ),
        ])
    )

    static let steepRamp = Location(
        id: .steepRamp,
        .name("Bottom of Ramp"),
        .description("""
            You are at the bottom of a steep metal ramp. The ramp leads up to the west, but it \
            is too steep and smooth to climb.
            """),
        .exits([
            .east: .to(.cellar),
        ])
    )

    static let troll = Location(
        id: .troll,
        .name("Troll Room"),
        .description("""
            This is a small room with passages to the east and south and a forbidding hole \
            leading west. Bloodstains and deep scratches (perhaps made by an axe) mar the \
            walls.
            """),
        .exits([
            .east: .to(.eastWestPassage),
            .south: .to(.cellar),
            .west: .to(.maze1),
        ])
    )

    static let eastWestPassage = Location(
        id: .eastWestPassage,
        .name("East-West Passage"),
        .description("""
            This is a narrow east-west passageway. There is a narrow stairway leading down at \
            the north end of the room.
            """),
        .exits([
            .east: .to(.roundRoom),
            .west: .to(.troll),
            .down: .to(.reservoir),
        ])
    )

    static let roundRoom = Location(
        id: .roundRoom,
        .name("Round Room"),
        .description("""
            This is a circular stone room with passages in all directions. Several of them \
            have unfortunate endings.
            """),
        .exits([
            .north: .to(.northSouthPassage),
            .northeast: .to(.northeastPassage),
            .east: .to(.deadEnd),
            .southeast: .to(.complexJunction),
            .south: .to(.southPassage),
            .southwest: .to(.southwestPassage),
            .west: .to(.eastWestPassage),
            .northwest: .to(.northwestPassage),
        ])
    )

    static let eastOfChasm = Location(
        id: .eastOfChasm,
        .name("East of Chasm"),
        .description("""
            You are on the east edge of a chasm, the bottom of which cannot be seen. A narrow \
            passage goes north, and the path you are on continues to the east.
            """),
        .exits([
            .north: .to(.cellar),
            .east: .to(.gallery),
        ])
    )

    static let gallery = Location(
        id: .gallery,
        .name("Gallery"),
        .description("""
            This is an art gallery. Most of the paintings have been stolen by vandals with \
            exceptional taste. The vandals left through either the north or west exits.
            """),
        .exits([
            .north: .to(.studio),
            .west: .to(.eastOfChasm),
        ])
    )

    static let studio = Location(
        id: .studio,
        .name("Studio"),
        .description("""
            This appears to have been an artist's studio. The walls and floors are splattered \
            with paints of 69 different colors. Strangely enough, nothing of value is hanging \
            here. At the south end of the room is an open door (also covered with paint). A \
            dark and narrow chimney leads up from a fireplace; although you might be able to \
            get up it, it seems unlikely you could get back down.
            """),
        .exits([
            .south: .to(.gallery),
            .up: Exit(
                destination: .kitchen,
                blockedMessage: "You try to climb the chimney, but it's too narrow and steep."
            ),
        ])
    )

    // Additional placeholder locations for future expansion
    static let reservoir = Location(
        id: .reservoir,
        .name("Reservoir"),
        .description("This is a large underground reservoir."),
        .exits([
            .up: .to(.eastWestPassage),
        ])
    )

    static let maze1 = Location(
        id: .maze1,
        .name("Maze"),
        .description("This is part of a maze of twisty little passages, all alike."),
        .exits([
            .east: .to(.troll),
        ])
    )

    static let deadEnd = Location(
        id: .deadEnd,
        .name("Dead End"),
        .description("You have come to a dead end."),
        .exits([
            .west: .to(.roundRoom),
        ])
    )

    static let northSouthPassage = Location(
        id: .northSouthPassage,
        .name("North-South Passage"),
        .description("This is a long north-south passage."),
        .exits([
            .south: .to(.roundRoom),
        ])
    )

    static let northeastPassage = Location(
        id: .northeastPassage,
        .name("Northeast Passage"),
        .description("This is a northeast passage."),
        .exits([
            .southwest: .to(.roundRoom),
        ])
    )

    static let complexJunction = Location(
        id: .complexJunction,
        .name("Complex Junction"),
        .description("This is a complex junction with passages leading in many directions."),
        .exits([
            .northwest: .to(.roundRoom),
        ])
    )

    static let southPassage = Location(
        id: .southPassage,
        .name("South Passage"),
        .description("This is a south passage."),
        .exits([
            .north: .to(.roundRoom),
        ])
    )

    static let southwestPassage = Location(
        id: .southwestPassage,
        .name("Southwest Passage"),
        .description("This is a southwest passage."),
        .exits([
            .northeast: .to(.roundRoom),
        ])
    )

    static let northwestPassage = Location(
        id: .northwestPassage,
        .name("Northwest Passage"),
        .description("This is a northwest passage."),
        .exits([
            .southeast: .to(.roundRoom),
        ])
    )

    // MARK: - Items

    static let steepRampItem = Item(
        id: .steepRampItem,
        .name("steep metal ramp"),
        .description("The ramp is too steep and smooth to climb."),
        .adjectives("steep", "metal"),
        .synonyms("ramp"),
        .in(.location(.cellar)),
        .isScenery,
        .isClimbable
    )
}
