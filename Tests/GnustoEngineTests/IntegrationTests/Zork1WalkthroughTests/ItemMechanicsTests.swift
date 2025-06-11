import CustomDump
import GnustoEngine
import Testing

@testable import Zork1

struct ItemMechanicsTests {
    @Test("Lamp and basic items collection")
    func testBasicItemCollection() async throws {
        let mockIO = await MockIOHandler(
            Moves.enterKitchen,
            "west",
            "take all",
            "examine the lamp",
            "turn on the lamp",
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
            \(Stub.enterKitchen)

            > west
            — Living Room —

            You are in the living room. There is a doorway to the east, a
            wooden door with strange gothic lettering to the west, which
            appears to be nailed shut, a trophy case, and a large oriental
            rug in the center of the room.

            A battery-powered brass lantern is on the trophy case.

            Above the trophy case hangs an elvish sword of great antiquity.

            In the trophy case is an ancient parchment which appears to be
            a map.

            > take all
            You take the brass lantern and the sword.

            > examine the lamp
            The lamp is turned off.

            > turn on the lamp
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
            "get lunch",
            "take garlic from sack",
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
            \(Stub.enterKitchen)

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

            > get lunch
            Taken.

            > take garlic from sack
            Taken.

            > take bottle
            Taken.

            > examine bottle
            The glass bottle contains a quantity of water.

            > drink water
            I don’t know the verb ‘drink’.

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

    @Test("Lamp mechanics")
    func testLampMechanics() async throws {
        let mockIO = await MockIOHandler(
            Moves.enterKitchen,
            "west",
            "take the lamp",
            "examine it",
            "go east",
            "climb the stairs",
            "light the lamp",
            "extinguish the lamp"
        )
        let engine = await GameEngine(
            blueprint: Zork1(),
            parser: StandardParser(),
            ioHandler: mockIO
        )
        await engine.run()

        let transcript = await mockIO.flush()
        expectNoDifference(transcript, """
            \(Stub.enterKitchen)

            > west
            — Living Room —

            You are in the living room. There is a doorway to the east, a
            wooden door with strange gothic lettering to the west, which
            appears to be nailed shut, a trophy case, and a large oriental
            rug in the center of the room.

            A battery-powered brass lantern is on the trophy case.

            Above the trophy case hangs an elvish sword of great antiquity.

            In the trophy case is an ancient parchment which appears to be
            a map.

            > take the lamp
            Taken.

            > examine it
            The lamp is turned off.

            > go east
            — Kitchen —

            > climb the stairs
            You have moved into a dark place.

            It is pitch black. You are likely to be eaten by a grue.

            > light the lamp
            The brass lantern is now on. You can see your surroundings now.

            — Attic —

            This is the attic. The only exit is a stairway leading down.

            A large coil of rope is lying in the corner.

            On a table is a nasty-looking knife.

            > extinguish the lamp
            The brass lantern is now off. You are plunged into darkness.

            It is pitch black. You are likely to be eaten by a grue.

            >
            Goodbye!
            """)
    }
}
