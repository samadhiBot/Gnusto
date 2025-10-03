import Testing

@testable import GnustoAutoWiringTool

@Suite("Scanner Tests")
struct ScannerTests {

    @Test("GameDataCollector detects LocationIDs from enum area")
    func testLocationIDDetectionEnum() {
        let source = """
            import GnustoEngine

            enum EnumArea {
                static let room = Location(.room)
                    .name("Room")
                    .description("A simple room.")
                    .inherentlyLit
                )

                static let chair = Item(.chair)
                    .name("chair")
                    .description("A wooden chair.")
                    .in(.room)
                )
            }
            """

        let scanner = Scanner(source: source, fileName: "test.swift")
        let gameData = scanner.process()

        #expect(gameData.locationIDs.keys.contains("room"))
        #expect(gameData.itemIDs.keys.contains("chair"))
        #expect(gameData.gameAreaTypes.contains("EnumArea"))
    }

    @Test("GameDataCollector detects LocationIDs from struct area static properties")
    func testLocationIDDetectionStructStaticProperties() {
        let source = """
            import GnustoEngine

            struct EnumArea {
                static let room = Location(.room)
                    .name("Room")
                    .description("A simple room.")
                    .inherentlyLit
                )

                static let chair = Item(.chair)
                    .name("chair")
                    .description("A wooden chair.")
                    .in(.room)
                )
            }
            """

        let scanner = Scanner(source: source, fileName: "test.swift")
        let gameData = scanner.process()

        #expect(gameData.locationIDs.keys.contains("room"))
        #expect(gameData.itemIDs.keys.contains("chair"))
        #expect(gameData.gameAreaTypes.contains("EnumArea"))
    }

    @Test("GameDataCollector detects LocationIDs from struct area instance properties")
    func testLocationIDDetectionStructInstanceProperties() {
        let source = """
            import GnustoEngine

            struct EnumArea {
                let room = Location(.room)
                    .name("Room")
                    .description("A simple room.")
                    .inherentlyLit
                )

                let chair = Item(.chair)
                    .name("chair")
                    .description("A wooden chair.")
                    .in(.room)
                )
            }
            """

        let scanner = Scanner(source: source, fileName: "test.swift")
        let gameData = scanner.process()

        #expect(gameData.locationIDs.keys.contains("room"))
        #expect(gameData.itemIDs.keys.contains("chair"))
        #expect(gameData.gameAreaTypes.contains("EnumArea"))
    }

    @Test("GameDataCollector detects LocationIDs from struct area mixed properties")
    func testLocationIDDetectionStructMixedProperties() {
        let source = """
            import GnustoEngine

            struct EnumArea {
                static let room = Location(.room)
                    .name("Room")
                    .description("A simple room.")
                    .inherentlyLit
                )

                let chair = Item(.chair)
                    .name("chair")
                    .description("A wooden chair.")
                    .in(.room)
                )
            }
            """

        let scanner = Scanner(source: source, fileName: "test.swift")
        let gameData = scanner.process()

        #expect(gameData.locationIDs.keys.contains("room"))
        #expect(gameData.itemIDs.keys.contains("chair"))
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

        let scanner = Scanner(source: source, fileName: "test.swift")
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

        let scanner = Scanner(source: source, fileName: "test.swift")
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
                static let room = Location(.room)
                    .name("Test Room")
                    .description("A simple test room.")
                    .inherentlyLit
                )

