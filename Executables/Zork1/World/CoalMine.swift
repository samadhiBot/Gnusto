import GnustoEngine

enum CoalMine {
    static let batRoom = Location(
        id: .batRoom,
        .name("Bat Room"),
        .description("""
            You are in a room infested with bats. Strange squeaky sounds fill the air.
            """),
        .exits([
            .south: .to(.squeakyRoom),
            .east: .to(.shaftRoom)
        ])
    )

    static let deadEnd5 = Location(
        id: .deadEnd5,
        .name("Dead End"),
        .description("""
            You have come to a dead end in the mine.
            """),
        .exits([
            .north: .to(.ladderBottom)
        ])
    )

    static let gasRoom = Location(
        id: .gasRoom,
        .name("Gas Room"),
        .description("""
            This is a small room which smells strongly of coal gas. There is a
            short climb up some stairs and a narrow tunnel leading east.
            """),
        .exits([
            .up: .to(.smellyRoom),
            .east: .to(.mine1)
        ]),
        .localGlobals(.stairs)
    )

    static let ladderBottom = Location(
        id: .ladderBottom,
        .name("Ladder Bottom"),
        .description("""
            This is a rather wide room. On one side is the bottom of a
            narrow wooden ladder. To the west and the south are passages
            leaving the room.
            """),
        .exits([
            .south: .to(.deadEnd5),
            .west: .to(.timberRoom),
            .up: .to(.ladderTop)
        ]),
        .localGlobals(.ladder)
    )

    static let ladderTop = Location(
        id: .ladderTop,
        .name("Ladder Top"),
        .description("""
            This is a very small room. In the corner is a rickety wooden
            ladder, leading downward. It might be safe to descend. There is
            also a staircase leading upward.
            """),
        .exits([
            .down: .to(.ladderBottom),
            .up: .to(.mine4)
        ]),
        .localGlobals(.ladder, .stairs)
    )

    static let lowerShaft = Location(
        id: .lowerShaft,
        .name("Drafty Room"),
        .description("""
            This is a small drafty room in which is the bottom of a long
            shaft. To the south is a passageway and to the east a very narrow
            passage. In the shaft can be seen a heavy iron chain.
            """),
        .exits([
            .south: .to(.machineRoom),
            // Note: OUT and EAST exits to timber room conditional on EMPTY-HANDED
        ])
    )

    static let machineRoom = Location(
        id: .machineRoom,
        .name("Machine Room"),
        .description("""
            This room contains a large machine.
            """),
        .exits([
            .north: .to(.lowerShaft)
        ])
    )

    static let mineEntrance = Location(
        id: .mineEntrance,
        .name("Mine Entrance"),
        .description("""
            You are standing at the entrance of what might have been a coal mine.
            The shaft enters the west wall, and there is another exit on the south
            end of the room.
            """),
        .exits([
            .south: .to(.slideRoom),
            .inside: .to(.squeakyRoom),
            .west: .to(.squeakyRoom)
        ])
    )

    static let mine1 = Location(
        id: .mine1,
        .name("Coal Mine"),
        .description("""
            This is a nondescript part of a coal mine.
            """),
        .exits([
            .north: .to(.gasRoom),
            .east: .to(.mine1),
            .northeast: .to(.mine2)
        ])
    )

    static let mine2 = Location(
        id: .mine2,
        .name("Coal Mine"),
        .description("""
            This is a nondescript part of a coal mine.
            """),
        .exits([
            .north: .to(.mine2),
            .south: .to(.mine1),
            .southeast: .to(.mine3)
        ])
    )

    static let mine3 = Location(
        id: .mine3,
        .name("Coal Mine"),
        .description("""
            This is a nondescript part of a coal mine.
            """),
        .exits([
            .south: .to(.mine3),
            .southwest: .to(.mine4),
            .east: .to(.mine2)
        ])
    )

    static let mine4 = Location(
        id: .mine4,
        .name("Coal Mine"),
        .description("""
            This is a nondescript part of a coal mine.
            """),
        .exits([
            .north: .to(.mine3),
            .west: .to(.mine4),
            .down: .to(.ladderTop)
        ])
    )

    static let shaftRoom = Location(
        id: .shaftRoom,
        .name("Shaft Room"),
        .description("""
            This is a large room, in the middle of which is a small shaft
            descending through the floor into darkness below. To the west and
            the north are exits from this room. Constructed over the top of the
            shaft is a metal framework to which a heavy iron chain is attached.
            """),
        .exits([
            // Note: DOWN exit has custom message
            .west: .to(.batRoom),
            .north: .to(.smellyRoom)
        ])
    )

