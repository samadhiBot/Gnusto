import Testing
import Foundation
import SwiftParser
import SwiftSyntax
@testable import GnustoAutoWiringTool

@Suite("Scanner Tests")
struct ScannerTests {

    @Test("GameDataCollector detects LocationIDs from enum area")
    func testLocationIDDetectionEnum() {
        let source = """
        import GnustoEngine

        enum EnumArea {
            static let room = Location(
                id: .room,
                .name("Room"),
                .description("A simple room."),
                .inherentlyLit
            )

            static let chair = Item(
                id: .chair,
                .name("chair"),
                .description("A wooden chair."),
                .in(.location(.room))
            )
        }
        """

        let gameData = parseGameData(from: source)

        #expect(gameData.locationIDs.contains("room"))
        #expect(gameData.itemIDs.contains("chair"))
        #expect(gameData.gameAreaTypes.contains("EnumArea"))
    }

    @Test("GameDataCollector detects GameBlueprint types")
    func testGameBlueprintTypeDetection() {
        let source = """
        import GnustoEngine

        struct AutoWiringTestGame: GameBlueprint {
            let constants = GameConstants(
                storyTitle: "Auto-Wiring Test Game",
                introduction: "Testing auto-wiring plugin scenarios...",
                release: "1",
                maximumScore: 100
            )

            var player: Player {
                Player(in: .livingRoom)
            }
        }
        """

        let gameData = parseGameData(from: source)

        #expect(gameData.gameBlueprintTypes.contains("AutoWiringTestGame"))
        #expect(gameData.locationIDs.contains("livingRoom"))
    }

    @Test("GameDataCollector detects event handlers")
    func testEventHandlerDetection() {
        let source = """
        import GnustoEngine

        enum TestArea {
            static let cloakHandler = ItemEventHandler { engine, event in
                return nil
            }

            static let barHandler = LocationEventHandler { engine, event in
                return nil
            }
        }
        """

        let gameData = parseGameData(from: source)

        #expect(gameData.itemEventHandlers.contains("cloak"))
        #expect(gameData.locationEventHandlers.contains("bar"))
        #expect(gameData.gameAreaTypes.contains("TestArea"))
    }

    // MARK: - Helper Methods

    private func parseGameData(from source: String) -> GameData {
        let scanner = Scanner()
        return scanner.processSource(source)
    }
}
