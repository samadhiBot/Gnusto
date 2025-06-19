import CustomDump
import Testing

@testable import GnustoEngine

@Suite("CryActionHandler Tests")
struct CryActionHandlerTests {
    @Test("CRY command")
    func testCry() async throws {
        let (engine, mockIO) = await GameEngine.test()
        let command = Command(verb: .cry, rawInput: "cry")

        // Act
        await engine.execute(command: command)

        // Assert
        let output = await mockIO.flush()
        expectNoDifference(output, "You weep quietly to yourself.")
    }

    @Test("CRY returns varied responses")
    func testCryVariedResponses() async throws {
        let (engine, mockIO) = await GameEngine.test()
        let command = Command(verb: .cry, rawInput: "cry")

        // Act
        await engine.execute(command: command)
        await engine.execute(command: command)
        await engine.execute(command: command)

        // Assert
        let output = await mockIO.flush()
        expectNoDifference(output, """
            You weep quietly to yourself.

            You break down and cry. After a bit the world seems a little
            brighter.

            You sob dramatically, and feel a little better.
            """)
    }
}
