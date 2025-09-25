import CustomDump
import GnustoTestSupport
import Testing

@testable import GnustoEngine

@Suite("ItemProxy StateChange Tests")
struct ItemProxyStateChangesTests {

    // MARK: - Flag Operations

    @Test("ItemProxy setFlag creates valid StateChange")
    func testSetFlagCreatesValidStateChange() async throws {
        // Given
        let testItem = Item(
            id: "testItem",
            .name("test item"),
            .in(.startRoom)
        )
        let game = MinimalGame(items: testItem)
        let (engine, _) = await GameEngine.test(blueprint: game)
        let proxy = await engine.item("testItem")

        // When
        let change = await proxy.setFlag(.isTouched)

        // Then
        #expect(change != nil)
        if let change {
            if case .setItemProperty(let id, let property, let value) = change {
                #expect(id == "testItem")
                #expect(property == .isTouched)
                if case .bool(let boolValue) = value {
                    #expect(boolValue == true)
                } else {
                    #expect(Bool(false), "Expected bool value")
                }
            } else {
                #expect(Bool(false), "Expected setItemProperty case")
            }
        }
    }

    @Test("ItemProxy setFlag returns nil when flag already set")
    func testSetFlagReturnsNilWhenAlreadySet() async throws {
        // Given
        let testItem = Item(
            id: "testItem",
            .name("test item"),
            .isTouched,
            .in(.startRoom)
        )
        let game = MinimalGame(items: testItem)
        let (engine, _) = await GameEngine.test(blueprint: game)
        let proxy = await engine.item("testItem")

        // When
        let change = await proxy.setFlag(.isTouched)

        // Then
        #expect(change == nil)
    }

    @Test("ItemProxy clearFlag creates valid StateChange")
    func testClearFlagCreatesValidStateChange() async throws {
        // Given
        let testItem = Item(
            id: "testItem",
            .name("test item"),
            .isTouched,
            .in(.startRoom)
        )
        let game = MinimalGame(items: testItem)
        let (engine, _) = await GameEngine.test(blueprint: game)
        let proxy = await engine.item("testItem")

        // When
        let change = await proxy.clearFlag(.isTouched)

        // Then
        #expect(change != nil)
        if let change {
            if case .setItemProperty(let id, let property, let value) = change {
                #expect(id == "testItem")
                #expect(property == .isTouched)
                if case .bool(let boolValue) = value {
                    #expect(boolValue == false)
                } else {
                    #expect(Bool(false), "Expected bool value")
                }
            } else {
                #expect(Bool(false), "Expected setItemProperty case")
            }
        }
    }

    @Test("ItemProxy clearFlag returns nil when flag not set")
    func testClearFlagReturnsNilWhenNotSet() async throws {
        // Given
        let testItem = Item(
            id: "testItem",
            .name("test item"),
            .in(.startRoom)
        )
        let game = MinimalGame(items: testItem)
        let (engine, _) = await GameEngine.test(blueprint: game)
        let proxy = await engine.item("testItem")

        // When
        let change = await proxy.clearFlag(.isTouched)

        // Then
        #expect(change == nil)
    }

    // MARK: - Movement Operations

    @Test("ItemProxy move creates valid StateChange")
    func testMoveCreatesValidStateChange() async throws {
        // Given
        let testItem = Item(
            id: "testItem",
            .name("test item"),
            .in(.startRoom)
        )
        let game = MinimalGame(items: testItem)
        let (engine, _) = await GameEngine.test(blueprint: game)
        let proxy = await engine.item("testItem")

        // When
        let change = proxy.move(to: .player)

        // Then
        if case .moveItem(let id, let parent) = change {
            #expect(id == "testItem")
            #expect(parent == .player)
        } else {
            #expect(Bool(false), "Expected moveItem case")
        }
    }

    @Test("ItemProxy remove creates valid StateChange")
    func testRemoveCreatesValidStateChange() async throws {
        // Given
        let testItem = Item(
            id: "testItem",
            .name("test item"),
            .in(.player)
        )
        let game = MinimalGame(items: testItem)
        let (engine, _) = await GameEngine.test(blueprint: game)
        let proxy = await engine.item("testItem")

        // When
        let change = proxy.remove()

        // Then
        if case .moveItem(let id, let parent) = change {
            #expect(id == "testItem")
            #expect(parent == .nowhere)
        } else {
            #expect(Bool(false), "Expected moveItem case")
        }
    }

    // MARK: - Property Operations

    @Test("ItemProxy setProperty StateValue creates valid StateChange")
    func testSetPropertyStateValueCreatesValidStateChange() async throws {
        // Given
        let testItem = Item(
            id: "testItem",
            .name("test item"),
            .in(.startRoom)
        )
        let game = MinimalGame(items: testItem)
        let (engine, _) = await GameEngine.test(blueprint: game)
        let proxy = await engine.item("testItem")

        // When
        let change = await proxy.setProperty(.testCounter, to: .int(42))

        // Then
        #expect(change != nil)
        if let change {
            if case .setItemProperty(let id, let property, let value) = change {
                #expect(id == "testItem")
                #expect(property == .testCounter)
                if case .int(let intValue) = value {
                    #expect(intValue == 42)
                } else {
                    #expect(Bool(false), "Expected int value")
                }
            } else {
                #expect(Bool(false), "Expected setItemProperty case")
            }
        }
    }

