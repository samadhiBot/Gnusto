import CustomDump
import GnustoEngine
import GnustoTestSupport
import Testing

/// Tests for ItemProxy and LocationProxy StateChange factory methods.
@Suite("Proxy StateChange Factory Tests")
struct ProxyStateChangeTests {

    // MARK: - ItemProxy StateChange Tests

    @Test("ItemProxy clearFlag - success when flag is set")
    func testItemProxyClearFlagSuccess() async throws {
        // Given
        let item = Item(
            id: "testItem",
            .name("Test Item"),
            .testItemAttrFlag
        )
        let game = MinimalGame(items: item)
        let (engine, _) = await GameEngine.test(blueprint: game)
        let itemProxy = await engine.item("testItem")

        // When
        let change = await itemProxy.clearFlag(.testItemFlag)

        // Then
        #expect(change != nil)
        if let change {
            if case .setItemProperty(let id, let property, let value) = change {
                #expect(id == "testItem")
                #expect(property == .testItemFlag)
                #expect(value == .bool(false))
            } else {
                #expect(Bool(false), "Expected setItemProperty case")
            }
        }
    }

    @Test("ItemProxy clearFlag - nil when flag not set")
    func testItemProxyClearFlagWhenNotSet() async throws {
        // Given
        let item = Item(
            id: "testItem",
            .name("Test Item")
        )
        let game = MinimalGame(items: item)
        let (engine, _) = await GameEngine.test(blueprint: game)
        let itemProxy = await engine.item("testItem")

        // When
        let change = await itemProxy.clearFlag(.testItemFlag)

        // Then
        #expect(change == nil)
    }

    @Test("ItemProxy setFlag - success when flag not set")
    func testItemProxySetFlagSuccess() async throws {
        // Given
        let item = Item(
            id: "testItem",
            .name("Test Item")
        )
        let game = MinimalGame(items: item)
        let (engine, _) = await GameEngine.test(blueprint: game)
        let itemProxy = await engine.item("testItem")

        // When
        let change = await itemProxy.setFlag(.testItemFlag)

        // Then
        #expect(change != nil)
        if let change {
            if case .setItemProperty(let id, let property, let value) = change {
                #expect(id == "testItem")
                #expect(property == .testItemFlag)
                #expect(value == .bool(true))
            } else {
                #expect(Bool(false), "Expected setItemProperty case")
            }
        }
    }

    @Test("ItemProxy setFlag - nil when flag already set")
    func testItemProxySetFlagWhenAlreadySet() async throws {
        // Given
        let item = Item(
            id: "testItem",
            .name("Test Item"),
            .testItemAttrFlag
        )
        let game = MinimalGame(items: item)
        let (engine, _) = await GameEngine.test(blueprint: game)
        let itemProxy = await engine.item("testItem")

        // When
        let change = await itemProxy.setFlag(.testItemFlag)

        // Then
        #expect(change == nil)
    }

    @Test("ItemProxy move - success")
    func testItemProxyMoveSuccess() async throws {
        // Given
        let item = Item(
            id: "testItem",
            .name("Test Item"),
            .in("startLocation")
        )
        let game = MinimalGame(items: item)
        let (engine, _) = await GameEngine.test(blueprint: game)
        let itemProxy = await engine.item("testItem")

        // When
        let change = itemProxy.move(to: .player)

        // Then
        if case .moveItem(let id, let parent) = change {
            #expect(id == "testItem")
            #expect(parent == .player)
        } else {
            #expect(Bool(false), "Expected moveItem case")
        }
    }

    @Test("ItemProxy remove - success")
    func testItemProxyRemoveSuccess() async throws {
        // Given
        let item = Item(
            id: "testItem",
            .name("Test Item"),
            .in(.player)
        )
        let game = MinimalGame(items: item)
        let (engine, _) = await GameEngine.test(blueprint: game)
        let itemProxy = await engine.item("testItem")

        // When
        let change = itemProxy.remove()

        // Then
        if case .moveItem(let id, let parent) = change {
            #expect(id == "testItem")
            #expect(parent == .nowhere)
        } else {
            #expect(Bool(false), "Expected moveItem case")
        }
    }

