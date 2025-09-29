import GnustoEngine
import GnustoTestSupport
import Testing

@testable import Zork1

struct OutsideHouseTests {
    let engine: GameEngine
    let mockIO: MockIOHandler

    init() async {
        (engine, mockIO) = await GameEngine.test(
            blueprint: Zork1(
                rng: SeededRandomNumberGenerator()
            )
        )
    }

    @Test("Interacting with the mailbox")
    func testMailbox() async throws {
        try await engine.execute(
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

        await mockIO.expectOutput(
            """
            > take the mailbox
            It is securely anchored.

            > open the mailbox
            As the small mailbox opens, it reveals a leaflet within.

            > read the leaflet
            (Taken)

            "WELCOME TO ZORK!

            ZORK is a game of adventure, danger, and low cunning. In it you
            will explore some of the most amazing territory ever seen by
            mortals. No computer should be without one!"

            > east
            The door is boarded and you can't remove the boards.

            > open door
            You cannot open the door, much as you might wish otherwise.

            > take boards
            The universe denies your request to take the board.

            > look at the house
            The white house stubbornly remains ordinary despite your
            thorough examination.
            """
        )
    }

    @Test("Basic house entry via kitchen window")
    func testHouseEntry() async throws {
        try await engine.apply(
            engine.player.move(to: .kitchen)
        )

        try await engine.execute(
            """
            examine table
            open sack
            inventory
            take all
            inventory
            """
        )

        await mockIO.expectOutput(
            """
            > examine table
            A bottle is sitting on the table. The glass bottle contains a
            quantity of water. On the table is an elongated brown sack,
            smelling of hot peppers.

            > open sack
            As the brown sack opens, it reveals a clove of garlic and a
            lunch within.

            > inventory
            You are unburdened by material possessions.

            > take all
            You take the glass bottle and the brown sack.

            > inventory
            You are carrying:
            - A glass bottle
            - A brown sack
            """
        )
    }

    @Test("Interacting with the boards on the house")
    func testBoards() async throws {
        try await engine.execute(
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

        await mockIO.expectOutput(
            """
            > take the boards
            The board stubbornly resists your attempts to take it.

            > north
            --- North of House ---

            You are facing the north side of a white house. There is no
            door here, and all the windows are boarded up. To the north a
            narrow path winds through the trees.

            > take the boards
            You cannot take the board, much as you might wish otherwise.

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
            The universe denies your request to take the kitchen window.

            > south
            --- South of House ---

            You are facing the south side of a white house. There is no
            door here, and all the windows are boarded.

            > take the boards
            You cannot take the board, much as you might wish otherwise.
            """
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
            Taken.

            > take sword
            Got it.

            > examine lamp
            The lamp is turned off.

            > turn on lamp
            With practiced efficiency, you turn on the brass lantern.

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
            Got it.

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

            > take lunch
            Acquired.

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
}
