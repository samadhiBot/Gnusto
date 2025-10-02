import GnustoEngine

struct CoalMine {
    // MARK: Locations

    let batRoom = Location(.batRoom)
        .name("Bat Room")
        .description(
            """
            You are in a room infested with bats. Strange squeaky sounds fill the air.
            """
        )
        .south(.squeakyRoom)
        .east(.shaftRoom)

    let deadEnd5 = Location(.deadEnd5)
        .name("Dead End")
        .description(
            """
            You have come to a dead end in the mine.
            """
        )
        .north(.ladderBottom)

    let gasRoom = Location(.gasRoom)
        .name("Gas Room")
        .description(
            """
            This is a small room which smells strongly of coal gas. There is a
            short climb up some stairs and a narrow tunnel leading east.
            """
        )
        .up(.smellyRoom)
        .east(.mine1)
        .localGlobals(.stairs)

    let ladderBottom = Location(.ladderBottom)
        .name("Ladder Bottom")
        .description(
            """
            This is a rather wide room. On one side is the bottom of a
            narrow wooden ladder. To the west and the south are passages
            leaving the room.
            """
        )
        .south(.deadEnd5)
        .west(.timberRoom)
        .up(.ladderTop)
        .localGlobals(.ladder)

    let ladderTop = Location(.ladderTop)
        .name("Ladder Top")
        .description(
            """
            This is a very small room. In the corner is a rickety wooden
            ladder, leading downward. It might be safe to descend. There is
            also a staircase leading upward.
            """
        )
        .down(.ladderBottom)
        .up(.mine4)
        .localGlobals(.ladder, .stairs)

    let lowerShaft = Location(.lowerShaft)
        .name("Drafty Room")
        .description(
            """
            This is a small drafty room in which is the bottom of a long
            shaft. To the south is a passageway and to the east a very narrow
            passage. In the shaft can be seen a heavy iron chain.
            """
        )
        .south(.machineRoom)
       // Note: OUT and EAST exits to timber room conditional on EMPTY-HANDED

    let machineRoom = Location(.machineRoom)
        .name("Machine Room")
        .description(
            """
            This room contains a large machine.
            """
        )
        .north(.lowerShaft)

    let mineEntrance = Location(.mineEntrance)
        .name("Mine Entrance")
        .description(
            """
            You are standing at the entrance of what might have been a coal mine.
            The shaft enters the west wall, and there is another exit on the south
            end of the room.
            """
        )
        .south(.slideRoom)
        .inside(.squeakyRoom)
        .west(.squeakyRoom)

    let mine1 = Location(.mine1)
        .name("Coal Mine")
        .description("This is a nondescript part of a coal mine.")
        .north(.gasRoom)
        .east(.mine1)
        .northeast(.mine2)

    let mine2 = Location(.mine2)
        .name("Coal Mine")
        .description("This is a nondescript part of a coal mine.")
        .north(.mine2)
        .south(.mine1)
        .southeast(.mine3)

    let mine3 = Location(.mine3)
        .name("Coal Mine")
        .description("This is a nondescript part of a coal mine.")
        .south(.mine3)
        .southwest(.mine4)
        .east(.mine2)

    let mine4 = Location(.mine4)
        .name("Coal Mine")
        .description("This is a nondescript part of a coal mine.")
        .north(.mine3)
        .west(.mine4)
        .down(.ladderTop)

    let shaftRoom = Location(.shaftRoom)
        .name("Shaft Room")
        .description(
            """
            This is a large room, in the middle of which is a small shaft
            descending through the floor into darkness below. To the west and
            the north are exits from this room. Constructed over the top of the
            shaft is a metal framework to which a heavy iron chain is attached.
            """
        )
        .west(.batRoom)
        .north(.smellyRoom)
        // Note: DOWN exit has custom message

    let slideRoom = Location(.slideRoom)
        .name("Slide Room")
        .description(
            """
            This is a small chamber, which appears to have been part of a
            coal mine. On the south wall of the chamber the letters "Granite
            Wall" are etched in the rock. To the east is a long passage, and
            there is a steep metal slide twisting downward. To the north is
            a small opening.
            """
        )
        .east(.coldPassage)
        .north(.mineEntrance)
        .down(.cellar)
        .localGlobals(.slide)