    @Test("ItemProxy setProperty StateValue - success")
    func testItemProxySetPropertyStateValueSuccess() async throws {
        // Given
        let item = Item(
            id: "testItem",
            .name("Test Item")
        )
        let game = MinimalGame(items: item)
        let (engine, _) = await GameEngine.test(blueprint: game)
        let itemProxy = await engine.item("testItem")

        // When
        let change = await itemProxy.setProperty(.testItemCounter, to: .int(42))

        // Then
        #expect(change != nil)
        if let change {
            if case .setItemProperty(let id, let property, let value) = change {
                #expect(id == "testItem")
                #expect(property == .testItemCounter)
                #expect(value == .int(42))
            } else {
                #expect(Bool(false), "Expected setItemProperty case")
            }
        }
    }

    @Test("ItemProxy setProperty StateValue - nil when no change")
    func testItemProxySetPropertyStateValueNoChange() async throws {
        // Given
        let item = Item(
            id: "testItem",
            .name("Test Item"),
            .testItemCounterValue(42)
        )
        let game = MinimalGame(items: item)
        let (engine, _) = await GameEngine.test(blueprint: game)
        let itemProxy = await engine.item("testItem")

        // When
        let change = await itemProxy.setProperty(.testItemCounter, to: .int(42))

        // Then
        #expect(change == nil)
    }

    @Test("ItemProxy setProperty Bool - success")
    func testItemProxySetPropertyBoolSuccess() async throws {
        // Given
        let item = Item(
            id: "testItem",
            .name("Test Item")
        )
        let game = MinimalGame(items: item)
        let (engine, _) = await GameEngine.test(blueprint: game)
        let itemProxy = await engine.item("testItem")

        // When
        let change = await itemProxy.setProperty(.testItemFlag, to: true)

        // Then
        #expect(change != nil)
        if let change {
            if case .setItemProperty(let id, let property, let value) = change {
                #expect(id == "testItem")
                #expect(property == .testItemFlag)
                #expect(value == .bool(true))
            } else {
                #expect(Bool(false), "Expected setItemProperty case")
            }
        }
    }

    @Test("ItemProxy setProperty Int - success")
    func testItemProxySetPropertyIntSuccess() async throws {
        // Given
        let item = Item(
            id: "testItem",
            .name("Test Item")
        )
        let game = MinimalGame(items: item)
        let (engine, _) = await GameEngine.test(blueprint: game)
        let itemProxy = await engine.item("testItem")

        // When
        let change = await itemProxy.setProperty(.testItemCounter, to: 100)

        // Then
        #expect(change != nil)
        if let change {
            if case .setItemProperty(let id, let property, let value) = change {
                #expect(id == "testItem")
                #expect(property == .testItemCounter)
                #expect(value == .int(100))
            } else {
                #expect(Bool(false), "Expected setItemProperty case")
            }
        }
    }

    @Test("ItemProxy setProperty String - success")
    func testItemProxySetPropertyStringSuccess() async throws {
        // Given
        let item = Item(
            id: "testItem",
            .name("Test Item")
        )
        let game = MinimalGame(items: item)
        let (engine, _) = await GameEngine.test(blueprint: game)
        let itemProxy = await engine.item("testItem")

        // When
        let change = await itemProxy.setProperty(.testItemText, to: "Hello World")

        // Then
        #expect(change != nil)
        if let change {
            if case .setItemProperty(let id, let property, let value) = change {
                #expect(id == "testItem")
                #expect(property == .testItemText)
                #expect(value == .string("Hello World"))
            } else {
                #expect(Bool(false), "Expected setItemProperty case")
            }
        }
    }

