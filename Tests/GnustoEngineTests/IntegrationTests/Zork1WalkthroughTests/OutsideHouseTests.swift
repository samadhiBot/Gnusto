import CustomDump
import GnustoEngine
import Testing

@testable import Zork1

struct OutsideHouseTests {
    @Test("Basic house entry via kitchen window")
    func testHouseEntry() async throws {
        let mockIO = await MockIOHandler(
            Moves.enterKitchen,
            "examine table",
            "open sack",
            "inventory",
            "take all",
            "inventory",
        )
        let engine = await GameEngine.test(
            blueprint: Zork1(),
            parser: StandardParser(),
            ioHandler: mockIO
        )
        await engine.run()

        let transcript = await mockIO.flush()
        expectNoDifference(transcript, """
            \(Playback.enterKitchen)

            > examine table
            A bottle is sitting on the table. The glass bottle contains a
            quantity of water. On the table is an elongated brown sack,
            smelling of hot peppers.

            > open sack
            Opening the brown sack reveals a clove of garlic and a lunch.

            > inventory
            You are empty-handed.

            > take all
            You take the glass bottle and the brown sack.

            > inventory
            You are carrying:
            - A glass bottle
            - A brown sack

            >
            Goodbye!
            """)
    }

    @Test("Interacting with the mailbox")
    func testMailbox() async throws {
        let mockIO = await MockIOHandler(
            "take the mailbox",
            "open the mailbox",
            "read the leaflet",
            "east",
            "open door",
            "take boards",
            "look at the house",
        )
        let engine = await GameEngine.test(
            blueprint: Zork1(),
            parser: StandardParser(),
            ioHandler: mockIO
        )
        await engine.run()

        let transcript = await mockIO.flush()
        expectNoDifference(transcript, """
            \(Playback.zork1Intro)

            > take the mailbox
            It is securely anchored.

            > open the mailbox
            Opening the small mailbox reveals a leaflet.

            > read the leaflet
            (Taken)

            “WELCOME TO ZORK!

            ZORK is a game of adventure, danger, and low cunning. In it you
            will explore some of the most amazing territory ever seen by
            mortals. No computer should be without one!”

            > east
            The door is boarded and you can’t remove the boards.

            > open door
            You can’t open the door.

            > take boards
            The boards are securely fastened.

            > look at the house
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
            "examine the window",
            "look through the window",
            "take the window",
            "south",
            "take the boards",
        )
        let engine = await GameEngine.test(
            blueprint: Zork1(),
            parser: StandardParser(),
            ioHandler: mockIO
        )
        await engine.run()

        let transcript = await mockIO.flush()
        expectNoDifference(transcript, """
            \(Playback.zork1Intro)

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

            > examine the window
            The window is slightly ajar, but not enough to allow entry.

            > look through the window
            You can see what appears to be a kitchen.

            > take the window
            You can’t take the kitchen window.

            > south
            — South of House —

            You are facing the south side of a white house. There is no
            door here, and all the windows are boarded.

            > take the boards
            The boards are securely fastened.

            >
            Goodbye!
            """)
    }

    @Test("Lamp and basic items collection")
    func testBasicItemCollection() async throws {
        let mockIO = await MockIOHandler(
            Moves.enterKitchen,
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
        let engine = await GameEngine.test(
            blueprint: Zork1(),
            parser: StandardParser(),
            ioHandler: mockIO
        )
        await engine.run()

        let transcript = await mockIO.flush()
        expectNoDifference(transcript, """
            \(Playback.enterKitchen)

            > west
            — Living Room —

            You are in the living room. There is a doorway to the east, a
            wooden door with strange gothic lettering to the west, which
            appears to be nailed shut, a trophy case, and a large oriental
            rug in the center of the room.

            A battery-powered brass lantern is on the trophy case.

            Above the trophy case hangs an elvish sword of great antiquity.

            > take lamp
            Taken.

            > take sword
            Taken.

            > examine lamp
            The lamp is turned off.

            > turn on lamp
            The brass lantern is now on.

            > inventory
            You are carrying:
            - A brass lantern
            - A sword

            > east
            — Kitchen —

            > up
            — Attic —

            This is the attic. The only exit is a stairway leading down.

            A large coil of rope is lying in the corner.

            On a table is a nasty-looking knife.

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
            Moves.enterKitchen,
            "examine table",
            "take sack",
            "examine sack",
            "open sack",
            "examine sack",
            "take lunch",
            "take garlic",
            "take bottle",
            "examine bottle",
            "examine water",
            "drink water",
            "examine bottle",
            "inventory"
        )
        let engine = await GameEngine.test(
            blueprint: Zork1(),
            parser: StandardParser(),
            ioHandler: mockIO
        )
        await engine.run()

        let transcript = await mockIO.flush()
        expectNoDifference(transcript, """
            \(Playback.enterKitchen)

            > examine table
            A bottle is sitting on the table. The glass bottle contains a
            quantity of water. On the table is an elongated brown sack,
            smelling of hot peppers.

            > take sack
            Taken.

            > examine sack
            The brown sack is closed.

            > open sack
            Opening the brown sack reveals a clove of garlic and a lunch.

            > examine sack
            The brown sack contains a clove of garlic and a lunch.

            > take lunch
            Taken.

            > take garlic
            Taken.

            > take bottle
            Taken.

            > examine bottle
            The glass bottle contains a quantity of water.

            > examine water
            It’s just water.

            > drink water
            You drink the quantity of water. It’s quite refreshing.

            > examine bottle
            The glass bottle is empty.

            > inventory
            You are carrying:
            - A glass bottle
            - A clove of garlic
            - A lunch
            - A brown sack

            >
            Goodbye!
            """)
    }
}
