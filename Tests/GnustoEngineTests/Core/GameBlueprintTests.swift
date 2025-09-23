import Foundation
import GnustoTestSupport
import Testing

@testable import GnustoEngine

/// Comprehensive tests for the `GameBlueprint` protocol and its default implementations.
struct GameBlueprintTests {

    // MARK: - Test Implementations

    /// Basic GameBlueprint implementation with only required properties
    struct MinimalGameBlueprint: GameBlueprint {
        let title = "Test Game"
        let abbreviatedTitle = "TestGame"
        let introduction = "A simple test game for unit testing."
        let release = "Release 1 / Serial 240101"
        let maximumScore = 100
        let player = Player(in: "startRoom")
        var items = [Item]()
    }

    /// Complete GameBlueprint implementation with all properties customized
    struct CompleteGameBlueprint: GameBlueprint {
        let title = "The Complete Adventure"
        let abbreviatedTitle = "CompleteAdv"
        let introduction = "A comprehensive test of all GameBlueprint features."
        let release = "Release 2 / Serial 240102"
        let maximumScore = 500
        let player = Player(in: "entrance")

        let items = [
            Item(
                id: "testSword",
                .name("magic sword"),
                .description("A gleaming magical blade"),
                .isTakable,
                .in("armory")
            ),
            Item(
                id: "testShield",
                .name("steel shield"),
                .description("A sturdy steel shield"),
                .isTakable,
                .in("armory")
            ),
        ]

        let locations = [
            Location(
                id: "entrance",
                .name("Grand Entrance"),
                .description("A magnificent entrance hall"),
                .inherentlyLit
            ),
            Location(
                id: "armory",
                .name("Royal Armory"),
                .description("Weapons and armor line the walls"),
                .inherentlyLit
            ),
        ]

        let customActionHandlers: [ActionHandler] = [
            TestCustomActionHandler()
        ]

        let itemEventHandlers = [
            ItemID("testSword"): TestItemEventHandler().createHandler()
        ]

        let locationEventHandlers = [
            LocationID("entrance"): TestLocationEventHandler().createHandler()
        ]

        let fuses = [
            "testFuse": Fuse(
                initialTurns: 5,
                action: { _, _ in ActionResult("Fuse triggered!") }
            )
        ]

        let daemons = [
            DaemonID("testDaemon"): Daemon(
                action: { _, _ in ActionResult("Daemon running!") }
            )
        ]

        let itemComputers = [
            ItemID("testSword"): ItemComputer(for: ItemID("testSword")) {
                itemProperty(ItemPropertyID.description) { context in
                    return .string("A dynamically computed description")
                }
            }
        ]

        let locationComputers = [
            LocationID("entrance"): LocationComputer(for: LocationID("entrance")) {
                locationProperty(.description) { context in
                    return .string("A dynamically computed location description")
                }
            }
        ]

        let messenger = TestMessenger()
    }

    // MARK: - Basic Implementation Tests

    @Test("Minimal GameBlueprint provides required properties")
    func testMinimalGameBlueprint() throws {
        let blueprint = MinimalGameBlueprint()

        #expect(blueprint.title == "Test Game")
        #expect(blueprint.abbreviatedTitle == "TestGame")
        #expect(blueprint.introduction == "A simple test game for unit testing.")
        #expect(blueprint.release == "Release 1 / Serial 240101")
        #expect(blueprint.maximumScore == 100)
        #expect(blueprint.player.currentLocationID == "startRoom")
    }

    @Test("Minimal GameBlueprint uses default implementations")
    func testMinimalGameBlueprintDefaults() throws {
        let blueprint = MinimalGameBlueprint()

        #expect(blueprint.items.isEmpty)
        #expect(blueprint.locations.isEmpty)
        #expect(blueprint.customActionHandlers.isEmpty)
        #expect(blueprint.itemEventHandlers.isEmpty)
        #expect(blueprint.locationEventHandlers.isEmpty)
        #expect(blueprint.fuses.isEmpty)
        #expect(blueprint.daemons.isEmpty)
        #expect(blueprint.itemComputers.isEmpty)
        #expect(blueprint.locationComputers.isEmpty)
    }

    // MARK: - Complete Implementation Tests

    @Test("Complete GameBlueprint provides all custom properties")
    func testCompleteGameBlueprint() throws {
        let blueprint = CompleteGameBlueprint()

        #expect(blueprint.title == "The Complete Adventure")
        #expect(blueprint.abbreviatedTitle == "CompleteAdv")
        #expect(blueprint.introduction == "A comprehensive test of all GameBlueprint features.")
        #expect(blueprint.release == "Release 2 / Serial 240102")
        #expect(blueprint.maximumScore == 500)
        #expect(blueprint.player.currentLocationID == "entrance")
        #expect(blueprint.player.score == 0)
        #expect(blueprint.player.characterSheet == .default)
    }

