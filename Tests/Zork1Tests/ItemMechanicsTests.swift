import GnustoEngine
import GnustoTestSupport
import Testing

@testable import Zork1

struct ItemMechanicsTests {
    let engine: GameEngine
    let mockIO: MockIOHandler

    init() async {
        (engine, mockIO) = await GameEngine.test(
            blueprint: Zork1(
                rng: SeededRandomNumberGenerator()
            )
        )
    }

    @Test("Lamp and basic items collection")
    func testBasicItemCollection() async throws {
        try await engine.apply(
            engine.player.move(to: .kitchen)
        )

        try await engine.execute(
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

            > take all
            You take the brass lantern and the sword.

            > examine the lamp
            The lamp is turned off.

            > turn on the lamp
            You turn on the brass lantern.

            > inventory
            You are carrying:
            - A brass lantern
            - A sword

            > east
            --- Kitchen ---

            You are in the kitchen of the white house. A table seems to
            have been used recently for the preparation of food. A passage
            leads to the west and a dark staircase can be seen leading
            upward. A dark chimney leads down and to the east is a small
            window which is slightly ajar.

            A bottle is sitting on the table. On the table is an elongated
            brown sack, smelling of hot peppers.

            > up
            --- Attic ---

            This is the attic. The only exit is a stairway leading down.

            A large coil of rope is lying in the corner. On a table is a
            nasty-looking knife.

            > take rope
            Got it.

            > take knife
            Acquired.

            > inventory
            You are carrying:
            - A nasty knife
            - A brass lantern
            - A rope
            - A sword
            """
        )
    }

    @Test("Container interactions (brown sack and bottle)")
    func testContainerInteractions() async throws {
        try await engine.apply(
            engine.player.move(to: .kitchen)
        )

        try await engine.execute(
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

        await mockIO.expectOutput(
            """
            > examine table
            A bottle is sitting on the table. The glass bottle contains a
            quantity of water. On the table is an elongated brown sack,
            smelling of hot peppers.

            > take sack
            Taken.

            > examine sack
            The brown sack is closed.

            > open sack
            Opening the brown sack brings a clove of garlic and a lunch
            into the light.

            > examine sack
            The brown sack contains a clove of garlic and a lunch.

            > get lunch
            Acquired.

            > take garlic from sack
            Got it.

            > take bottle
            Got it.

            > examine it
            The glass bottle contains a quantity of water.

            > drink water
            You'll have to open the glass bottle first.

            > open bottle
            Opening the glass bottle brings a quantity of water into the
            light.

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
            """
        )
    }

    @Test("Lamp mechanics")
    func testLampMechanics() async throws {
        try await engine.apply(
            engine.player.move(to: .kitchen)
        )

        try await engine.execute(
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

            > take the lamp
            Taken.

            > examine it
            The lamp is turned off.

            > go east
            --- Kitchen ---

            You are in the kitchen of the white house. A table seems to
            have been used recently for the preparation of food. A passage
            leads to the west and a dark staircase can be seen leading
            upward. A dark chimney leads down and to the east is a small
            window which is slightly ajar.

            A bottle is sitting on the table. On the table is an elongated
            brown sack, smelling of hot peppers.

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
            """
        )
    }
}
