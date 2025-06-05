import CustomDump
import GnustoEngine
import Testing

@testable import Zork1

struct OutsideHouseTests {
    let enterKitchenSteps = [
        "north",
        "east",
        "examine window",
        "open window",
        "west",
    ]

    let introPlayback = """
        Zork I: The Great Underground Empire
        
        ZORK I: The Great Underground Empire Copyright (c) 1981, 1982,
        1983 Infocom, Inc. All rights reserved. ZORK is a registered
        trademark of Infocom, Inc. Revision 88 / Serial number 840726
        """

    let enterKitchenPlayback = """
        Zork I: The Great Underground Empire
        
        ZORK I: The Great Underground Empire Copyright (c) 1981, 1982,
        1983 Infocom, Inc. All rights reserved. ZORK is a registered
        trademark of Infocom, Inc. Revision 88 / Serial number 840726

        — West of House —

        You are standing in an open field west of a white house, with a
        boarded front door.

        There is a small mailbox here.

        > north
        — North of House —

        You are facing the north side of a white house. There is no
        door here, and all the windows are boarded up. To the north a
        narrow path winds through the trees.

        > east
        — Behind House —

        You are behind the white house. A path leads into the forest to
        the east. In one corner of the house there is a small window
        which is slightly ajar.

        > examine window
        The window is slightly ajar, but not enough to allow entry.

        > open window
        With great effort, you open the window far enough to allow
        entry.

        > west
        — Kitchen —

        You are in the kitchen of the white house. A table seems to
        have been used recently for the preparation of food. A passage
        leads to the west and a dark staircase can be seen leading
        upward. A dark chimney leads down and to the east is a small
        window which is open.
        """

    @Test("Basic house entry via kitchen window")
    func testHouseEntry() async throws {
        let mockIO = await MockIOHandler(
            enterKitchenSteps,
            "examine table",
            "open sack",
            "inventory"
        )
        let engine = await GameEngine(
            blueprint: Zork1(),
            parser: StandardParser(),
            ioHandler: mockIO
        )
        await engine.run()

        let transcript = await mockIO.flush()
        expectNoDifference(transcript, """
            \(enterKitchenPlayback)

            > examine table
            The table seems to have been used recently for the preparation
            of food. The kitchen table contains a glass bottle and a brown
            sack.

            > open sack
            You open the brown sack.

            > inventory
            You are empty-handed.

            >
            Goodbye!
            """)
    }

    @Test("Interacting with the mailbox")
    func testMailbox() async throws {
        let mockIO = await MockIOHandler(
            "take the mailbox",
            "open the mailbox",
            "east",
            "open door",
            "take boards",
            "look house",
        )
        let engine = await GameEngine(
            blueprint: Zork1(),
            parser: StandardParser(),
            ioHandler: mockIO
        )
        await engine.run()

        let transcript = await mockIO.flush()
        expectNoDifference(transcript, """
            \(introPlayback)

            — West of House —

            You are standing in an open field west of a white house, with a
            boarded front door.

            There is a small mailbox here.

            > take the mailbox
            It is securely anchored.

            > open the mailbox
            You open the small mailbox.

            > east
            The door is boarded and you can’t remove the boards.

            > open door
            You can’t open the front door.

            > take boards
            The boards are securely fastened.

            > look house
            The house is a beautiful colonial house which is painted white.
            It is clear that the owners must have been extremely wealthy.

            >
            Goodbye!
            """)
    }

