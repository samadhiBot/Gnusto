import CustomDump
import GnustoEngine
import GnustoTestSupport
import Testing

@testable import Zork1

struct OutsideHouseTests {
    @Test("Interacting with the mailbox")
    func testMailbox() async throws {
        let (engine, mockIO) = await GameEngine.zork1(
            """
            take the mailbox
            open the mailbox
            read the leaflet
            east
            open door
            take boards
            look at the house
            """
        )
        await engine.run()

        await mockIO.expectOutput(
            """
            Zork I: The Great Underground Empire

            ZORK I: The Great Underground Empire Copyright (c) 1981, 1982,
            1983 Infocom, Inc. All rights reserved. ZORK is a registered
            trademark of Infocom, Inc. Revision 88 / Serial number 840726

            --- West of House ---

            You are standing in an open field west of a white house, with a
            boarded front door.

            There is a small mailbox here.

            > take the mailbox
            It is securely anchored.

            > open the mailbox
            Opening the small mailbox brings a leaflet into the light.

            > read the leaflet
            (Taken)

            "WELCOME TO ZORK!

            ZORK is a game of adventure, danger, and low cunning. In it you
            will explore some of the most amazing territory ever seen by
            mortals. No computer should be without one!"

            > east
            The door is boarded and you can't remove the boards.

            > open door
            The universe denies your request to open the door.

            > take boards
            You cannot take the board, much as you might wish otherwise.

            > look at the house
            The white house stubbornly remains ordinary despite your
            thorough examination.

            >
            May your adventures elsewhere prove fruitful!
            """
        )
    }

    @Test("Basic house entry via kitchen window")
    func testHouseEntry() async throws {
        let (engine, mockIO) = await GameEngine.zork1(
            pre: .enterKitchen,
            """
            examine table
            open sack
            inventory
            take all
            inventory
            """
        )
        await engine.run()

        await mockIO.expectOutput(
            """
            > examine table
            A bottle is sitting on the table. The glass bottle contains a
            quantity of water. On the table is an elongated brown sack,
            smelling of hot peppers.

            > open sack
            Opening the brown sack brings a clove of garlic and a lunch
            into the light.

            > inventory
            You carry nothing but your own thoughts.

            > take all
            You take the glass bottle and the brown sack.

            > inventory
            You are carrying:
            - A glass bottle
            - A brown sack

            >
            May your adventures elsewhere prove fruitful!
            """
        )
    }

    @Test("Interacting with the boards on the house")
    func testBoards() async throws {
        let (engine, mockIO) = await GameEngine.zork1(
            """
            take the boards
            north
            take the boards
            east
            examine the window
            look through the window
            take the window
            south
            take the boards
            """
        )
        await engine.run()

        await mockIO.expectOutput(
            """
            Zork I: The Great Underground Empire

            ZORK I: The Great Underground Empire Copyright (c) 1981, 1982,
            1983 Infocom, Inc. All rights reserved. ZORK is a registered
            trademark of Infocom, Inc. Revision 88 / Serial number 840726

            --- West of House ---

            You are standing in an open field west of a white house, with a
            boarded front door.

            There is a small mailbox here.

            > take the boards
            You cannot take the board, much as you might wish otherwise.

            > north
            --- North of House ---

            You are facing the north side of a white house. There is no
            door here, and all the windows are boarded up. To the north a
            narrow path winds through the trees.

            > take the boards
            The universe denies your request to take the board.

            > east
            --- Behind House ---

            You are behind the white house. A path leads into the forest to
            the east. In one corner of the house there is a small window
            which is slightly ajar.

            > examine the window
            The window is slightly ajar, but not enough to allow entry. The
            kitchen window is closed.

            > look through the window
            You can see what appears to be a kitchen.

            > take the window
            You cannot take the kitchen window, much as you might wish
            otherwise.

            > south
            --- South of House ---

            You are facing the south side of a white house. There is no
            door here, and all the windows are boarded.

            > take the boards
            You cannot take the board, much as you might wish otherwise.

            >
            May your adventures elsewhere prove fruitful!
            """
        )
    }

    @Test("Lamp and basic items collection")
    func testBasicItemCollection() async throws {
        let (engine, mockIO) = await GameEngine.zork1(
            pre: .enterKitchen,
            """
            west
            take lamp
            take sword
            examine lamp
            turn on lamp
            inventory
            east
            up
            take rope
            take knife
            inventory
            """
        )
        await engine.run()

        await mockIO.expectOutput(
            """
            > west
            --- Living Room ---

            You are in the living room. There is a doorway to the east, a
            wooden door with strange gothic lettering to the west, which
            appears to be nailed shut, a trophy case, and a large oriental
            rug in the center of the room.

            A battery-powered brass lantern is on the trophy case. Above
            the trophy case hangs an elvish sword of great antiquity.

            > take lamp
            Got it.

            > take sword
            Acquired.

            > examine lamp
            The lamp is turned off.

            > turn on lamp
            You successfully turn on the brass lantern.

            > inventory
            You are carrying:
            - A brass lantern
            - A sword

            > east
            --- Kitchen ---

            > up
            --- Attic ---

            This is the attic. The only exit is a stairway leading down.

            A large coil of rope is lying in the corner. On a table is a
            nasty-looking knife.

            > take rope
            Got it.

            > take knife
            Got it.

            > inventory
            You are carrying:
            - A nasty knife
            - A brass lantern
            - A rope
            - A sword

            >
            Until we meet again in another tale...
            """
        )
    }

    @Test("Container interactions (brown sack and bottle)")
    func testContainerInteractions() async throws {
        let (engine, mockIO) = await GameEngine.zork1(
            pre: .enterKitchen,
            """
            examine table
            take sack
            examine sack
            open sack
            examine sack
            take lunch
            take garlic
            take bottle
            examine bottle
            examine water
            drink water
            open bottle
            drink water
            examine bottle
            inventory
            """
        )
        await engine.run()

        await mockIO.expectOutput(
            """
            > examine table
            A bottle is sitting on the table. The glass bottle contains a
            quantity of water. On the table is an elongated brown sack,
            smelling of hot peppers.

            > take sack
            Got it.

            > examine sack
            The brown sack is closed.

            > open sack
            The brown sack parts to disclose a clove of garlic and a lunch,
            previously hidden from view.

            > examine sack
            The brown sack contains a clove of garlic and a lunch.

            > take lunch
            Got it.

            > take garlic
            Got it.

            > take bottle
            Got it.

            > examine bottle
            The glass bottle contains a quantity of water.

            > examine water
            It's just water.

            > drink water
            You'll have to open the glass bottle first.

            > open bottle
            The glass bottle parts to disclose a quantity of water,
            previously hidden from view.

            > drink water
            Thank you very much. I was rather thirsty (from all this
            talking, probably).

            > examine bottle
            The glass bottle is empty.

            > inventory
            You are carrying:
            - A glass bottle
            - A clove of garlic
            - A lunch
            - A brown sack

            >
            Until we meet again in another tale...
            """
        )
    }
}
