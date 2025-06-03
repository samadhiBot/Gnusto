import CustomDump
//import Foundation
//import SwiftParser
//import SwiftSyntax
import Testing

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

        let scanner = Scanner(source: source)
        let gameData = scanner.process()

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

        let scanner = Scanner(source: source)
        let gameData = scanner.process()

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

        let scanner = Scanner(source: source)
        let gameData = scanner.process()

        #expect(gameData.itemEventHandlers.contains("cloak"))
        #expect(gameData.locationEventHandlers.contains("bar"))
        #expect(gameData.gameAreaTypes.contains("TestArea"))
    }

    @Test("Refined ID detection filters out method calls correctly")
    func testRefinedIDDetection() {
        let source = """
            import GnustoEngine

            enum TestArea {
                static let room = Location(
                    id: .room,
                    .name("Test Room"),
                    .description("A simple test room."),
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

        let scanner = Scanner(source: source)
        let gameData = scanner.process()

        // Should detect actual IDs
        #expect(gameData.locationIDs.contains("room"))
        #expect(gameData.itemIDs.contains("chair"))
        #expect(gameData.gameAreaTypes.contains("TestArea"))

        // Should NOT detect method calls as IDs
        #expect(!gameData.locationIDs.contains("name"))
        #expect(!gameData.locationIDs.contains("description"))
        #expect(!gameData.locationIDs.contains("location"))
        #expect(!gameData.itemIDs.contains("in"))
    }

    @Test("Complex multi-item scenario detection")
    func testComplexMultiItemDetection() {
        let source = """
            import GnustoEngine

            enum TestArea {
                static let room = Location(
                    id: .room,
                    .name("Test Room"),
                    .description("A simple test room."),
                    .inherentlyLit
                )

                static let chair = Item(
                    id: .chair,
                    .name("chair"),
                    .description("A wooden chair."),
                    .in(.location(.room))
                )

                static let table = Item(
                    id: .table,
                    .name("table"),
                    .description("A wooden table."),
                    .in(.location(.room))
                )
            }

            struct TestGame: GameBlueprint {
                let constants = GameConstants(
                    storyTitle: "Test Game",
                    introduction: "A simple test game.",
                    release: "1",
                    maximumScore: 100
                )

                var player: Player {
                    Player(in: .room)
                }
            }
            """

        let scanner = Scanner(source: source)
        let gameData = scanner.process()

        // Should detect all IDs
        #expect(gameData.locationIDs.contains("room"))
        #expect(gameData.itemIDs.contains("chair"))
        #expect(gameData.itemIDs.contains("table"))
        #expect(gameData.gameBlueprintTypes.contains("TestGame"))
        #expect(gameData.gameAreaTypes.contains("TestArea"))

        // Verify counts
        #expect(gameData.itemIDs.count >= 2)
        #expect(gameData.locationIDs.count >= 1)
    }

    @Test("CloakOfDarkness-style pattern detection")
    func testCloakOfDarknessPatterns() {
        let source = """
            import GnustoEngine

            enum OperaHouse {
                static let foyer = Location(
                    id: .foyer,
                    .name("Foyer of the Opera House"),
                    .description("You are standing in a spacious hall."),
                    .exits([
                        .south: .to(.bar),
                        .west: .to(.cloakroom),
                    ]),
                    .inherentlyLit
                )

                static let cloakroom = Location(
                    id: .cloakroom,
                    .name("Cloakroom"),
                    .description("The walls of this small room were clearly once lined with hooks."),
                    .exits([
                        .east: .to(.foyer),
                    ]),
                    .inherentlyLit
                )

                static let bar = Location(
                    id: .bar,
                    .name("Bar"),
                    .description("You are in the bar. It is quite dark here."),
                    .exits([
                        .north: .to(.foyer),
                    ])
                )

                static let cloak = Item(
                    id: .cloak,
                    .name("velvet cloak"),
                    .description("A handsome cloak."),
                    .in(.player),
                    .isWearable
                )

                static let hook = Item(
                    id: .hook,
                    .adjectives("small", "brass"),
                    .in(.location(.cloakroom)),
                    .isScenery,
                    .isSurface
                )
            }
            """

        let scanner = Scanner(source: source)
        let gameData = scanner.process()

        // Should detect all expected IDs
        #expect(gameData.locationIDs.contains("foyer"))
        #expect(gameData.locationIDs.contains("cloakroom"))
        #expect(gameData.locationIDs.contains("bar"))
        #expect(gameData.itemIDs.contains("cloak"))
        #expect(gameData.itemIDs.contains("hook"))
        #expect(gameData.gameAreaTypes.contains("OperaHouse"))

        // Should NOT detect method calls
        #expect(!gameData.locationIDs.contains("to"))
        #expect(!gameData.itemIDs.contains("adjectives"))
        #expect(!gameData.itemIDs.contains("player"))
    }

    @Test("Edge case: Empty game area")
    func testEmptyGameArea() {
        let source = """
            import GnustoEngine

            enum EmptyArea {
                // No content
            }
            """

        let scanner = Scanner(source: source)
        let gameData = scanner.process()

        // Should detect area but no game objects
        #expect(gameData.gameAreaTypes.contains("EmptyArea"))
        #expect(gameData.locationIDs.isEmpty)
        #expect(gameData.itemIDs.isEmpty)
    }

    @Test("Edge case: Non-game code")
    func testNonGameCode() {
        let source = """
            import Foundation

            struct RegularStruct {
                let property = "value"

                func regularMethod() {
                    print("Not game code")
                }
            }
            """

        let scanner = Scanner(source: source)
        let gameData = scanner.process()

        // Should not detect anything
        #expect(gameData.locationIDs.isEmpty)
        #expect(gameData.itemIDs.isEmpty)
        #expect(gameData.gameAreaTypes.isEmpty)
        #expect(gameData.gameBlueprintTypes.isEmpty)
    }

    @Test("Various ID contexts and patterns")
    func testVariousIDPatterns() {
        let source = """
            import GnustoEngine

            enum TestArea {
                static let forestPath = Location(
                    id: .forestPath,
                    .exits([
                        .north: .to(.northOfHouse),
                        .south: .to(.southOfHouse),
                    ])
                )

                static let sword = Item(
                    id: .sword,
                    .in(.location(.forestPath))
                )
            }
            """

        let scanner = Scanner(source: source)
        let gameData = scanner.process()

        // Should detect IDs in various contexts
        #expect(gameData.locationIDs.contains("forestPath"))
        #expect(gameData.locationIDs.contains("northOfHouse"))
        #expect(gameData.locationIDs.contains("southOfHouse"))
        #expect(gameData.itemIDs.contains("sword"))

        // Should NOT detect method names
        #expect(!gameData.locationIDs.contains("exits"))
        #expect(!gameData.locationIDs.contains("to"))
    }
}

@Suite("CodeGenerator Tests")
struct CodeGeneratorTests {

    @Test("CodeGenerator produces basic ID extensions")
    func testBasicIDExtensions() {
        var gameData = GameData()
        gameData.locationIDs = ["room", "hall"]
        gameData.itemIDs = ["chair", "table"]

        let generator = CodeGenerator()
        let generatedCode = generator.generate(from: gameData)

        // Should contain proper headers
        #expect(generatedCode.contains("// Generated by GnustoAutoWiringPlugin"))
        #expect(generatedCode.contains("import GnustoEngine"))

        // Should contain LocationID extension
        #expect(generatedCode.contains("extension LocationID {"))
        #expect(generatedCode.contains("static let room = LocationID(\"room\")"))
        #expect(generatedCode.contains("static let hall = LocationID(\"hall\")"))

        // Should contain ItemID extension
        #expect(generatedCode.contains("extension ItemID {"))
        #expect(generatedCode.contains("static let chair = ItemID(\"chair\")"))
        #expect(generatedCode.contains("static let table = ItemID(\"table\")"))
    }

    @Test("CodeGenerator handles empty GameData")
    func testEmptyGameData() {
        let gameData = GameData()
        let generator = CodeGenerator()
        let generatedCode = generator.generate(from: gameData)

        // Should contain headers and no-content message
        #expect(generatedCode.contains("// Generated by GnustoAutoWiringPlugin"))
        #expect(generatedCode.contains("import GnustoEngine"))
        #expect(generatedCode.contains("// No ID constants or GameBlueprint extensions need to be generated."))

        // Should NOT contain any extensions
        #expect(!generatedCode.contains("extension LocationID"))
        #expect(!generatedCode.contains("extension ItemID"))
    }

    @Test("CodeGenerator produces sorted output")
    func testSortedOutput() {
        var gameData = GameData()
        // Add in non-alphabetical order to test sorting
        gameData.locationIDs = ["zebra", "alpha", "beta"]
        gameData.itemIDs = ["yankee", "xray", "zulu"]

        let generator = CodeGenerator()
        let generatedCode = generator.generate(from: gameData)

        // Should be sorted alphabetically
        let lines = generatedCode.components(separatedBy: .newlines)
        let locationLines = lines.filter { $0.contains("static let") && $0.contains("LocationID") }
        let itemLines = lines.filter { $0.contains("static let") && $0.contains("ItemID") }

        // Check LocationID sorting
        #expect(locationLines.count == 3)
        #expect(locationLines[0].contains("alpha"))
        #expect(locationLines[1].contains("beta"))
        #expect(locationLines[2].contains("zebra"))

        // Check ItemID sorting
        #expect(itemLines.count == 3)
        #expect(itemLines[0].contains("xray"))
        #expect(itemLines[1].contains("yankee"))
        #expect(itemLines[2].contains("zulu"))
    }

    @Test("CodeGenerator handles all ID types")
    func testAllIDTypes() {
        var gameData = GameData()
        gameData.locationIDs = ["room"]
        gameData.itemIDs = ["chair"]
        gameData.globalIDs = ["score"]
        gameData.fuseIDs = ["bomb"]
        gameData.daemonIDs = ["timer"]
        gameData.verbIDs = ["dance"]

        let generator = CodeGenerator()
        let generatedCode = generator.generate(from: gameData)

        // Should contain all extension types
        #expect(generatedCode.contains("extension LocationID {"))
        #expect(generatedCode.contains("extension ItemID {"))
        #expect(generatedCode.contains("extension GlobalID {"))
        #expect(generatedCode.contains("extension FuseID {"))
        #expect(generatedCode.contains("extension DaemonID {"))
        #expect(generatedCode.contains("extension VerbID {"))

        // Should contain all expected constants
        #expect(generatedCode.contains("static let room = LocationID(\"room\")"))
        #expect(generatedCode.contains("static let chair = ItemID(\"chair\")"))
        #expect(generatedCode.contains("static let score = GlobalID(\"score\")"))
        #expect(generatedCode.contains("static let bomb = FuseID(\"bomb\")"))
        #expect(generatedCode.contains("static let timer = DaemonID(\"timer\")"))
        #expect(generatedCode.contains("static let dance = VerbID(\"dance\")"))
    }
}

@Suite("Integration Tests")
struct IntegrationTests {

    @Test("Full pipeline: Scanner to CodeGenerator")
    func testFullPipeline() {
        let source = """
            import GnustoEngine

            enum TestArea {
                static let room = Location(
                    id: .room,
                    .name("Test Room"),
                    .inherentlyLit
                )

                static let chair = Item(
                    id: .chair,
                    .name("chair"),
                    .in(.location(.room))
                )
            }
            """

        // Parse with Scanner
        let scanner = Scanner(source: source)
        let gameData = scanner.process()

        // Generate code with CodeGenerator
        let generator = CodeGenerator()
        let generatedCode = generator.generate(from: gameData)

        // Verify the complete pipeline
        #expect(generatedCode.contains("extension LocationID {"))
        #expect(generatedCode.contains("static let room = LocationID(\"room\")"))
        #expect(generatedCode.contains("extension ItemID {"))
        #expect(generatedCode.contains("static let chair = ItemID(\"chair\")"))

        // Verify filtering worked
        #expect(!generatedCode.contains("location"))
        #expect(!generatedCode.contains("name"))
    }

    @Test("Real-world CloakOfDarkness generation")
    func testCloakOfDarknessGeneration() {
        let source = """
            import GnustoEngine

            enum OperaHouse {
                static let foyer = Location(id: .foyer, .name("Foyer"))
                static let bar = Location(id: .bar, .name("Bar"))
                static let cloakroom = Location(id: .cloakroom, .name("Cloakroom"))
                static let cloak = Item(id: .cloak, .name("cloak"))
                static let hook = Item(id: .hook, .name("hook"))
            }

            struct CloakOfDarkness: GameBlueprint {
                let constants = GameConstants(storyTitle: "Cloak of Darkness", introduction: "A brief test.", release: "1", maximumScore: 2)
                var player: Player { Player(in: .foyer) }
            }
            """

        let scanner = Scanner(source: source)
        let gameData = scanner.process()

        let generator = CodeGenerator()
        let generatedCode = generator.generate(from: gameData)

        // Should contain all expected CloakOfDarkness IDs
        #expect(generatedCode.contains("static let foyer = LocationID(\"foyer\")"))
        #expect(generatedCode.contains("static let bar = LocationID(\"bar\")"))
        #expect(generatedCode.contains("static let cloakroom = LocationID(\"cloakroom\")"))
        #expect(generatedCode.contains("static let cloak = ItemID(\"cloak\")"))
        #expect(generatedCode.contains("static let hook = ItemID(\"hook\")"))

        // Verify GameBlueprint was detected
        #expect(gameData.gameBlueprintTypes.contains("CloakOfDarkness"))
    }
}
