import CustomDump
import Testing

@testable import Gnusto

@Suite("Renderer Tests")
struct RendererTests {
    @Test("TestRenderer should capture and render text effects")
    func testShowTextEffect() {
        // Arrange
        let renderer = TestRenderer()

        // Act
        renderer.render(.showText("Hello world"))
        renderer.render(.showText("Another message"))

        // Assert
        expectNoDifference(
            renderer.output(),
            """
            Hello world
            Another message
            """
        )
    }

    @Test("TestRenderer should handle status line updates")
    func testStatusLineEffect() {
        // Arrange
        let renderer = TestRenderer()

        // Act
        renderer.render(.updateStatusLine(location: "Cave", score: 10, moves: 5))

        // Assert - status line only shows in verbose mode
        expectNoDifference(
            renderer.output(verbose: true),
            ".updateStatusLine(Cave, 10, 5)"
        )

        // Should not show in normal mode
        expectNoDifference(renderer.output(), "")
    }

    @Test("TestRenderer should handle sound effects")
    func testSoundEffect() {
        // Arrange
        let renderer = TestRenderer()

        // Act
        renderer.render(.playSound("door_creak"))

        // Assert - sound only shows in verbose mode
        expectNoDifference(
            renderer.output(verbose: true),
            ".playSound(door_creak)"
        )

        // Should not show in normal mode
        expectNoDifference(renderer.output(), "")
    }

    @Test("TestRenderer should handle end game effect")
    func testEndGameEffect() {
        // Arrange
        let renderer = TestRenderer()

        // Act
        renderer.render(.endGame)

        // Assert
        expectNoDifference(
            renderer.output(),
            ".endGame(GAME OVER)"
        )
    }

    @Test("TestRenderer should handle inventory changes")
    func testInventoryChangeEffect() {
        // Arrange
        let renderer = TestRenderer()

        // Act - Test both adding and removing items
        renderer.render(.showInventoryChange(item: "brass lantern", added: true))
        renderer.render(.showInventoryChange(item: "small key", added: false))

        // Assert - inventory changes only show in verbose mode
        expectNoDifference(
            renderer.output(verbose: true),
            """
            .showInventoryChange(brass lantern true)
            .showInventoryChange(small key false)
            """
        )

        // Should not show in normal mode
        expectNoDifference(renderer.output(), "")
    }

    @Test("TestRenderer should handle object highlighting")
    func testHighlightObjectEffect() {
        // Arrange
        let renderer = TestRenderer()

        // Act
        renderer.render(.highlightObject(name: "ancient scroll"))

        // Assert - highlighting only shows in verbose mode
        expectNoDifference(
            renderer.output(verbose: true),
            ".highlightObject(ancient scroll)"
        )

        // Should not show in normal mode
        expectNoDifference(renderer.output(), "")
    }

    @Test("TestRenderer should handle input responses")
    func testInputResponses() {
        // Arrange
        let renderer = TestRenderer()
        renderer.inputResponses = ["look", "quit"]

        // Act & Assert
        expectNoDifference(renderer.getInput(prompt: "> "), "look")
        expectNoDifference(renderer.getInput(prompt: "> "), "quit")
        expectNoDifference(renderer.getInput(prompt: "> "), nil)
    }

    @Test("TestRenderer should clear captured effects")
    func testClearEffects() {
        // Arrange
        let renderer = TestRenderer()

        // Act
        renderer.render(.showText("First message"))
        renderer.clear()
        renderer.render(.showText("Second message"))

        // Assert
        expectNoDifference(
            renderer.output(),
            "Second message"
        )
    }

    @Test("TestRenderer should process multiple effects")
    func testProcessEffects() {
        // Arrange
        let renderer = TestRenderer()
        let effects: [Effect] = [
            .showText("Welcome to the game"),
            .updateStatusLine(location: "Start Room", score: 0, moves: 1),
            .playSound("intro_music"),
            .showText("You see a lantern here.")
        ]

        // Act & Assert - Test both normal and verbose output
        expectNoDifference(
            renderer.process(effects),
            """
            Welcome to the game
            You see a lantern here.
            """
        )

        expectNoDifference(
            renderer.process(effects, verbose: true),
            """
            Welcome to the game
            .updateStatusLine(Start Room, 0, 1)
            .playSound(intro_music)
            You see a lantern here.
            """
        )
    }

    @Test("TestRenderer should handle request input effects")
    func testRequestInputEffect() {
        // Arrange
        let renderer = TestRenderer()

        // Act
        renderer.render(.requestInput(prompt: "What do you want to do?"))

        // Assert - request input only shows in verbose mode
        expectNoDifference(
            renderer.output(verbose: true),
            ".requestInput(What do you want to do?)"
        )

        // Should not show in normal mode
        expectNoDifference(renderer.output(), "")
    }
}
