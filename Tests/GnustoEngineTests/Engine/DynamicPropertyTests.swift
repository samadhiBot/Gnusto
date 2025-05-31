import Testing
@testable import GnustoEngine

/// Tests for the dynamic property system (registry, engine helpers, state integration).
struct DynamicPropertyTests {

    // MARK: - Basic Get/Set Tests

    @Test("Get/Set Simple Dynamic Item Value")
    func testGetSetSimpleItemValue() async throws {
        let testItem = Item(
            id: "testItem",
            .name("widget"),
            .in(.location("testLocation")),
            .description("A test widget")
        )

        let testLocation = Location(
            id: "testLocation",
            .name("Test Chamber"),
            .description("A dark, dark room.")
        )

        let game = MinimalGame(
            locations: [testLocation],
            items: [testItem],
            dynamicAttributeRegistry: DynamicAttributeRegistry()
        )
        let mockIO = await MockIOHandler()
        let engine = await GameEngine(
            blueprint: game,
            parser: MockParser(),
            ioHandler: mockIO
        )

        // Set initial value through StateChange builder
        let item = try await engine.item("testItem")
        if let change = await engine.setAttribute(.init("simpleProp"), on: item, to: .int(10)) {
            try await engine.apply(change)
        }

        // Get initial value
        let initialValue: Int = try await engine.attribute("simpleProp", of: "testItem")
        #expect(initialValue == 10)

        // Set new value
        let updatedItem = try await engine.item("testItem")
        if let change = await engine.setAttribute(.init("simpleProp"), on: updatedItem, to: .int(20)) {
            try await engine.apply(change)
        }

        // Verify new value in GameState
        let finalItem = await engine.gameState.items["testItem"]
        #expect(finalItem?.attributes["simpleProp"] == StateValue.int(20))

        // Verify getting the value again works
        let finalValue: Int = try await engine.attribute("simpleProp", of: "testItem")
        #expect(finalValue == 20)
    }

    // MARK: - Validation Tests

    @Test("Set Validated Item Value - Success")
    func testSetValidatedItemValueSuccess() async throws {
        var registry = DynamicAttributeRegistry()
        registry.registerItemValidate(itemID: "testItem", attributeID: "validatedProp") { item, newValue in
            // Example: Only allow positive integers
            guard case .int(let intValue) = newValue else { return false }
            return intValue > 0
        }

        let testItem = Item(
            id: "testItem",
            .name("widget"),
            .in(.location("testLocation"))
        )

        let testLocation = Location(
            id: "testLocation",
            .name("Test Chamber")
        )

        let game = MinimalGame(
            locations: [testLocation],
            items: [testItem],
            dynamicAttributeRegistry: registry
        )
        let mockIO = await MockIOHandler()
        let engine = await GameEngine(
            blueprint: game,
            parser: MockParser(),
            ioHandler: mockIO
        )

        // Set a valid value using StateChange builder
        let item = try await engine.item("testItem")
        if let change = await engine.setAttribute(.init("validatedProp"), on: item, to: .int(5)) {
            try await engine.apply(change)
        }

        // Verify value in GameState
        let updatedItem = await engine.gameState.items["testItem"]
        #expect(updatedItem?.attributes["validatedProp"] == StateValue.int(5))
    }

    @Test("Set Validated Item Value - Failure")
    func testSetValidatedItemValueFailure() async throws {
        var registry = DynamicAttributeRegistry()
        registry.registerItemValidate(itemID: "testItem", attributeID: "validatedProp") { item, newValue in
            guard case .int(let intValue) = newValue else { return false }
            return intValue > 0
        }

        let testItem = Item(
            id: "testItem",
            .name("widget"),
            .in(.location("testLocation"))
        )

        let testLocation = Location(
            id: "testLocation",
            .name("Test Chamber")
        )

        let game = MinimalGame(
            locations: [testLocation],
            items: [testItem],
            dynamicAttributeRegistry: registry
        )
        let mockIO = await MockIOHandler()
        let engine = await GameEngine(
            blueprint: game,
            parser: MockParser(),
            ioHandler: mockIO
        )

        // Set initial valid value
        let item = try await engine.item("testItem")
        if let change = await engine.setAttribute(.init("validatedProp"), on: item, to: .int(1)) {
            try await engine.apply(change)
        }

        // Attempt to set an invalid value (zero)
        await #expect(throws: ActionResponse.self) {
            let currentItem = try await engine.item("testItem")
            if let change = await engine.setAttribute(.init("validatedProp"), on: currentItem, to: .int(0)) {
                try await engine.apply(change)
            }
        }

        // Verify value in GameState hasn't changed
        let itemAfterFailure = await engine.gameState.items["testItem"]
        #expect(itemAfterFailure?.attributes["validatedProp"] == StateValue.int(1))

