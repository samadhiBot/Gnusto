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
                    .in(.room)
                )
            }
            """

        let scanner = Scanner(source: source)
        let gameData = scanner.process()

        #expect(gameData.locationIDs.contains("room"))
        #expect(gameData.itemIDs.contains("chair"))
        #expect(gameData.gameAreaTypes.contains("EnumArea"))
    }

    @Test("GameDataCollector detects LocationIDs from struct area static properties")
    func testLocationIDDetectionStructStaticProperties() {
        let source = """
            import GnustoEngine

            struct EnumArea {
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
                    .in(.room)
                )
            }
            """

        let scanner = Scanner(source: source)
        let gameData = scanner.process()

        #expect(gameData.locationIDs.contains("room"))
        #expect(gameData.itemIDs.contains("chair"))
        #expect(gameData.gameAreaTypes.contains("EnumArea"))
    }

    @Test("GameDataCollector detects LocationIDs from struct area instance properties")
    func testLocationIDDetectionStructInstanceProperties() {
        let source = """
            import GnustoEngine

            struct EnumArea {
                let room = Location(
                    id: .room,
                    .name("Room"),
                    .description("A simple room."),
                    .inherentlyLit
                )

                let chair = Item(
                    id: .chair,
                    .name("chair"),
                    .description("A wooden chair."),
                    .in(.room)
                )
            }
            """

        let scanner = Scanner(source: source)
        let gameData = scanner.process()

        #expect(gameData.locationIDs.contains("room"))
        #expect(gameData.itemIDs.contains("chair"))
        #expect(gameData.gameAreaTypes.contains("EnumArea"))
    }

    @Test("GameDataCollector detects LocationIDs from struct area mixed properties")
    func testLocationIDDetectionStructMixedProperties() {
        let source = """
            import GnustoEngine

            struct EnumArea {
                static let room = Location(
                    id: .room,
                    .name("Room"),
                    .description("A simple room."),
                    .inherentlyLit
                )

                let chair = Item(
                    id: .chair,
                    .name("chair"),
                    .description("A wooden chair."),
                    .in(.room)
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
                let title = "Auto-Wiring Test Game"
                let abbreviatedTitle = "AutoWiringTest"
                let introduction = "Testing auto-wiring plugin scenarios..."
                let release = "1"
                let maximumScore = 100
                var player: Player {
                    Player(in: .livingRoom)
                }
            }
            """

        let scanner = Scanner(source: source)
        let gameData = scanner.process()

        #expect(gameData.gameBlueprintTypes.contains("AutoWiringTestGame"))
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
                    .in(.room)
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
                    .in(.room)
                )

                static let table = Item(
                    id: .table,
                    .name("table"),
                    .description("A wooden table."),
                    .in(.room)
                )
            }

            struct TestGame: GameBlueprint {
                let title = "Test Game"
                let abbreviatedTitle = "TestGame"
                let introduction = "A simple test game."
                let release = "1"
                let maximumScore = 100

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
                    .exits(
                        .south(.bar),
                        .west(.cloakroom)
                    ),
                    .inherentlyLit
                )

                static let cloakroom = Location(
                    id: .cloakroom,
                    .name("Cloakroom"),
                    .description("The walls of this small room were clearly once lined with hooks."),
                    .exits(
                        .east(.foyer)
                    ),
                    .inherentlyLit
                )

                static let bar = Location(
                    id: .bar,
                    .name("Bar"),
                    .description("You are in the bar. It is quite dark here."),
                    .exits(
                        .north(.foyer)
                    )
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
                    .in(.cloakroom),
                    .omitDescription,
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
        #expect(gameData.gameAreaTypes == ["RegularStruct"])
        #expect(gameData.gameBlueprintTypes.isEmpty)
    }

    @Test("Various ID contexts and patterns")
    func testVariousIDPatterns() {
        let source = """
            import GnustoEngine

            enum TestArea {
                static let forestPath = Location(
                    id: .forestPath,
                    .exits(
                        .north(.northOfHouse),
                        .south(.southOfHouse)
                    )
                )

                static let sword = Item(
                    id: .sword,
                    .in(.forestPath)
                )
            }
            """

        let scanner = Scanner(source: source)
        let gameData = scanner.process()

        // Should detect IDs in various contexts
        #expect(gameData.locationIDs.contains("forestPath"))
        #expect(gameData.itemIDs.contains("sword"))

        // Should NOT detect method names
        #expect(!gameData.locationIDs.contains("exits"))
        #expect(!gameData.locationIDs.contains("to"))
    }
}