    @Test("Complete GameBlueprint provides custom items")
    func testCompleteGameBlueprintItems() throws {
        let blueprint = CompleteGameBlueprint()

        #expect(blueprint.items.count == 2)

        let sword = blueprint.items.first { $0.id == "testSword" }
        let shield = blueprint.items.first { $0.id == "testShield" }

        #expect(sword != nil)
        #expect(shield != nil)
        #expect(sword?.id == "testSword")
        #expect(shield?.id == "testShield")
    }

    @Test("Complete GameBlueprint provides custom locations")
    func testCompleteGameBlueprintLocations() throws {
        let blueprint = CompleteGameBlueprint()

        #expect(blueprint.locations.count == 2)

        let entrance = blueprint.locations.first { $0.id == "entrance" }
        let armory = blueprint.locations.first { $0.id == "armory" }

        #expect(entrance != nil)
        #expect(armory != nil)
        #expect(entrance?.id == "entrance")
        #expect(armory?.id == "armory")
    }

    @Test("Complete GameBlueprint provides custom handlers")
    func testCompleteGameBlueprintHandlers() throws {
        let blueprint = CompleteGameBlueprint()

        #expect(blueprint.customActionHandlers.count == 1)
        #expect(blueprint.customActionHandlers.first is TestCustomActionHandler)

        #expect(blueprint.itemEventHandlers.count == 1)
        #expect(blueprint.itemEventHandlers[ItemID("testSword")] != nil)

        #expect(blueprint.locationEventHandlers.count == 1)
        #expect(blueprint.locationEventHandlers[LocationID("entrance")] != nil)
    }

    @Test("Complete GameBlueprint provides custom timed events")
    func testCompleteGameBlueprintTimedEvents() throws {
        let blueprint = CompleteGameBlueprint()

        #expect(blueprint.fuses.count == 1)
        #expect(blueprint.fuses["testFuse"] != nil)

        #expect(blueprint.daemons.count == 1)
        #expect(blueprint.daemons[DaemonID("testDaemon")] != nil)
    }

    @Test("Complete GameBlueprint provides custom computers")
    func testCompleteGameBlueprintComputers() throws {
        let blueprint = CompleteGameBlueprint()

        #expect(blueprint.itemComputers.count == 1)
        #expect(blueprint.itemComputers[ItemID("testSword")] != nil)

        #expect(blueprint.locationComputers.count == 1)
        #expect(blueprint.locationComputers[LocationID("entrance")] != nil)
    }

    // MARK: - Polymorphism Tests

    @Test("GameBlueprint protocol enables polymorphism")
    func testGameBlueprintPolymorphism() throws {
        let blueprints: [GameBlueprint] = [
            MinimalGameBlueprint(),
            CompleteGameBlueprint(),
        ]

        #expect(blueprints.count == 2)

        let minimal = blueprints[0]
        let complete = blueprints[1]

        #expect(minimal.title == "Test Game")
        #expect(complete.title == "The Complete Adventure")

        #expect(minimal.items.isEmpty)
        #expect(complete.items.count == 2)

        #expect(minimal.maximumScore == 100)
        #expect(complete.maximumScore == 500)
    }

    // MARK: - Default Override Tests