    let smellyRoom = Location(.smellyRoom)
        .name("Smelly Room")
        .description(
            """
            This is a small nondescript room. However, from the direction
            of a small descending staircase a foul odor can be detected. To the
            south is a narrow tunnel.
            """
        )
        .down(.gasRoom)
        .south(.shaftRoom)
        .localGlobals(.stairs)

    let squeakyRoom = Location(.squeakyRoom)
        .name("Squeaky Room")
        .description(
            """
            You are in a small room. Strange squeaky sounds may be heard coming
            from the passage at the north end. You may also escape to the east.
            """
        )
        .north(.batRoom)
        .east(.mineEntrance)

    let timberRoom = Location(.timberRoom)
        .name("Timber Room")
        .description(
            """
            This is a long and narrow passage, which is cluttered with broken
            timbers. A wide passage comes from the east and turns at the
            west end of the room into a very narrow passageway. From the west
            comes a strong draft.
            """
        )
        .east(.ladderBottom)
        // Note: WEST exit to lower shaft conditional on EMPTY-HANDED

    // MARK: Items

    let bat = Item(.bat)
        .name("bat")
        .synonyms("bat", "vampire")
        .adjectives("vampire", "deranged")
        .requiresTryTake
        .in(.batRoom)
        // Note: Has action handler BAT-F, DESCFCN BAT-D

    let bracelet = Item(.bracelet)
        .name("sapphire-encrusted bracelet")
        .synonyms("bracelet", "jewel", "sapphire", "treasure")
        .adjectives("sapphire")
        .isTakable
        .size(10)
        .in(.gasRoom)
        .value(5)
        // Note: VALUE 5, TVALUE 5

    let coal = Item(.coal)
        .name("small pile of coal")
        .synonyms("coal", "pile", "heap")
        .adjectives("small")
        .isTakable
        .isFlammable
        .size(20)
        .in(.deadEnd5)

    let diamond = Item(.diamond)
        .name("huge diamond")
        .synonyms("diamond", "treasure")
        .adjectives("huge", "enormous")
        .isTakable
        .description("There is an enormous diamond (perfectly cut) here.")
        .value(10)
        // Note: VALUE 10, TVALUE 10, parent location not specified in ZIL

    let jade = Item(.jade)
        .name("jade figurine")
        .synonyms("figurine", "treasure")
        .adjectives("exquisite", "jade")
        .isTakable
        .description("There is an exquisite jade figurine here.")
        .size(10)
        .in(.batRoom)
        .value(5)
        // Note: VALUE 5, TVALUE 5

    let ladder = Item(.ladder)
        .name("wooden ladder")
        .adjectives("wooden", "rickety", "narrow")
        .isClimbable
        .omitDescription

    let loweredBasket = Item(.loweredBasket)
        .name("basket")
        .synonyms("cage", "dumbwaiter", "basket")
        .adjectives("lowered")
        .requiresTryTake
        .description("From the chain is suspended a basket.")
        .in(.lowerShaft)
        // Note: Has action handler BASKET-F

    let machine = Item(.machine)
        .name("machine")
        .synonyms("machine", "pdp10", "dryer", "lid")
        .isContainer
        .omitDescription
        .requiresTryTake
        .capacity(50)
        .in(.machineRoom)
        // Note: Has action handler MACHINE-F

    let machineSwitch = Item(.machineSwitch)
        .name("switch")
        .synonyms("switch")
        .omitDescription
        .in(.machineRoom)
        // Note: Has action handler MSWITCH-FUNCTION, TURNBIT

    let raisedBasket = Item(.raisedBasket)
        .name("basket")
        .synonyms("cage", "dumbwaiter", "basket")
        .isTransparent
        .requiresTryTake
        .isContainer
        .isOpen
        .description("At the end of the chain is a basket.")
        .capacity(50)
        .in(.shaftRoom)
        // Note: Has action handler BASKET-F

    let slide = Item(.slide)
        .name("slide")
        .synonyms("chute", "ramp", "slide")
        .adjectives("steep", "metal", "twisting")
        .isClimbable
        // (ACTION SLIDE-FUNCTION)

    let timbers = Item(.timbers)
        .name("broken timber")
        .synonyms("timbers", "pile")
        .adjectives("wooden", "broken")
        .isTakable
        .size(50)
        .in(.timberRoom)
}