    @Test("ItemProxy setDescription - success")
    func testItemProxySetDescriptionSuccess() async throws {
        // Given
        let item = Item(
            id: "testItem",
            .name("Test Item")
        )
        let game = MinimalGame(items: item)
        let (engine, _) = await GameEngine.test(blueprint: game)
        let itemProxy = await engine.item("testItem")

        // When
        let change = await itemProxy.setDescription(to: "A newly described item.")

        // Then
        #expect(change != nil)
        if let change {
            if case .setItemProperty(let id, let property, let value) = change {
                #expect(id == "testItem")
                #expect(property == .description)
                #expect(value == .string("A newly described item."))
            } else {
                #expect(Bool(false), "Expected setItemProperty case")
            }
        }
    }

    @Test("ItemProxy setDescription - nil when no change")
    func testItemProxySetDescriptionNoChange() async throws {
        // Given
        let item = Item(
            id: "testItem",
            .name("Test Item"),
            .description("A newly described item.")
        )
        let game = MinimalGame(items: item)
        let (engine, _) = await GameEngine.test(blueprint: game)
        let itemProxy = await engine.item("testItem")

        // When
        let change = await itemProxy.setDescription(to: "A newly described item.")

        // Then
        #expect(change == nil)
    }

    // MARK: - LocationProxy StateChange Tests

    @Test("LocationProxy clearFlag - success when flag is set")
    func testLocationProxyClearFlagSuccess() async throws {
        // Given
        let location = Location(
            id: "testLocation",
            .name("Test Location"),
            .testLocationAttrFlag
        )
        let game = MinimalGame(locations: location)
        let (engine, _) = await GameEngine.test(blueprint: game)
        let locationProxy = await engine.location("testLocation")

        // When
        let change = await locationProxy.clearFlag(.testLocationFlag)

        // Then
        #expect(change != nil)
        if let change {
            if case .setLocationProperty(let id, let property, let value) = change {
                #expect(id == "testLocation")
                #expect(property == .testLocationFlag)
                #expect(value == .bool(false))
            } else {
                #expect(Bool(false), "Expected setLocationProperty case")
            }
        }
    }

    @Test("LocationProxy clearFlag - nil when flag not set")
    func testLocationProxyClearFlagWhenNotSet() async throws {
        // Given
        let location = Location(
            id: "testLocation",
            .name("Test Location")
        )
        let game = MinimalGame(locations: location)
        let (engine, _) = await GameEngine.test(blueprint: game)
        let locationProxy = await engine.location("testLocation")

        // When
        let change = await locationProxy.clearFlag(.testLocationFlag)

        // Then
        #expect(change == nil)
    }

    @Test("LocationProxy setFlag - success when flag not set")
    func testLocationProxySetFlagSuccess() async throws {
        // Given
        let location = Location(
            id: "testLocation",
            .name("Test Location")
        )
        let game = MinimalGame(locations: location)
        let (engine, _) = await GameEngine.test(blueprint: game)
        let locationProxy = await engine.location("testLocation")

        // When
        let change = await locationProxy.setFlag(.testLocationFlag)

        // Then
        #expect(change != nil)
        if let change {
            if case .setLocationProperty(let id, let property, let value) = change {
                #expect(id == "testLocation")
                #expect(property == .testLocationFlag)
                #expect(value == .bool(true))
            } else {
                #expect(Bool(false), "Expected setLocationProperty case")
            }
        }
    }

    @Test("LocationProxy setFlag - nil when flag already set")
    func testLocationProxySetFlagWhenAlreadySet() async throws {
        // Given
        let location = Location(
            id: "testLocation",
            .name("Test Location"),
            .testLocationAttrFlag
        )
        let game = MinimalGame(locations: location)
        let (engine, _) = await GameEngine.test(blueprint: game)
        let locationProxy = await engine.location("testLocation")

        // When
        let change = await locationProxy.setFlag(.testLocationFlag)

        // Then
        #expect(change == nil)
    }

    @Test("LocationProxy setProperty StateValue - success")
    func testLocationProxySetPropertyStateValueSuccess() async throws {
        // Given
        let location = Location(
            id: "testLocation",
            .name("Test Location")
        )
        let game = MinimalGame(locations: location)
        let (engine, _) = await GameEngine.test(blueprint: game)
        let locationProxy = await engine.location("testLocation")

        // When
        let change = await locationProxy.setProperty(.testLocationCounter, to: .int(99))

        // Then
        #expect(change != nil)
        if let change {
            if case .setLocationProperty(let id, let property, let value) = change {
                #expect(id == "testLocation")
                #expect(property == .testLocationCounter)
                #expect(value == .int(99))
            } else {
                #expect(Bool(false), "Expected setLocationProperty case")
            }
        }
    }

