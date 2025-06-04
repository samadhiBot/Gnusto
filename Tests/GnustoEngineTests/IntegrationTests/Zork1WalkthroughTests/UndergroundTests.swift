import CustomDump
import GnustoEngine
import Testing

@testable import Zork1

struct UndergroundTests {
    @Test("Underground access via trap door")
    func testUndergroundAccess() async throws {
        let mockIO = await MockIOHandler(
            "north",
            "east",
            "open window",
            "west",
            "west",
            "take lamp",
            "turn on lamp",
            "examine trap door",
            "open trap door",
            "down",
            "look",
            "north"
        )
        let engine = await GameEngine(
            blueprint: Zork1(),
            parser: StandardParser(),
            ioHandler: mockIO
        )
        await engine.run()

        let transcript = await mockIO.flush()
        let lines = transcript.components(separatedBy: "\n")

        // Should be able to reach living room
        #expect(lines.contains { $0.contains("Living Room") })

        // Should be able to take and turn on lamp
        #expect(lines.contains { $0.contains("take") || $0.contains("Taken") })
        #expect(lines.contains { $0.contains("The brass lantern is now on") || $0.contains("turn") })

        // Should be able to open trap door
        #expect(lines.contains { $0.contains("You open the trap door") })

        // Should be able to go down to cellar (now lit)
        #expect(lines.contains { $0.contains("Cellar") })

        // Should be able to move to Troll Room
        #expect(lines.contains { $0.contains("Troll Room") })
    }

    @Test("Basic underground exploration")
    func testUndergroundExploration() async throws {
        let mockIO = await MockIOHandler(
            "north",
            "east",
            "open window",
            "west",
            "west",
            "take lamp",
            "turn on lamp",
            "open trap door",
            "down",
            "north",
            "east",
            "east",
            "look",
            "west",
            "west",
            "south",
            "south",
            "east",
            "look"
        )
        let engine = await GameEngine(
            blueprint: Zork1(),
            parser: StandardParser(),
            ioHandler: mockIO
        )
        await engine.run()

        let transcript = await mockIO.flush()
        let lines = transcript.components(separatedBy: "\n")

        // Should be able to navigate underground areas (with lamp)
        #expect(lines.contains { $0.contains("Cellar") })
        #expect(lines.contains { $0.contains("Troll Room") })
        #expect(lines.contains { $0.contains("East-West Passage") })
        #expect(lines.contains { $0.contains("Round Room") })
        #expect(lines.contains { $0.contains("East of Chasm") })
        #expect(lines.contains { $0.contains("Gallery") })
    }
}
