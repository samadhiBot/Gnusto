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
        ]),
        .isLand,
        .isSacred
    )

    static let deadEnd5 = Location(
        id: .deadEnd5,
        .name("Dead End"),
        .description("""
            You have come to a dead end in the mine.
            """),
        .exits([
            .north: .to(.ladderBottom)
        ]),
        .isLand
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
        .isLand,
        .isSacred,
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
        .isLand,
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
        .isLand,
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
        ]),
        .isLand,
        .isSacred
    )

    static let machineRoom = Location(
        id: .machineRoom,
        .name("Machine Room"),
        .description("""
            This room contains a large machine.
            """),
        .exits([
            .north: .to(.lowerShaft)
        ]),
        .isLand
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
        ]),
        .isLand
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
        ]),
        .isLand
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
        ]),
        .isLand
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
        ]),
        .isLand
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
        ]),
        .isLand
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
        ]),
        .isLand
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
        .isLand,
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
        .isLand,
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
        ]),
        .isLand
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
        ]),
        .isLand,
        .isSacred
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

    static let diamond = Item(
        id: .diamond,
        .name("huge diamond"),
        .synonyms("diamond", "treasure"),
        .adjectives("huge", "enormous"),
        .isTakable,
        .description("There is an enormous diamond (perfectly cut) here.")
        // Note: VALUE 10, TVALUE 10, parent location not specified in ZIL
    )

    static let machine = Item(
        id: .machine,
        .name("machine"),
        .synonyms("machine", "pdp10", "dryer", "lid"),
        .isContainer,
        .suppressDescription,
        .requiresTryTake,
        .capacity(50),
        .in(.location(.machineRoom))
        // Note: Has action handler MACHINE-F
    )
}