    @Test("LocationProxy setProperty StateValue - nil when no change")
    func testLocationProxySetPropertyStateValueNoChange() async throws {
        // Given
        let location = Location(
            id: "testLocation",
            .name("Test Location"),
            .testLocationCounterValue(99)
        )
        let game = MinimalGame(locations: location)
        let (engine, _) = await GameEngine.test(blueprint: game)
        let locationProxy = await engine.location("testLocation")

        // When
        let change = await locationProxy.setProperty(.testLocationCounter, to: .int(99))

        // Then
        #expect(change == nil)
    }

    @Test("LocationProxy setProperty Bool - success")
    func testLocationProxySetPropertyBoolSuccess() async throws {
        // Given
        let location = Location(
            id: "testLocation",
            .name("Test Location")
        )
        let game = MinimalGame(locations: location)
        let (engine, _) = await GameEngine.test(blueprint: game)
        let locationProxy = await engine.location("testLocation")

        // When
        let change = await locationProxy.setProperty(.testLocationFlag, to: true)

        // Then
        #expect(change != nil)
        if let change {
            if case .setLocationProperty(let id, let property, let value) = change {
                #expect(id == "testLocation")
                #expect(property == .testLocationFlag)
                #expect(value == .bool(true))
            } else {
                #expect(Bool(false), "Expected setLocationProperty case")
            }
        }
    }

    @Test("LocationProxy setProperty Int - success")
    func testLocationProxySetPropertyIntSuccess() async throws {
        // Given
        let location = Location(
            id: "testLocation",
            .name("Test Location")
        )
        let game = MinimalGame(locations: location)
        let (engine, _) = await GameEngine.test(blueprint: game)
        let locationProxy = await engine.location("testLocation")

        // When
        let change = await locationProxy.setProperty(.testLocationCounter, to: 200)

        // Then
        #expect(change != nil)
        if let change {
            if case .setLocationProperty(let id, let property, let value) = change {
                #expect(id == "testLocation")
                #expect(property == .testLocationCounter)
                #expect(value == .int(200))
            } else {
                #expect(Bool(false), "Expected setLocationProperty case")
            }
        }
    }

    @Test("LocationProxy setProperty String - success")
    func testLocationProxySetPropertyStringSuccess() async throws {
        // Given
        let location = Location(
            id: "testLocation",
            .name("Test Location")
        )
        let game = MinimalGame(locations: location)
        let (engine, _) = await GameEngine.test(blueprint: game)
        let locationProxy = await engine.location("testLocation")

        // When
        let change = await locationProxy.setProperty(.testLocationText, to: "Location Text")

        // Then
        #expect(change != nil)
        if let change {
            if case .setLocationProperty(let id, let property, let value) = change {
                #expect(id == "testLocation")
                #expect(property == .testLocationText)
                #expect(value == .string("Location Text"))
            } else {
                #expect(Bool(false), "Expected setLocationProperty case")
            }
        }

    }

    @Test("LocationProxy setDescription - success")
    func testLocationProxySetDescriptionSuccess() async throws {
        // Given
        let location = Location(
            id: "testLocation",
            .name("Test Location")
        )
        let game = MinimalGame(locations: location)
        let (engine, _) = await GameEngine.test(blueprint: game)
        let locationProxy = await engine.location("testLocation")

        // When
        let change = await locationProxy.setDescription(to: "A newly described location.")

        // Then
        #expect(change != nil)
        if let change {
            if case .setLocationProperty(let id, let property, let value) = change {
                #expect(id == "testLocation")
                #expect(property == .description)
                #expect(value == .string("A newly described location."))
            } else {
                #expect(Bool(false), "Expected setLocationProperty case")
            }
        }
    }

