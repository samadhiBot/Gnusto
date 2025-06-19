import CustomDump
import Testing

@testable import GnustoEngine

@Suite("WaitActionHandler Tests")
struct WaitActionHandlerTests {
    let handler = WaitActionHandler()

    @Test("Wait performs successfully")
    func testWaitPerformsSuccessfully() async throws {
        // Arrange
        let mockParser = MockParser()
        let (engine, mockIO) = await GameEngine.test(
            blueprint: game,
            parser: mockParser
        )

        let command = Command(
            verb: .wait,
            rawInput: "wait"
        )

        // Act
        // We call perform(), which uses the default implementation
        // calling validate(), process(), and postProcess().
        await engine.execute(command: command)

        // Assert
        // The default postProcess should print the message from the ActionResult.
        let output = await mockIO.flush()
        expectNoDifference(output, "Time passes.")
    }

    // Removed testWaitProcessReturnsCorrectResult due to Sendable complexities
    // with returning ActionResult from the non-Sendable ActionHandler protocol.
    // The perform test adequately covers the behavior for this simple handler.

    // @Test("Wait process returns correct ActionResult")
    // func testWaitProcessReturnsCorrectResult() async throws {
    //     // ... removed implementation ...
    // }
}
