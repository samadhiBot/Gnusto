import CustomDump
@testable import Gnusto // Import @testable to access internal types if needed
import Testing

struct ConditionalExitTests {
    @Test
    func testConditionalExits() throws {
        let game = TestGame()
        let renderer = TestRenderer()
        let engine = try Engine(game: game, renderer: renderer)
        try engine.start(enterGameLoop: false)
        renderer.clear()

        // Try going east without the lantern on - should be blocked
        let goEastDarkInput = UserInput(
            verb: .go,
            directObject: "east",
            rawInput: "go east"
        )
        engine.processAction(.command(goEastDarkInput))
        expectNoDifference(
            renderer.flush(),
            "It's too dark to see any passage to the east."
        )

        // Turn on the lantern
        let turnOnInput = UserInput(
            verb: "turn",
            directObject: "lantern",
            prepositions: "on",
            rawInput: "turn on lantern"
        )
        engine.processAction(.command(turnOnInput))
        expectNoDifference(
            renderer.flush(),
            """
            You turn on the brass lantern.
            STARTING ROOM
            This is where your adventure begins. A small, cozy room with wooden walls \
            and a comfortable feel.
            You can see: brass lantern, small key.
            Exits: east, north
            """
        )

        // Try going east again - should work now
        let goEastLitInput = UserInput(
            verb: "go",
            directObject: "east",
            rawInput: "go east"
        )
        engine.processAction(.command(goEastLitInput))
        expectNoDifference(
            renderer.flush(),
            """
            EAST ROOM
            A mysterious room with shimmering walls and a pedestal in the center.
            You can see: stone pedestal.
            Exits: north, west
            """
        )
    }
}