    @Test("ItemProxy setProperty returns nil when no change")
    func testSetPropertyReturnsNilWhenNoChange() async throws {
        // Given
        let testItem = Item(
            id: "testItem",
            .name("test item"),
            .testCounterValue(42),
            .in(.startRoom)
        )
        let game = MinimalGame(items: testItem)
        let (engine, _) = await GameEngine.test(blueprint: game)
        let proxy = await engine.item("testItem")

        // When
        let change = await proxy.setProperty(.testCounter, to: .int(42))

        // Then
        #expect(change == nil)
    }

    @Test("ItemProxy setProperty Bool creates valid StateChange")
    func testSetPropertyBoolCreatesValidStateChange() async throws {
        // Given
        let testItem = Item(
            id: "testItem",
            .name("test item"),
            .in(.startRoom)
        )
        let game = MinimalGame(items: testItem)
        let (engine, _) = await GameEngine.test(blueprint: game)
        let proxy = await engine.item("testItem")

        // When
        let change = await proxy.setProperty(.testFlag, to: true)

        // Then
        #expect(change != nil)
        if let change {
            if case .setItemProperty(let id, let property, let value) = change {
                #expect(id == "testItem")
                #expect(property == .testFlag)
                if case .bool(let boolValue) = value {
                    #expect(boolValue == true)
                } else {
                    #expect(Bool(false), "Expected bool value")
                }
            } else {
                #expect(Bool(false), "Expected setItemProperty case")
            }
        }
    }

    @Test("ItemProxy setProperty Int creates valid StateChange")
    func testSetPropertyIntCreatesValidStateChange() async throws {
        // Given
        let testItem = Item(
            id: "testItem",
            .name("test item"),
            .in(.startRoom)
        )
        let game = MinimalGame(items: testItem)
        let (engine, _) = await GameEngine.test(blueprint: game)
        let proxy = await engine.item("testItem")

        // When
        let change = await proxy.setProperty(.testCounter, to: 100)

        // Then
        #expect(change != nil)
        if let change {
            if case .setItemProperty(let id, let property, let value) = change {
                #expect(id == "testItem")
                #expect(property == .testCounter)
                if case .int(let intValue) = value {
                    #expect(intValue == 100)
                } else {
                    #expect(Bool(false), "Expected int value")
                }
            } else {
                #expect(Bool(false), "Expected setItemProperty case")
            }
        }
    }

    @Test("ItemProxy setProperty String creates valid StateChange")
    func testSetPropertyStringCreatesValidStateChange() async throws {
        // Given
        let testItem = Item(
            id: "testItem",
            .name("test item"),
            .in(.startRoom)
        )
        let game = MinimalGame(items: testItem)
        let (engine, _) = await GameEngine.test(blueprint: game)
        let proxy = await engine.item("testItem")

        // When
        let change = await proxy.setProperty(.testText, to: "Hello World")

        // Then
        #expect(change != nil)
        if let change {
            if case .setItemProperty(let id, let property, let value) = change {
                #expect(id == "testItem")
                #expect(property == .testText)
                if case .string(let stringValue) = value {
                    #expect(stringValue == "Hello World")
                } else {
                    #expect(Bool(false), "Expected string value")
                }
            } else {
                #expect(Bool(false), "Expected setItemProperty case")
            }
        }
    }

    // MARK: - Description Operations

    @Test("ItemProxy setDescription creates valid StateChange")
    func testSetDescriptionCreatesValidStateChange() async throws {
        // Given
        let testItem = Item(
            id: "testItem",
            .name("test item"),
            .in(.startRoom)
        )
        let game = MinimalGame(items: testItem)
        let (engine, _) = await GameEngine.test(blueprint: game)
        let proxy = await engine.item("testItem")

        // When
        let change = await proxy.setDescription(to: "A newly described item.")

        // Then
        #expect(change != nil)
        if let change {
            if case .setItemProperty(let id, let property, let value) = change {
                #expect(id == "testItem")
                #expect(property == .description)
                if case .string(let stringValue) = value {
                    #expect(stringValue == "A newly described item.")
                } else {
                    #expect(Bool(false), "Expected string value")
                }
            } else {
                #expect(Bool(false), "Expected setItemProperty case")
            }
        }
    }

    @Test("ItemProxy setDescription returns nil when no change")
    func testSetDescriptionReturnsNilWhenNoChange() async throws {
        // Given
        let testItem = Item(
            id: "testItem",
            .name("test item"),
            .description("A newly described item."),
            .in(.startRoom)
        )
        let game = MinimalGame(items: testItem)
        let (engine, _) = await GameEngine.test(blueprint: game)
        let proxy = await engine.item("testItem")

        // When
        let change = await proxy.setDescription(to: "A newly described item.")

        // Then
        #expect(change == nil)
    }