    @Test("Interacting with the boards on the house")
    func testBoards() async throws {
        let mockIO = await MockIOHandler(
            "take the boards",
            "north",
            "take the boards",
            "east",
            "take the boards",
            "south",
            "take the boards",
        )
        let engine = await GameEngine(
            blueprint: Zork1(),
            parser: StandardParser(),
            ioHandler: mockIO
        )
        await engine.run()

        let transcript = await mockIO.flush()
        expectNoDifference(transcript, """
            \(introPlayback)

            — West of House —

            You are standing in an open field west of a white house, with a
            boarded front door.

            There is a small mailbox here.

            > take the boards
            The boards are securely fastened.

            > north
            — North of House —

            You are facing the north side of a white house. There is no
            door here, and all the windows are boarded up. To the north a
            narrow path winds through the trees.

            > take the boards
            The boards are securely fastened.

            > east
            — Behind House —

            You are behind the white house. A path leads into the forest to
            the east. In one corner of the house there is a small window
            which is slightly ajar.

            > take the boards
            The boards are securely fastened.

            > south
            — South of House —

            You are facing the south side of a white house. There is no
            door here, and all the windows are boarded.

            There is a boarded window here.

            > take the boards
            The boards are securely fastened.

            >
            Goodbye!
            """)
    }

    @Test("Lamp and basic items collection")
    func testBasicItemCollection() async throws {
        let mockIO = await MockIOHandler(
            enterKitchenSteps,
            "west",
            "take lamp",
            "take sword",
            "examine lamp",
            "turn on lamp",
            "inventory",
            "east",
            "up",
            "take rope",
            "take knife",
            "inventory"
        )
        let engine = await GameEngine(
            blueprint: Zork1(),
            parser: StandardParser(),
            ioHandler: mockIO
        )
        await engine.run()

        let transcript = await mockIO.flush()
        expectNoDifference(transcript, """
            \(enterKitchenPlayback)

            > west
            — Living Room —

            You are in the living room. There is a doorway to the east, a
            wooden door with strange gothic lettering to the west, which
            appears to be nailed shut, a trophy case, and a large oriental
            rug in the center of the room.

            There are a brass lantern and a sword here.

            > take lamp
            Taken.

            > take sword
            Taken.

            > examine lamp
            The brass lantern is turned off. The brass lantern contains a
            clear glass globe which is currently dark.

            > turn on lamp
            The brass lantern is now on.

            — Living Room —

            You are in the living room. There is a doorway to the east, a
            wooden door with strange gothic lettering to the west, which
            appears to be nailed shut, a trophy case, and a large oriental
            rug in the center of the room.

            > inventory
            You are carrying:
            - A brass lantern
            - A sword

            > east
            — Kitchen —

            > up
            — Attic —

            This is the attic. The only exit is a stairway leading down.

            There are a nasty knife and a rope here.

            > take rope
            Taken.

            > take knife
            Taken.

            > inventory
            You are carrying:
            - A nasty knife
            - A brass lantern
            - A rope
            - A sword

            >
            Goodbye!
            """)
    }

    @Test("Container interactions (brown sack and bottle)")
    func testContainerInteractions() async throws {
        let mockIO = await MockIOHandler(
            enterKitchenSteps,
            "examine table",
            "take sack",
            "examine sack",
            "open sack",
            "examine sack",
            "take lunch",
            "take garlic",
            "take bottle",
            "examine bottle",
            "drink water",
            "inventory"
        )
        let engine = await GameEngine(
            blueprint: Zork1(),
            parser: StandardParser(),
            ioHandler: mockIO
        )
        await engine.run()

        let transcript = await mockIO.flush()
        expectNoDifference(transcript, """
            \(enterKitchenPlayback)

            > examine table
            The table seems to have been used recently for the preparation
            of food. The kitchen table contains a glass bottle and a brown
            sack.

            > take sack
            Taken.

            > examine sack
            An elongated brown sack, smelling of hot peppers. The brown
            sack is closed.

            > open sack
            You open the brown sack.

            > examine sack
            An elongated brown sack, smelling of hot peppers. The brown
            sack contains a clove of garlic and a lunch.

            > take lunch
            Taken.

            > take garlic
            Taken.

            > take bottle
            Taken.

            > examine bottle
            It’s a glass bottle. The glass bottle is closed.

            > drink water
            I don’t know the verb ‘drink’.

            > inventory
            You are carrying:
            - A glass bottle
            - A brown sack
            - A clove of garlic
            - A lunch

            >
            Goodbye!
            """)
    }
}
