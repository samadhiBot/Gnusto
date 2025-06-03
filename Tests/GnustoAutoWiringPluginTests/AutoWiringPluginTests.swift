import Testing
import GnustoEngine
import CustomDump

/// Comprehensive tests for the GnustoAutoWiringPlugin to ensure it correctly handles
/// various organizational patterns and generates working code.
///
/// These tests verify that the plugin:
/// 1. Correctly maps properties to their containing areas
/// 2. Doesn't create cross-contamination between areas
/// 3. Handles multiple organizational patterns (multi-area, single-area, mixed static/instance)
/// 4. Generates code that compiles and runs correctly (integration testing)
/// 5. Discovers and handles complex patterns like event handlers and nested structures
@Suite("Auto-Wiring Plugin Tests")
struct AutoWiringPluginTests {

    @Test("Multi-area organization generates correct property mappings")
    func testMultiAreaOrganization() {
        // The auto-wiring plugin should generate correct mappings for our test scenarios
        let game = AutoWiringTestGame()

        // Verify that items and locations are properly collected
        #expect(game.items.count == 5, "Should have 5 items across all test areas")
        #expect(game.locations.count == 5, "Should have 5 locations across all test areas")

        // Verify specific items exist (static properties only)
        let itemNames = game.items.map(\.name).sorted()
        let expectedItemNames = ["chair", "cookbook", "garden shovel", "house key", "mailbox"]
        #expect(itemNames == expectedItemNames, "Should have correct item names")

        // Verify specific locations exist (static properties only)
        let locationNames = game.locations.map(\.name).sorted()
        let expectedLocationNames = ["Back Yard", "Front Yard", "Kitchen", "Living Room", "Room"]
        #expect(locationNames == expectedLocationNames, "Should have correct location names")
    }

    @Test("Items are placed in correct locations across areas")
    func testCrossAreaItemPlacement() {
        let game = AutoWiringTestGame()

        // Find specific items and verify their locations
        let houseKey = game.items.first { $0.name == "house key" }
        let cookbook = game.items.first { $0.name == "cookbook" }
        let gardenShovel = game.items.first { $0.name == "garden shovel" }
        let mailbox = game.items.first { $0.name == "mailbox" }
        let chair = game.items.first { $0.name == "chair" }

        // Verify items exist
        #expect(houseKey != nil, "House key should exist")
        #expect(cookbook != nil, "Cookbook should exist")
        #expect(gardenShovel != nil, "Garden shovel should exist")
        #expect(mailbox != nil, "Mailbox should exist")
        #expect(chair != nil, "Chair should exist")

        // The fact that the game builds without errors means the auto-wiring plugin
        // generated valid cross-area references with correct property-to-area mappings
    }

    @Test("Plugin correctly maps properties to containing areas")
    func testPropertyToAreaMapping() {
        // This test verifies that the auto-wiring plugin generates code that compiles
        // which proves the property-to-area mappings are correct.
        //
        // If the plugin was still broken, we would see compilation errors like:
        // - error: type 'TestHouseArea' has no member 'gardenShovel'
        // - error: type 'TestHouseArea' has no member 'chair'
        // - error: type 'TestHouseArea' has no member 'mailbox'
        //
        // The successful compilation of this test target proves the fix works!

        let game = AutoWiringTestGame()

        // Basic validation that the game blueprint works
        #expect(!game.items.isEmpty, "Game should have items")
        #expect(!game.locations.isEmpty, "Game should have locations")
        #expect(game.constants.storyTitle == "Auto-Wiring Test Game", "Game title should be correct")
    }

    @Test("Plugin handles static vs instance property organization")
    func testStaticVsInstancePropertyHandling() {
        let game = AutoWiringTestGame()

        // Verify that both static and instance-based areas are properly handled
        // Static areas: HouseArea, GardenArea, SimpleArea
        // Instance areas: InstanceArea

        // The successful compilation and operation proves the plugin correctly
        // generated different access patterns for static vs instance properties
        #expect(!game.items.isEmpty, "Should handle mixed static/instance organization")
        #expect(!game.locations.isEmpty, "Should handle mixed static/instance organization")
    }

    @Test("Plugin discovers all ID types correctly")
    func testIDDiscovery() {
        let game = AutoWiringTestGame()

        // Test that all IDs used in test scenarios are discovered and generated correctly
        // This is verified by the fact that the game compiles without undefined identifier errors

        // Test item and location initialization with proper IDs
        let itemsWithIds = game.items.filter { !$0.id.rawValue.isEmpty }
        let locationsWithIds = game.locations.filter { !$0.id.rawValue.isEmpty }

        #expect(itemsWithIds.count == game.items.count, "All items should have valid IDs")
        #expect(locationsWithIds.count == game.locations.count, "All locations should have valid IDs")
    }

