import CustomDump
import GnustoEngine
import Testing

@testable import Zork1

struct ForestTests {
    @Test("Forest exploration and grating discovery")
    func testForestExploration() async throws {
        let mockIO = await MockIOHandler(
            "north",
            "north",
            "examine path",
            "north",
            "examine trees",
            "east",
            "north",
            "examine grating",
            "move leaves",
            "examine grating"
        )
        let engine = await GameEngine(
            blueprint: Zork1(),
            parser: StandardParser(),
            ioHandler: mockIO
        )
        await engine.run()

        let transcript = await mockIO.flush()
        let lines = transcript.components(separatedBy: "\n")

        // Should be able to explore forest areas
        #expect(lines.contains { $0.contains("Forest Path") || $0.contains("path") })
        #expect(lines.contains { $0.contains("forest") || $0.contains("Forest") })

        // Should find grating
        #expect(lines.contains { $0.contains("grating") })
    }
}
