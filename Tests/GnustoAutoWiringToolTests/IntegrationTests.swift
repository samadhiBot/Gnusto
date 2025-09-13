import Testing

@testable import GnustoAutoWiringTool

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
                    .in(.room)
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
                let title = "Cloak of Darkness"
                let abbreviatedTitle = "Cloak"
                let introduction = "A brief test."
                let release = "1"
                let maximumScore = 2
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