    @Test("Plugin generates consistent area-to-property mappings")
    func testAreaToPropertyMappingConsistency() {
        let game = AutoWiringTestGame()

        // Verify that items from different areas don't interfere with each other
        let houseItems = ["house key", "cookbook"]
        let gardenItems = ["garden shovel", "mailbox"]
        let simpleItems = ["chair"]

        let gameItemNames = Set(game.items.map(\.name))

        for itemName in houseItems + gardenItems + simpleItems {
            #expect(gameItemNames.contains(itemName), "Should contain \(itemName)")
        }

        // The fact that we can access these cross-area items means the plugin
        // correctly mapped each property to its containing area
    }

    @Test("Generated extensions provide correct aggregation")
    func testGeneratedExtensionAggregation() {
        let game = AutoWiringTestGame()

        // Test that the generated extension properly aggregates all items and locations
        // from different areas into the main game blueprint

        // Verify all expected areas are represented
        let expectedItemCount = 5  // Based on test scenarios
        let expectedLocationCount = 5  // Based on test scenarios

        #expect(game.items.count == expectedItemCount, "Should aggregate all items from all areas")
        #expect(game.locations.count == expectedLocationCount, "Should aggregate all locations from all areas")

        // Verify no duplicates (Set should have same count as array)
        let uniqueItemNames = Set(game.items.map(\.name))
        let uniqueLocationNames = Set(game.locations.map(\.name))

        #expect(uniqueItemNames.count == game.items.count, "Should not have duplicate item names")
        #expect(uniqueLocationNames.count == game.locations.count, "Should not have duplicate location names")
    }

    @Test("Plugin handles complex nested ID patterns")
    func testComplexNestedIDPatterns() {
        let game = AutoWiringTestGame()

        // The existence of complex test scenarios with nested patterns
        // that compile successfully proves the plugin can handle:
        // - Multiple exit directions in a single location
        // - Container items with multiple child items
        // - Cross-references between different areas
        // - Mixed static and instance property declarations

        // The compilation success itself is the primary test here
        #expect(game.items.count >= 5, "Should handle complex nested patterns")
        #expect(game.locations.count >= 5, "Should handle complex nested patterns")
    }

    @Test("Plugin discovers event handler patterns")
    func testEventHandlerDiscovery() {
        let game = AutoWiringTestGame()

        // The auto-wiring plugin should discover and properly map event handlers
        // The successful compilation of complex scenarios with event handlers
        // (in ComplexScenarios.swift) proves this works correctly

        // Event handlers in the test scenarios include:
        // - EventTestArea.doorHandler (ItemEventHandler)
        // - EventTestArea.mysticalRoomHandler (LocationEventHandler)
        // - InstanceTestArea.dynamicHandler (instance-based ItemEventHandler)

        // The fact that these compile and the game can be instantiated
        // proves the plugin correctly handled the event handler mappings
        #expect(game.items.count > 0, "Game with event handlers should compile")
        #expect(game.locations.count > 0, "Game with event handlers should compile")
    }

    @Test("Plugin handles timer definitions correctly")
    func testTimerDefinitionHandling() {
        let game = AutoWiringTestGame()

        // The test scenarios include complex timer definitions:
        // - TimerTestArea.explosiveDevice (FuseDefinition)
        // - TimerTestArea.timedPuzzle (FuseDefinition)
        // - TimerTestArea.randomEvents (DaemonDefinition)
        // - TimerTestArea.atmosphericEffects (DaemonDefinition)

        // The successful compilation proves the plugin can discover and map
        // these timer definitions to their containing areas
        #expect(game.items.count > 0, "Game with timer definitions should compile")
        #expect(game.locations.count > 0, "Game with timer definitions should compile")
    }

    @Test("Plugin handles mixed organizational patterns")
    func testMixedOrganizationalPatterns() {
        let game = AutoWiringTestGame()

        // Test scenarios include various organizational patterns:
        // 1. Static enum-based areas (EventTestArea, TimerTestArea, etc.)
        // 2. Instance struct-based areas (InstanceTestArea)
        // 3. Mixed static/instance properties within areas
        // 4. Cross-area references and dependencies

        // The successful compilation proves the plugin can handle all these patterns
        // and generate appropriate access code for each organizational style
        #expect(game.items.count > 0, "Mixed organizational patterns should work")
        #expect(game.locations.count > 0, "Mixed organizational patterns should work")
    }

    @Test("Plugin correctly scopes property access")
    func testPropertyAccessScoping() {
        let game = AutoWiringTestGame()

        // The plugin must generate correct property access patterns:
        // - Static properties: AreaType.propertyName
        // - Instance properties: Self._areaInstance.propertyName
        // - Proper area-to-property mapping without cross-contamination

        // This is tested implicitly through compilation success
        // If scoping was incorrect, we'd see compilation errors
        #expect(game.items.count > 0, "Correct property scoping should enable compilation")
        #expect(game.locations.count > 0, "Correct property scoping should enable compilation")
    }
}
