import Testing
@testable import GnustoEngine

/// Tests for the dynamic property system (registry, engine helpers, state integration).
struct DynamicPropertyTests {
    /*
    // Helper to create a basic engine setup for testing
    @MainActor
    private func createTestEngine(
        initialItemValues: [AttributeID: StateValue] = [:],
        initialLocationValues: [AttributeID: StateValue] = [:],
        dynamicRegistry: DynamicAttributeRegistry = DynamicAttributeRegistry(),
        ioHandler: IOHandler
    ) -> GameEngine {
        var testItem = Item(
            id: "testItem",
            name: "widget",
//            attributes: initialItemValues, // Set manually after init if needed
            parent: .location("testLocation")
        )
        testItem.attributes = initialItemValues // Assign initial values

        var testLocation = Location(
            id: "testLocation",
            name: "Test Chamber",
//            attributes: initialLocationValues // Set manually after init if needed
        )
        testLocation.attributes = initialLocationValues // Assign initial values

        let blueprint = MinimalGame(
            locations: [testLocation],
            items: [testItem],
            dynamicAttributeRegistry: dynamicRegistry
        )

        return await GameEngine(
            game: blueprint,
            parser: MockParser(),
            ioHandler: ioHandler
        )
*/

    // MARK: - Basic Get/Set Tests

    @Test("Get/Set Simple Dynamic Item Value")
    @MainActor
    func testGetSetSimpleItemValue() async throws {
        let testItem = Item(
            id: "testItem",
            name: "widget",
            parent: .location("testLocation"),
            attributes: ["simpleProp": StateValue.int(10)]
        )
        var testLocation = Location(
            id: "testLocation",
            name: "Test Chamber",
        )
        let game = MinimalGame(
            locations: [testLocation],
            items: [testItem],
            dynamicAttributeRegistry: DynamicAttributeRegistry()
        )
        let mockIO = await MockIOHandler()
        let engine = await GameEngine(
            game: game,
            parser: MockParser(),
            ioHandler: mockIO
        )

        // Get initial value
        let initialValue: Int = try await engine.fetch("testItem", "simpleProp")
        #expect(initialValue == 10)

        // Set new value
        try await engine.setDynamicItemValue(itemID: "testItem", key: "simpleProp", newValue: StateValue.int(20))

        // Verify new value in GameState
        let updatedItem = await engine.gameState.items["testItem"]
        #expect(updatedItem?.attributes["simpleProp"] == StateValue.int(20))

        // Verify getting the value again works
        let finalValue: Int = try await engine.fetch("testItem", "simpleProp")
        #expect(finalValue == 20)
    }

    // MARK: - Validation Tests

//    @Test("Set Validated Item Value - Success")
//    @MainActor
//    func testSetValidatedItemValueSuccess() async throws {
//        var registry = DynamicAttributeRegistry()
//        registry.registerItemValidate(key: "validatedProp") { item, newValue in
//            // Example: Only allow positive integers
//            guard case .int(let intValue) = newValue else { return false }
//            return intValue > 0
//        }
//
//        let ioHandler = await MockIOHandler()
//        let engine = createTestEngine(dynamicRegistry: registry, ioHandler: ioHandler)
//
//        // Set a valid value
//        try await engine.setDynamicItemValue(itemID: "testItem", key: "validatedProp", newValue: StateValue.int(5))
//
//        // Verify value in GameState
//        let updatedItem = await engine.gameState.items["testItem"]
//        #expect(updatedItem?.attributes["validatedProp"] == StateValue.int(5))
//    }
//
//    @Test("Set Validated Item Value - Failure")
//    @MainActor
//    func testSetValidatedItemValueFailure() async throws {
//        var registry = DynamicAttributeRegistry()
//        registry.registerItemValidate(key: "validatedProp") { item, newValue in
//             guard case .int(let intValue) = newValue else { return false }
//             return intValue > 0
//        }
//
//        let ioHandler = await MockIOHandler()
//        let engine = createTestEngine(
//            initialItemValues: ["validatedProp": StateValue.int(1)],
//            dynamicRegistry: registry,
//            ioHandler: ioHandler
//        )
//
//        // Attempt to set an invalid value (zero)
//        await #expect(throws: ActionError.self) {
//             try await engine.setDynamicItemValue(itemID: "testItem", key: "validatedProp", newValue: StateValue.int(0))
//        }
//
//        // Verify value in GameState hasn't changed
//        let item = await engine.gameState.items["testItem"]
//        #expect(item?.attributes["validatedProp"] == StateValue.int(1))
//
//        // Attempt to set wrong type
//         await #expect(throws: ActionError.self) {
//             try await engine.setDynamicItemValue(itemID: "testItem", key: "validatedProp", newValue: StateValue.string("invalid"))
//        }
//         #expect(item?.attributes["validatedProp"] == StateValue.int(1))
//    }
//
//    // TODO: Add tests for Location dynamic properties
//    // TODO: Add tests for interaction between compute and validate handlers?
//    // TODO: Add tests checking StateChange history for dynamic values.
}