    @Test("LocationProxy setDescription - nil when no change")
    func testLocationProxySetDescriptionNoChange() async throws {
        // Given
        let location = Location(
            id: "testLocation",
            .name("Test Location"),
            .description("A newly described location.")
        )
        let game = MinimalGame(locations: location)
        let (engine, _) = await GameEngine.test(blueprint: game)
        let locationProxy = await engine.location("testLocation")

        // When
        let change = await locationProxy.setDescription(to: "A newly described location.")

        // Then
        #expect(change == nil)
    }

    // MARK: - Integration Tests

    @Test("ItemProxy StateChange integration - complex scenario")
    func testItemProxyStateChangeIntegration() async throws {
        // Given
        let item = Item(
            id: "testItem",
            .name("Test Item"),
            .in(.startRoom)
        )
        let game = MinimalGame(items: item)
        let (engine, _) = await GameEngine.test(blueprint: game)
        let itemProxy = await engine.item("testItem")

        // When - Apply multiple changes in sequence
        let moveChange = itemProxy.move(to: .player)
        try await engine.apply(moveChange)

        let flagChange = await itemProxy.setFlag(.testItemFlag)
        if let flagChange {
            try await engine.apply(flagChange)
        }

        let descriptionChange = await itemProxy.setDescription(to: "A modified item.")
        if let descriptionChange {
            try await engine.apply(descriptionChange)
        }

        // Then - Verify final state
        let finalItemProxy = await engine.item("testItem")
        #expect(await finalItemProxy.parent == .player)
        #expect(await finalItemProxy.hasFlag(.testItemFlag) == true)
        #expect(await finalItemProxy.description == "A modified item.")
    }

    @Test("LocationProxy StateChange integration - complex scenario")
    func testLocationProxyStateChangeIntegration() async throws {
        // Given
        let location = Location(
            id: "testLocation",
            .name("Test Location")
        )
        let game = MinimalGame(locations: location)
        let (engine, _) = await GameEngine.test(blueprint: game)
        let locationProxy = await engine.location("testLocation")

        // When - Apply multiple changes in sequence
        let flagChange = await locationProxy.setFlag(.testLocationFlag)
        if let flagChange {
            try await engine.apply(flagChange)
        }

        let counterChange = await locationProxy.setProperty(.testLocationCounter, to: 42)
        if let counterChange {
            try await engine.apply(counterChange)
        }

        let descriptionChange = await locationProxy.setDescription(to: "A modified location.")
        if let descriptionChange {
            try await engine.apply(descriptionChange)
        }

        // Then - Verify final state
        let finalLocationProxy = await engine.location("testLocation")
        #expect(await finalLocationProxy.hasFlag(.testLocationFlag) == true)
        #expect(await finalLocationProxy.property(.testLocationCounter) == .int(42))
        #expect(await finalLocationProxy.description == "A modified location.")
    }
}

// MARK: - Test Extensions

extension ItemPropertyID {
    fileprivate static let testItemFlag = ItemPropertyID("testItemFlag")
    fileprivate static let testItemCounter = ItemPropertyID("testItemCounter")
    fileprivate static let testItemText = ItemPropertyID("testItemText")
}

extension LocationPropertyID {
    fileprivate static let testLocationFlag = LocationPropertyID("testLocationFlag")
    fileprivate static let testLocationCounter = LocationPropertyID("testLocationCounter")
    fileprivate static let testLocationText = LocationPropertyID("testLocationText")
}

extension ItemProperty {
    fileprivate static let testItemAttrFlag = ItemProperty(
        id: .testItemFlag, rawValue: .bool(true))
    fileprivate static func testItemCounterValue(_ value: Int) -> ItemProperty {
        ItemProperty(id: .testItemCounter, rawValue: .int(value))
    }
}

extension LocationProperty {
    fileprivate static let testLocationAttrFlag = LocationProperty(
        id: .testLocationFlag, rawValue: .bool(true))
    fileprivate static func testLocationCounterValue(_ value: Int) -> LocationProperty {
        LocationProperty(id: .testLocationCounter, rawValue: .int(value))
    }
}