        // Attempt to set wrong type
        await #expect(throws: ActionResponse.self) {
            let currentItem = try await engine.item("testItem")
            if let change = await engine.setAttribute(.init("validatedProp"), on: currentItem, to: .string("invalid")) {
                try await engine.apply(change)
            }
        }
        #expect(itemAfterFailure?.attributes["validatedProp"] == StateValue.int(1))
    }

    @Test("Set Validated Location Value - Success")
    func testSetValidatedLocationValueSuccess() async throws {
        var registry = DynamicAttributeRegistry()
        registry.registerLocationValidate(locationID: "testLocation", attributeID: "lightLevel") { location, newValue in
            // Example: Only allow light levels between 0 and 10
            guard case .int(let lightLevel) = newValue else { return false }
            return lightLevel >= 0 && lightLevel <= 10
        }

        let testLocation = Location(
            id: "testLocation",
            .name("Test Chamber")
        )

        let game = MinimalGame(
            locations: [testLocation],
            dynamicAttributeRegistry: registry
        )
        let mockIO = await MockIOHandler()
        let engine = await GameEngine(
            blueprint: game,
            parser: MockParser(),
            ioHandler: mockIO
        )

        // Set a valid value using StateChange builder
        let location = try await engine.location("testLocation")
        if let change = await engine.setAttribute(.init("lightLevel"), on: location, to: .int(5)) {
            try await engine.apply(change)
        }

        // Verify value in GameState
        let updatedLocation = await engine.gameState.locations["testLocation"]
        #expect(updatedLocation?.attributes["lightLevel"] == StateValue.int(5))
    }

    @Test("Set Validated Location Value - Failure")
    func testSetValidatedLocationValueFailure() async throws {
        var registry = DynamicAttributeRegistry()
        registry.registerLocationValidate(locationID: "testLocation", attributeID: "lightLevel") { location, newValue in
            guard case .int(let lightLevel) = newValue else { return false }
            return lightLevel >= 0 && lightLevel <= 10
        }

        let testLocation = Location(
            id: "testLocation",
            .name("Test Chamber")
        )

        let game = MinimalGame(
            locations: [testLocation],
            dynamicAttributeRegistry: registry
        )
        let mockIO = await MockIOHandler()
        let engine = await GameEngine(
            blueprint: game,
            parser: MockParser(),
            ioHandler: mockIO
        )

        // Attempt to set an invalid value (too high)
        await #expect(throws: ActionResponse.self) {
            let location = try await engine.location("testLocation")
            if let change = await engine.setAttribute(.init("lightLevel"), on: location, to: .int(15)) {
                try await engine.apply(change)
            }
        }

        // Verify value in GameState hasn't changed (should be nil since we never set a valid value)
        let location = await engine.gameState.locations["testLocation"]
        #expect(location?.attributes["lightLevel"] == nil)
    }

    // MARK: - Convenience Method Tests

    @Test("Set Item Flag")
    func testSetItemFlag() async throws {
        let testItem = Item(
            id: "testItem",
            .name("widget"),
            .in(.location("testLocation"))
        )

        let testLocation = Location(
            id: "testLocation",
            .name("Test Chamber")
        )

        let game = MinimalGame(
            locations: [testLocation],
            items: [testItem],
            dynamicAttributeRegistry: DynamicAttributeRegistry()
        )
        let mockIO = await MockIOHandler()
        let engine = await GameEngine(
            blueprint: game,
            parser: MockParser(),
            ioHandler: mockIO
        )

        // Set flag to true using StateChange builder
        let item = try await engine.item("testItem")
        if let change = await engine.setAttribute("isOpen", on: item, to: true) {
            try await engine.apply(change)
        }

        let itemAfterSet = await engine.gameState.items["testItem"]
        #expect(itemAfterSet?.attributes["isOpen"] == StateValue.bool(true))

        // Set flag to false
        let updatedItem = try await engine.item("testItem")
        if let change = await engine.setAttribute("isOpen", on: updatedItem, to: false) {
            try await engine.apply(change)
        }

        let finalItem = await engine.gameState.items["testItem"]
        #expect(finalItem?.attributes["isOpen"] == StateValue.bool(false))
    }

    @Test("Set Location Flag")
    func testSetLocationFlag() async throws {
        let testLocation = Location(
            id: "testLocation",
            .name("Test Chamber")
        )

        let game = MinimalGame(
            locations: [testLocation],
            dynamicAttributeRegistry: DynamicAttributeRegistry()
        )
        let mockIO = await MockIOHandler()
        let engine = await GameEngine(
            blueprint: game,
            parser: MockParser(),
            ioHandler: mockIO
        )

        // Set flag to true using StateChange builder
        let location = try await engine.location("testLocation")
        if let change = await engine.setAttribute("isLit", on: location, to: true) {
            try await engine.apply(change)
        }

        let locationAfterSet = await engine.gameState.locations["testLocation"]
        #expect(locationAfterSet?.attributes["isLit"] == StateValue.bool(true))
    }

    @Test("Set Item Description")
    func testSetItemDescription() async throws {
        let testItem = Item(
            id: "testItem",
            .name("widget"),
            .in(.location("testLocation")),
            .description("Original description")
        )

        let testLocation = Location(
            id: "testLocation",
            .name("Test Chamber")
        )

        let game = MinimalGame(
            locations: [testLocation],
            items: [testItem],
            dynamicAttributeRegistry: DynamicAttributeRegistry()
        )
        let mockIO = await MockIOHandler()
        let engine = await GameEngine(
            blueprint: game,
            parser: MockParser(),
            ioHandler: mockIO
        )

        // Change description using StateChange builder
        let item = try await engine.item("testItem")
        if let change = await engine.setDescription(on: item, to: "New dynamic description") {
            try await engine.apply(change)
        }

        let updatedItem = await engine.gameState.items["testItem"]
        #expect(updatedItem?.attributes[.description] == StateValue.string("New dynamic description"))
    }

    @Test("Set Location Description")
    func testSetLocationDescription() async throws {
        let testLocation = Location(
            id: "testLocation",
            .name("Test Chamber"),
            .description("Original description")
        )

        let game = MinimalGame(
            locations: [testLocation],
            dynamicAttributeRegistry: DynamicAttributeRegistry()
        )
        let mockIO = await MockIOHandler()
        let engine = await GameEngine(
            blueprint: game,
            parser: MockParser(),
            ioHandler: mockIO
        )

        // Change description using StateChange builder
        let location = try await engine.location("testLocation")
        if let change = await engine.setDescription(on: location, to: "New dynamic description") {
            try await engine.apply(change)
        }

        let updatedLocation = await engine.gameState.locations["testLocation"]
        #expect(updatedLocation?.attributes[.description] == StateValue.string("New dynamic description"))
    }

    // MARK: - Type-Specific Convenience Tests

    @Test("Set Item Int and String Attributes")
    func testSetItemIntAndStringAttributes() async throws {
        let testItem = Item(
            id: "testItem",
            .name("widget"),
            .in(.location("testLocation"))
        )

        let testLocation = Location(
            id: "testLocation",
            .name("Test Chamber")
        )

        let game = MinimalGame(
            locations: [testLocation],
            items: [testItem],
            dynamicAttributeRegistry: DynamicAttributeRegistry()
        )
        let mockIO = await MockIOHandler()
        let engine = await GameEngine(
            blueprint: game,
            parser: MockParser(),
            ioHandler: mockIO
        )

        // Set integer attribute using StateChange builder
        let item = try await engine.item("testItem")
        if let change = await engine.setAttribute(.init("strength"), on: item, to: 42) {
            try await engine.apply(change)
        }

        let itemAfterInt = await engine.gameState.items["testItem"]
        #expect(itemAfterInt?.attributes["strength"] == StateValue.int(42))

        // Set string attribute
        let updatedItem = try await engine.item("testItem")
        if let change = await engine.setAttribute(.init("color"), on: updatedItem, to: "blue") {
            try await engine.apply(change)
        }

        let finalItem = await engine.gameState.items["testItem"]
        #expect(finalItem?.attributes["color"] == StateValue.string("blue"))
    }

    @Test("Set Location Int and String Attributes")
    func testSetLocationIntAndStringAttributes() async throws {
        let testLocation = Location(
            id: "testLocation",
            .name("Test Chamber")
        )

        let game = MinimalGame(
            locations: [testLocation],
            dynamicAttributeRegistry: DynamicAttributeRegistry()
        )
        let mockIO = await MockIOHandler()
        let engine = await GameEngine(
            blueprint: game,
            parser: MockParser(),
            ioHandler: mockIO
        )

        // Set integer attribute using StateChange builder
        let location = try await engine.location("testLocation")
        if let change = await engine.setAttribute(.init("temperature"), on: location, to: 72) {
            try await engine.apply(change)
        }

        let locationAfterInt = await engine.gameState.locations["testLocation"]
        #expect(locationAfterInt?.attributes["temperature"] == StateValue.int(72))

        // Set string attribute
        let updatedLocation = try await engine.location("testLocation")
        if let change = await engine.setAttribute(.init("atmosphere"), on: updatedLocation, to: "spooky") {
            try await engine.apply(change)
        }

        let finalLocation = await engine.gameState.locations["testLocation"]
        #expect(finalLocation?.attributes["atmosphere"] == StateValue.string("spooky"))
    }

    // MARK: - Complex Validation Tests

    @Test("Complex Validation - Troll Fighting Logic")
    func testComplexValidationTrollFighting() async throws {
        var registry = DynamicAttributeRegistry()
        
        // Complex validation: Troll can only stop fighting if unconscious OR doesn't have weapon
        registry.registerItemValidate(itemID: "troll", attributeID: "fighting") { item, newValue in
            guard case .bool(let fighting) = newValue else { return false }
            
            // If trying to set fighting to false, check conditions
            if !fighting {
                let hasWeapon = item.attributes["hasWeapon"] == .bool(true)
                let isUnconscious = item.attributes["unconscious"] == .bool(true)
                
                // Can only stop fighting if unconscious OR doesn't have weapon
                return isUnconscious || !hasWeapon
            }
            
            // Always allow setting fighting to true
            return true
        }

        let troll = Item(
            id: "troll",
            .name("troll"),
            .in(.location("bridge"))
        )

        let bridge = Location(
            id: "bridge",
            .name("Bridge")
        )

        let game = MinimalGame(
            locations: [bridge],
            items: [troll],
            dynamicAttributeRegistry: registry
        )
        let mockIO = await MockIOHandler()
        let engine = await GameEngine(
            blueprint: game,
            parser: MockParser(),
            ioHandler: mockIO
        )

        // Set up troll with weapon and fighting using StateChange builders
        let trollItem = try await engine.item("troll")
        if let change = await engine.setAttribute("hasWeapon", on: trollItem, to: true) {
            try await engine.apply(change)
        }
        
        let trollWithWeapon = try await engine.item("troll")
        if let change = await engine.setAttribute("fighting", on: trollWithWeapon, to: true) {
            try await engine.apply(change)
        }

        // Should fail to stop fighting while troll has weapon and is conscious
        await #expect(throws: ActionResponse.self) {
            let currentTroll = try await engine.item("troll")
            if let change = await engine.setAttribute("fighting", on: currentTroll, to: false) {
                try await engine.apply(change)
            }
        }

        // Make troll unconscious, then should be able to stop fighting
        let consciousTroll = try await engine.item("troll")
        if let change = await engine.setAttribute("unconscious", on: consciousTroll, to: true) {
            try await engine.apply(change)
        }
        
        let unconsciousTroll = try await engine.item("troll")
        if let change = await engine.setAttribute("fighting", on: unconsciousTroll, to: false) {
            try await engine.apply(change)
        }

        let finalTroll = await engine.gameState.items["troll"]
        #expect(finalTroll?.attributes["fighting"] == StateValue.bool(false))
        #expect(finalTroll?.attributes["unconscious"] == StateValue.bool(true))
    }

    // MARK: - Error Handling Tests

    @Test("Validation Handler Throws Custom Error")
    func testValidationHandlerThrowsCustomError() async throws {
        var registry = DynamicAttributeRegistry()
        registry.registerItemValidate(itemID: "testItem", attributeID: "restrictedProp") { item, newValue in
            // Throw specific errors for different invalid cases
            switch newValue {
            case .int:
                throw ActionResponse.invalidValue("This property only accepts strings")
            case .string(let str) where str == "forbidden":
                throw ActionResponse.invalidValue("The value 'forbidden' is not allowed")
            case .string("allowed"):
                return true
            default:
                return false
            }
        }

        let testItem = Item(
            id: "testItem",
            .name("widget"),
            .in(.location("testLocation"))
        )

        let testLocation = Location(
            id: "testLocation",
            .name("Test Chamber")
        )

        let game = MinimalGame(
            locations: [testLocation],
            items: [testItem],
            dynamicAttributeRegistry: registry
        )
        let mockIO = await MockIOHandler()
        let engine = await GameEngine(
            blueprint: game,
            parser: MockParser(),
            ioHandler: mockIO
        )

        // Should throw specific error for wrong type
        await #expect(throws: ActionResponse.self) {
            let item = try await engine.item("testItem")
            if let change = await engine.setAttribute(.init("restrictedProp"), on: item, to: .int(42)) {
                try await engine.apply(change)
            }
        }

        // Should throw specific error for forbidden value
        await #expect(throws: ActionResponse.self) {
            let item = try await engine.item("testItem")
            if let change = await engine.setAttribute(.init("restrictedProp"), on: item, to: .string("forbidden")) {
                try await engine.apply(change)
            }
        }

        // Should succeed for valid value
        let item = try await engine.item("testItem")
        if let change = await engine.setAttribute(.init("restrictedProp"), on: item, to: .string("allowed")) {
            try await engine.apply(change)
        }

        let finalItem = await engine.gameState.items["testItem"]
        #expect(finalItem?.attributes["restrictedProp"] == StateValue.string("allowed"))
    }
}
