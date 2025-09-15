import CustomDump
import GnustoEngine
import GnustoTestSupport
import Testing

@testable import Zork1

struct ItemMechanicsTests {
    @Test("Lamp and basic items collection")
    func testBasicItemCollection() async throws {
        let (engine, mockIO) = await GameEngine.zork1(
            pre: .enterKitchen,
            """
            west
            take all
            examine the lamp
            turn on the lamp
            inventory
            east
            up
            take rope
            take knife
            inventory
            """
        )
        await engine.run()

        let transcript = await mockIO.flush()
        expectNoDifference(
            transcript,
            """
            > west
            --- Living Room ---

            You are in the living room. There is a doorway to the east, a
            wooden door with strange gothic lettering to the west, which
            appears to be nailed shut, a trophy case, and a large oriental
            rug in the center of the room.

            A battery-powered brass lantern is on the trophy case. Above
            the trophy case hangs an elvish sword of great antiquity.

            > take all
            You take the brass lantern and the sword.

            > examine the lamp
            The lamp is turned off.

            > turn on the lamp
            With practiced efficiency, you turn on the brass lantern.

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
            May your adventures elsewhere prove fruitful!
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
            get lunch
            take garlic from sack
            take bottle
            examine it
            drink water
            open bottle
            drink water
            examine bottle
            inventory
            """
        )
        await engine.run()

        let transcript = await mockIO.flush()
        expectNoDifference(
            transcript,
            """
            > examine table
            A bottle is sitting on the table. The glass bottle contains a
            quantity of water. On the table is an elongated brown sack,
            smelling of hot peppers.

            > take sack
            Acquired.

            > examine sack
            The brown sack is closed.

            > open sack
            Opening the brown sack brings a clove of garlic and a lunch
            into the light.

            > examine sack
            The brown sack contains a clove of garlic and a lunch.

            > get lunch
            Got it.

            > take garlic from sack
            Got it.

            > take bottle
            Acquired.

            > examine it
            The glass bottle contains a quantity of water.

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
            May your adventures elsewhere prove fruitful!
            """
        )
    }

    @Test("Lamp mechanics")
    func testLampMechanics() async throws {
        let (engine, mockIO) = await GameEngine.zork1(
            pre: .enterKitchen,
            """
            west
            take the lamp
            examine it
            go east
            climb the stairs
            light the lamp
            extinguish the lamp
            """
        )
        await engine.run()

        let transcript = await mockIO.flush()
        expectNoDifference(
            transcript,
            """
            > west
            --- Living Room ---

            You are in the living room. There is a doorway to the east, a
            wooden door with strange gothic lettering to the west, which
            appears to be nailed shut, a trophy case, and a large oriental
            rug in the center of the room.

            A battery-powered brass lantern is on the trophy case. Above
            the trophy case hangs an elvish sword of great antiquity.

            > take the lamp
            Acquired.

            > examine it
            The lamp is turned off.

            > go east
            --- Kitchen ---

            > climb the stairs
            You have moved into a dark place.

            It is pitch black. You are likely to be eaten by a grue.

            > light the lamp
            You successfully light the brass lantern.

            --- Attic ---

            This is the attic. The only exit is a stairway leading down.

            A large coil of rope is lying in the corner. On a table is a
            nasty-looking knife.

            > extinguish the lamp
            You extinguish the brass lantern.

            You have moved into a dark place.

            It is pitch black. You are likely to be eaten by a grue.

            >
            May your adventures elsewhere prove fruitful!
            """
        )
    }
}
