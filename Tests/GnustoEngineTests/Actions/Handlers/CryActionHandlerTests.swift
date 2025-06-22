import CustomDump
import Testing

@testable import GnustoEngine

@Suite("CryActionHandler Tests")
struct CryActionHandlerTests {
    @Test("CRY command")
    func testCry() async throws {
        let (engine, mockIO) = await GameEngine.test()

        // Act
        try await engine.execute("cry")

        // Assert
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > cry
            You shed tears with the confident vulnerability of a
            true empath.
            """)
    }

    @Test("CRY returns varied responses")
    func testCryVariedResponses() async throws {
        let (engine, mockIO) = await GameEngine.test()

        // Act
        try await engine.execute("cry", times: 3)

        // Assert
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > cry
            You shed tears with the confident vulnerability of a
            true empath.

            > cry
            You cry with the authentic passion of someone unafraid to
            feel deeply.

            > cry
            You weep beautifully, demonstrating your impressive range
            of expression.
            """)
    }
}