    // MARK: - Complex Operations

    @Test("ItemProxy multiple flag operations")
    func testMultipleFlagOperations() async throws {
        // Given
        let testItem = Item(
            id: "testItem",
            .name("test item"),
            .in(.startRoom)
        )
        let game = MinimalGame(items: testItem)
        let (engine, _) = await GameEngine.test(blueprint: game)
        let proxy = await engine.item("testItem")

        // When/Then: Set a new flag
        let setChange = await proxy.setFlag(.isTouched)
        #expect(setChange != nil)
        if let setChange {
            if case .setItemProperty(let id, let property, let value) = setChange {
                #expect(id == "testItem")
                #expect(property == .isTouched)
                if case .bool(let boolValue) = value {
                    #expect(boolValue == true)
                }
            }
        }

        // Apply the change to update the proxy's state
        try await engine.apply(setChange!)

        // Clear the flag
        let clearChange = await proxy.clearFlag(.isTouched)
        #expect(clearChange != nil)
        if let clearChange {
            if case .setItemProperty(let id, let property, let value) = clearChange {
                #expect(id == "testItem")
                #expect(property == .isTouched)
                if case .bool(let boolValue) = value {
                    #expect(boolValue == false)
                }
            }
        }
    }

    @Test("ItemProxy StateValue property operations")
    func testStateValuePropertyOperations() async throws {
        // Given
        let testItem = Item(
            id: "testItem",
            .name("test item"),
            .in(.startRoom)
        )
        let game = MinimalGame(items: testItem)
        let (engine, _) = await GameEngine.test(blueprint: game)
        let proxy = await engine.item("testItem")

        // When/Then: Set various property types
        let boolChange = await proxy.setProperty(.testFlag, to: true)
        #expect(boolChange != nil)
        if let boolChange {
            if case .setItemProperty(let id, let property, let value) = boolChange {
                #expect(id == "testItem")
                #expect(property == .testFlag)
                if case .bool(let boolValue) = value {
                    #expect(boolValue == true)
                }
            }
        }

        // Set int property
        let intChange = await proxy.setProperty(.testCounter, to: 42)
        #expect(intChange != nil)
        if let intChange {
            if case .setItemProperty(let id, let property, let value) = intChange {
                #expect(id == "testItem")
                #expect(property == .testCounter)
                if case .int(let intValue) = value {
                    #expect(intValue == 42)
                }
            }
        }

        // Set string property
        let stringChange = await proxy.setProperty(.testText, to: "test value")
        #expect(stringChange != nil)
        if let stringChange {
            if case .setItemProperty(let id, let property, let value) = stringChange {
                #expect(id == "testItem")
                #expect(property == .testText)
                if case .string(let stringValue) = value {
                    #expect(stringValue == "test value")
                }
            }
        }
    }

    // MARK: - Change History Integration

    @Test("ItemProxy changes are applied in order")
    func testChangesAreAppliedInOrder() async throws {
        // Given
        let testItem = Item(
            id: "testItem",
            .name("test item"),
            .in(.startRoom)
        )
        let game = MinimalGame(items: testItem)
        let (engine, _) = await GameEngine.test(blueprint: game)
        let proxy = await engine.item("testItem")

        // When: Apply multiple changes
        let change1 = await proxy.setProperty(.testCounter, to: 1)
        let change2 = await proxy.setProperty(.testCounter, to: 2)
        let change3 = await proxy.setProperty(.testCounter, to: 3)

        try await engine.apply(change1!)
        try await engine.apply(change2!)
        try await engine.apply(change3!)

        // Then: Final value should be from the last change
        let finalItem = await engine.item("testItem")
        #expect(await finalItem.property(.testCounter) == .int(3))

        // And: Change history should preserve order
        let history = await engine.changeHistory
        let counterChanges = history.filter {
            if case .setItemProperty(let id, _, _) = $0 {
                return id == "testItem"
            }
            return false
        }
        #expect(counterChanges.count == 3)
        if case .setItemProperty(_, _, let value1) = counterChanges[0] {
            #expect(value1 == .int(1))
        }
        if case .setItemProperty(_, _, let value2) = counterChanges[1] {
            #expect(value2 == .int(2))
        }
        if case .setItemProperty(_, _, let value3) = counterChanges[2] {
            #expect(value3 == .int(3))
        }
    }
}

// MARK: - Test Extensions

extension ItemPropertyID {
    fileprivate static let testFlag = ItemPropertyID("testFlag")
    fileprivate static let testCounter = ItemPropertyID("testCounter")
    fileprivate static let testText = ItemPropertyID("testText")
}

extension ItemProperty {
    fileprivate static let testAttrFlag = ItemProperty(id: .testFlag, rawValue: true)
    fileprivate static func testCounterValue(_ value: Int) -> ItemProperty {
        ItemProperty(id: .testCounter, rawValue: .int(value))
    }
}