    @Test("Custom implementations properly override defaults")
    func testDefaultOverrides() throws {
        let blueprint = CompleteGameBlueprint()

        // Verify defaults are overridden
        #expect(!blueprint.items.isEmpty, "Items should be overridden")
        #expect(!blueprint.locations.isEmpty, "Locations should be overridden")
        #expect(
            !blueprint.customActionHandlers.isEmpty, "Custom action handlers should be overridden")
        #expect(!blueprint.itemEventHandlers.isEmpty, "Item event handlers should be overridden")
        #expect(
            !blueprint.locationEventHandlers.isEmpty, "Location event handlers should be overridden"
        )
        #expect(!blueprint.fuses.isEmpty, "Fuses should be overridden")
        #expect(!blueprint.daemons.isEmpty, "Daemons should be overridden")
        #expect(!blueprint.itemComputers.isEmpty, "Item computers should be overridden")
        #expect(!blueprint.locationComputers.isEmpty, "Location computers should be overridden")
    }

    // MARK: - Complex Scenario Tests

    @Test("GameBlueprint supports complex game structures")
    func testComplexGameStructure() throws {
        let blueprint = CompleteGameBlueprint()

        // Test that all components work together
        #expect(blueprint.player.currentLocationID == "entrance")

        let playerLocation = blueprint.locations.first {
            $0.id == blueprint.player.currentLocationID
        }
        #expect(playerLocation != nil, "Player should start in a valid location")

        let armoryItems = blueprint.items.compactMap { item -> Item? in
            // Check if item is in armory location
            if case .parentEntity(.location(let locationID)) = item.properties[.parentEntity] {
                return locationID == "armory" ? item : nil
            }
            return nil
        }

        #expect(armoryItems.count == 2, "Armory should contain both test items")

        // Test that event handlers are properly associated
        let swordHandler = blueprint.itemEventHandlers[ItemID("testSword")]
        let entranceHandler = blueprint.locationEventHandlers[LocationID("entrance")]

        #expect(swordHandler != nil, "Sword should have an event handler")
        #expect(entranceHandler != nil, "Entrance should have an event handler")
    }

    @Test("GameBlueprint computer handlers work correctly")
    func testComputerHandlers() async throws {
        let blueprint = CompleteGameBlueprint()
        let (engine, mockIO) = await GameEngine.test(blueprint: blueprint)
        let gameState = await engine.gameState

        // Test item computer
        let itemComputer = blueprint.itemComputers[ItemID("testSword")]
        #expect(itemComputer != nil)

        let computedDescription = await itemComputer?.compute(
            ItemComputeContext(
                propertyID: .description,
                item: gameState.items[ItemID("testSword")]!,
                engine: GameEngine(blueprint: blueprint, ioHandler: mockIO)
            )
        )
        #expect(computedDescription == .string("A dynamically computed description"))

        let nonComputedProperty = await itemComputer?.compute(
            ItemComputeContext(
                propertyID: .name,
                item: gameState.items[ItemID("testSword")]!,
                engine: engine
            )
        )
        #expect(nonComputedProperty == nil)

        // Test location computer
        let locationComputer = blueprint.locationComputers[LocationID("entrance")]
        #expect(locationComputer != nil)

        let computedLocationDescription = await locationComputer?.compute(
            LocationComputeContext(
                propertyID: .description,
                location: gameState.locations[LocationID("entrance")]!,
                engine: GameEngine(blueprint: blueprint, ioHandler: mockIO)
            )
        )
        #expect(
            computedLocationDescription == .string("A dynamically computed location description")
        )

        let nonComputedLocationProperty = await locationComputer?.compute(
            LocationComputeContext(
                propertyID: .name,
                location: gameState.locations[LocationID("entrance")]!,
                engine: GameEngine(blueprint: blueprint, ioHandler: mockIO)
            )
        )
        #expect(nonComputedLocationProperty == nil)
    }

    // MARK: - Edge Cases

    @Test("GameBlueprint handles empty collections gracefully")
    func testEmptyCollections() throws {
        let blueprint = MinimalGameBlueprint()

        // All collections should be empty and non-nil
        #expect(blueprint.items.count == 0)
        #expect(blueprint.locations.count == 0)
        #expect(blueprint.customActionHandlers.count == 0)
        #expect(blueprint.itemEventHandlers.count == 0)
        #expect(blueprint.locationEventHandlers.count == 0)
        #expect(blueprint.fuses.count == 0)
        #expect(blueprint.daemons.count == 0)
        #expect(blueprint.itemComputers.count == 0)
        #expect(blueprint.locationComputers.count == 0)
    }

    @Test("GameBlueprint properties are accessible")
    func testPropertyAccess() throws {
        let blueprint = CompleteGameBlueprint()

        // Test that all properties are accessible without throwing
        _ = blueprint.title
        _ = blueprint.abbreviatedTitle
        _ = blueprint.introduction
        _ = blueprint.release
        _ = blueprint.maximumScore
        _ = blueprint.player
        _ = blueprint.items
        _ = blueprint.locations
        _ = blueprint.customActionHandlers
        _ = blueprint.itemEventHandlers
        _ = blueprint.locationEventHandlers
        _ = blueprint.fuses
        _ = blueprint.daemons
        _ = blueprint.itemComputers
        _ = blueprint.locationComputers
        _ = blueprint.messenger
    }
}

// MARK: - Test Helper Classes

/// Test ActionHandler for testing custom action handlers
struct TestCustomActionHandler: ActionHandler {
    let synonyms: [Verb] = []
    let syntax: [SyntaxRule] = [.match(.test)]
    let requiresLight: Bool = false

    func process(context: ActionContext) async throws -> ActionResult {
        ActionResult("Test action executed")
    }
}

/// Test ItemEventHandler for testing item event handlers
struct TestItemEventHandler {
    func createHandler() -> ItemEventHandler {
        ItemEventHandler { engine, event in
            ActionResult("Test item event handled")
        }
    }
}

/// Test LocationEventHandler for testing location event handlers
struct TestLocationEventHandler {
    func createHandler() -> LocationEventHandler {
        LocationEventHandler { engine, event in
            ActionResult("Test location event handled")
        }
    }
}

/// Test MessageProvider for testing custom message providers
class TestMessenger: StandardMessenger, @unchecked Sendable {
    override func anySuchThing() -> String {
        "Custom: Cannot see any such thing in these parts."
    }
}

// MARK: - Test Helper Extensions

extension Verb {
    fileprivate static let test = Verb("test")
}