                static let chair = Item(.chair)
                    .name("chair")
                    .description("A wooden chair.")
                    .in(.room)
                )
            }
            """

        let scanner = Scanner(source: source, fileName: "test.swift")
        let gameData = scanner.process()

        // Should detect actual IDs
        #expect(gameData.locationIDs.keys.contains("room"))
        #expect(gameData.itemIDs.keys.contains("chair"))
        #expect(gameData.gameAreaTypes.contains("TestArea"))

        // Should NOT detect method calls as IDs
        #expect(!gameData.locationIDs.keys.contains("name"))
        #expect(!gameData.locationIDs.keys.contains("description"))
        #expect(!gameData.locationIDs.keys.contains("location"))
        #expect(!gameData.itemIDs.keys.contains("in"))
    }

    @Test("Complex multi-item scenario detection")
    func testComplexMultiItemDetection() {
        let source = """
            import GnustoEngine

            enum TestArea {
                static let room = Location(.room)
                    .name("Test Room")
                    .description("A simple test room.")
                    .inherentlyLit
                )

                static let chair = Item(.chair)
                    .name("chair")
                    .description("A wooden chair.")
                    .in(.room)
                )

                static let table = Item(.table)
                    .name("table")
                    .description("A wooden table.")
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

        let scanner = Scanner(source: source, fileName: "test.swift")
        let gameData = scanner.process()

        // Should detect all IDs
        #expect(gameData.locationIDs.keys.contains("room"))
        #expect(gameData.itemIDs.keys.contains("chair"))
        #expect(gameData.itemIDs.keys.contains("table"))
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
                static let foyer = Location(.foyer)
                    .name("Foyer of the Opera House")
                    .description("You are standing in a spacious hall.")
                                    .south(.bar),
                        .west(.cloakroom)
                    ),
                    .inherentlyLit
                )

                static let cloakroom = Location(.cloakroom)
                    .name("Cloakroom")
                    .description("The walls of this small room were clearly once lined with hooks.")
                                    .east(.foyer)
                    ),
                    .inherentlyLit
                )

                static let bar = Location(.bar)
                    .name("Bar")
                    .description("You are in the bar. It is quite dark here.")
                                    .north(.foyer)
                    )
                )

                static let cloak = Item(.cloak)
                    .name("velvet cloak")
                    .description("A handsome cloak.")
                    .in(.player)
                    .isWearable
                )

                static let hook = Item(.hook)
                    .adjectives("small", "brass")
                    .in(.cloakroom)
                    .omitDescription
                    .isSurface
                )
            }
            """

        let scanner = Scanner(source: source, fileName: "test.swift")
        let gameData = scanner.process()

        // Should detect all expected IDs
        #expect(gameData.locationIDs.keys.contains("foyer"))
        #expect(gameData.locationIDs.keys.contains("cloakroom"))
        #expect(gameData.locationIDs.keys.contains("bar"))
        #expect(gameData.itemIDs.keys.contains("cloak"))
        #expect(gameData.itemIDs.keys.contains("hook"))
        #expect(gameData.gameAreaTypes.contains("OperaHouse"))

        // Should NOT detect method calls
        #expect(!gameData.locationIDs.keys.contains("to"))
        #expect(!gameData.itemIDs.keys.contains("adjectives"))
        #expect(!gameData.itemIDs.keys.contains("player"))
    }

    @Test("Edge case: Empty game area")
    func testEmptyGameArea() {
        let source = """
            import GnustoEngine

            enum EmptyArea {
                // No content
            }
            """

        let scanner = Scanner(source: source, fileName: "test.swift")
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

        let scanner = Scanner(source: source, fileName: "test.swift")
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
                static let forestPath = Location(.forestPath)
                                    .north(.northOfHouse),
                        .south(.southOfHouse)
                    )
                )

                static let sword = Item(.sword)
                    .in(.forestPath)
                )
            }
            """

        let scanner = Scanner(source: source, fileName: "test.swift")
        let gameData = scanner.process()

        // Should detect IDs in various contexts
        #expect(gameData.locationIDs.keys.contains("forestPath"))
        #expect(gameData.itemIDs.keys.contains("sword"))

        // Should NOT detect method names
        #expect(!gameData.locationIDs.keys.contains("exits"))
        #expect(!gameData.locationIDs.keys.contains("to"))
    }

    @Test("Unlabeled initializer syntax detection")
    func testUnlabeledInitializerSyntax() {
        let source = """
            import GnustoEngine

            enum TestArea {
                // Locations - Old style with labeled parameter
                static let room1 = Location(.room1)
                    .name("Room One")
                    .inherentlyLit

                // Locations - New chained style with labeled parameter
                static let room2 = Location(id: .room2)
                    .name("Room Two")
                    .inherentlyLit

                // Locations - New chained style with UNLABELED parameter
                static let room3 = Location(.room3)
                    .name("Room Three")
                    .inherentlyLit

                // Locations - Unlabeled with full properties
                static let room4 = Location(.room4)
                    .name("Room Four")
                    .inherentlyLit)

                // Items - Labeled parameter
                static let sword = Item(id: .sword)
                    .name("sword")
                    .isTakable

                // Items - Unlabeled parameter
                static let shield = Item(.shield)
                    .name("shield")
                    .isTakable
            }
            """

        let scanner = Scanner(source: source, fileName: "test.swift")
        let gameData = scanner.process()

        // Should detect all location IDs regardless of syntax
        #expect(gameData.locationIDs.keys.contains("room1"))
        #expect(gameData.locationIDs.keys.contains("room2"))
        #expect(gameData.locationIDs.keys.contains("room3"))
        #expect(gameData.locationIDs.keys.contains("room4"))

        // Should detect all item IDs regardless of syntax
        #expect(gameData.itemIDs.keys.contains("sword"))
        #expect(gameData.itemIDs.keys.contains("shield"))

        #expect(gameData.gameAreaTypes.contains("TestArea"))
    }
}