    static let slideRoom = Location(
        id: .slideRoom,
        .name("Slide Room"),
        .description("""
            This is a small chamber, which appears to have been part of a
            coal mine. On the south wall of the chamber the letters "Granite
            Wall" are etched in the rock. To the east is a long passage, and
            there is a steep metal slide twisting downward. To the north is
            a small opening.
            """),
        .exits([
            .east: .to(.coldPassage),
            .north: .to(.mineEntrance),
            .down: .to(.cellar)
        ]),
        .localGlobals(.slide)
    )

    static let smellyRoom = Location(
        id: .smellyRoom,
        .name("Smelly Room"),
        .description("""
            This is a small nondescript room. However, from the direction
            of a small descending staircase a foul odor can be detected. To the
            south is a narrow tunnel.
            """),
        .exits([
            .down: .to(.gasRoom),
            .south: .to(.shaftRoom)
        ]),
        .localGlobals(.stairs)
    )

    static let squeakyRoom = Location(
        id: .squeakyRoom,
        .name("Squeaky Room"),
        .description("""
            You are in a small room. Strange squeaky sounds may be heard coming
            from the passage at the north end. You may also escape to the east.
            """),
        .exits([
            .north: .to(.batRoom),
            .east: .to(.mineEntrance)
        ])
    )

    static let timberRoom = Location(
        id: .timberRoom,
        .name("Timber Room"),
        .description("""
            This is a long and narrow passage, which is cluttered with broken
            timbers. A wide passage comes from the east and turns at the
            west end of the room into a very narrow passageway. From the west
            comes a strong draft.
            """),
        .exits([
            .east: .to(.ladderBottom),
            // Note: WEST exit to lower shaft conditional on EMPTY-HANDED
        ])
    )
}

// MARK: - Items

extension CoalMine {
    static let bat = Item(
        id: .bat,
        .name("bat"),
        .synonyms("bat", "vampire"),
        .adjectives("vampire", "deranged"),
        .isCharacter,  // ACTORBIT
        .requiresTryTake,
        .in(.location(.batRoom))
        // Note: Has action handler BAT-F, DESCFCN BAT-D
    )

    static let bracelet = Item(
        id: .bracelet,
        .name("sapphire-encrusted bracelet"),
        .synonyms("bracelet", "jewel", "sapphire", "treasure"),
        .adjectives("sapphire"),
        .isTakable,
        .size(10),
        .in(.location(.gasRoom))
        // Note: VALUE 5, TVALUE 5
    )

    static let coal = Item(
        id: .coal,
        .name("small pile of coal"),
        .synonyms("coal", "pile", "heap"),
        .adjectives("small"),
        .isTakable,
        .isFlammable,
        .size(20),
        .in(.location(.deadEnd5))
    )

    static let diamond = Item(
        id: .diamond,
        .name("huge diamond"),
        .synonyms("diamond", "treasure"),
        .adjectives("huge", "enormous"),
        .isTakable,
        .description("There is an enormous diamond (perfectly cut) here.")
        // Note: VALUE 10, TVALUE 10, parent location not specified in ZIL
    )

    static let jade = Item(
        id: .jade,
        .name("jade figurine"),
        .synonyms("figurine", "treasure"),
        .adjectives("exquisite", "jade"),
        .isTakable,
        .description("There is an exquisite jade figurine here."),
        .size(10),
        .in(.location(.batRoom))
        // Note: VALUE 5, TVALUE 5
    )

    static let loweredBasket = Item(
        id: .loweredBasket,
        .name("basket"),
        .synonyms("cage", "dumbwaiter", "basket"),
        .adjectives("lowered"),
        .requiresTryTake,
        .description("From the chain is suspended a basket."),
        .in(.location(.lowerShaft))
        // Note: Has action handler BASKET-F
    )

    static let machine = Item(
        id: .machine,
        .name("machine"),
        .synonyms("machine", "pdp10", "dryer", "lid"),
        .isContainer,
        .omitDescription,
        .requiresTryTake,
        .capacity(50),
        .in(.location(.machineRoom))
        // Note: Has action handler MACHINE-F
    )

    static let machineSwitch = Item(
        id: .machineSwitch,
        .name("switch"),
        .synonyms("switch"),
        .omitDescription,
        .in(.location(.machineRoom))
        // Note: Has action handler MSWITCH-FUNCTION, TURNBIT
    )

    static let raisedBasket = Item(
        id: .raisedBasket,
        .name("basket"),
        .synonyms("cage", "dumbwaiter", "basket"),
        .isTransparent,
        .requiresTryTake,
        .isContainer,
        .isOpen,
        .description("At the end of the chain is a basket."),
        .capacity(50),
        .in(.location(.shaftRoom))
        // Note: Has action handler BASKET-F
    )

    static let timbers = Item(
        id: .timbers,
        .name("broken timber"),
        .synonyms("timbers", "pile"),
        .adjectives("wooden", "broken"),
        .isTakable,
        .size(50),
        .in(.location(.timberRoom))
    )
}
