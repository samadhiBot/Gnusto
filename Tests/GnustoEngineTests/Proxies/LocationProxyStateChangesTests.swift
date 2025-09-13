import CustomDump
import GnustoTestSupport
import Testing

@testable import GnustoEngine

@Suite("LocationProxy StateChange Tests")
struct LocationProxyStateChangesTests {

    // MARK: - Flag Operations

    @Test("LocationProxy setFlag creates valid StateChange")
    func testSetFlagCreatesValidStateChange() async throws {
        // Given
        let game = MinimalGame()
        let (engine, _) = await GameEngine.test(blueprint: game)
        let proxy = try await engine.location(.startRoom)

        // When
        let change = try await proxy.setFlag(.isVisited)

        // Then
        #expect(change != nil)
        if let change {
            if case .setLocationProperty(let id, let property, let value) = change {
                #expect(id == .startRoom)
                #expect(property == .isVisited)
                if case .bool(let boolValue) = value {
                    #expect(boolValue == true)
                } else {
                    #expect(Bool(false), "Expected bool value")
                }
            } else {
                #expect(Bool(false), "Expected setLocationProperty case")
            }
        }
    }

    @Test("LocationProxy setFlag returns nil when flag already set")
    func testSetFlagReturnsNilWhenAlreadySet() async throws {
        // Given
        let testRoom = Location(
            id: .startRoom,
            .name("Test Room"),
            .isVisited
        )
        let game = MinimalGame(locations: testRoom)
        let (engine, _) = await GameEngine.test(blueprint: game)
        let proxy = try await engine.location(.startRoom)

        // When
        let change = try await proxy.setFlag(.isVisited)

        // Then
        #expect(change == nil)
    }

    @Test("LocationProxy clearFlag creates valid StateChange")
    func testClearFlagCreatesValidStateChange() async throws {
        // Given
        let testRoom = Location(
            id: .startRoom,
            .name("Test Room"),
            .isVisited
        )
        let game = MinimalGame(locations: testRoom)
        let (engine, _) = await GameEngine.test(blueprint: game)
        let proxy = try await engine.location(.startRoom)

        // When
        let change = try await proxy.clearFlag(.isVisited)

        // Then
        #expect(change != nil)
        if let change {
            if case .setLocationProperty(let id, let property, let value) = change {
                #expect(id == .startRoom)
                #expect(property == .isVisited)
                if case .bool(let boolValue) = value {
                    #expect(boolValue == false)
                } else {
                    #expect(Bool(false), "Expected bool value")
                }
            } else {
                #expect(Bool(false), "Expected setLocationProperty case")
            }
        }
    }

    @Test("LocationProxy clearFlag returns nil when flag already clear")
    func testClearFlagReturnsNilWhenAlreadyClear() async throws {
        // Given
        let testRoom = Location(
            id: .startRoom,
            .name("Test Room"),
            .inherentlyLit
        )
        let game = MinimalGame(locations: testRoom)
        let (engine, _) = await GameEngine.test(blueprint: game)
        let proxy = try await engine.location(.startRoom)

        // When
        let change = try await proxy.clearFlag(.isVisited)

        // Then
        #expect(change == nil)
    }

    // MARK: - Property Operations

    @Test("LocationProxy clearFlag on inherently lit location")
    func testClearFlagOnInherentlyLitLocation() async throws {
        // Given
        let testRoom = Location(
            id: .startRoom,
            .name("Test Room"),
            .inherentlyLit
        )
        let game = MinimalGame(locations: testRoom)
        let (engine, _) = await GameEngine.test(blueprint: game)
        let proxy = try await engine.location(.startRoom)

        // When
        let change = try await proxy.clearFlag(.inherentlyLit)

        // Then
        #expect(change != nil)
        if let change {
            if case .setLocationProperty(let id, let property, let value) = change {
                #expect(id == .startRoom)
                #expect(property == .inherentlyLit)
                if case .bool(let boolValue) = value {
                    #expect(boolValue == false)
                } else {
                    #expect(Bool(false), "Expected bool value")
                }
            } else {
                #expect(Bool(false), "Expected setLocationProperty case")
            }
        }
    }

    @Test("LocationProxy setProperty creates valid StateChange for description")
    func testSetPropertyCreatesValidStateChangeForDescription() async throws {
        // Given
        let game = MinimalGame()
        let (engine, _) = await GameEngine.test(blueprint: game)
        let proxy = try await engine.location(.startRoom)

        // When
        let change = try await proxy.setProperty(.description, to: "New description")

        // Then
        #expect(change != nil)
        if let change {
            if case .setLocationProperty(let id, let property, let value) = change {
                #expect(id == .startRoom)
                #expect(property == .description)
                if case .string(let stringValue) = value {
                    #expect(stringValue == "New description")
                } else {
                    #expect(Bool(false), "Expected string value")
                }
            } else {
                #expect(Bool(false), "Expected setLocationProperty case")
            }
        }
    }

    @Test("LocationProxy setProperty returns nil when value unchanged")
    func testSetPropertyReturnsNilWhenValueUnchanged() async throws {
        // Given
        let testRoom = Location(
            id: .startRoom,
            .name("Test Room"),
            .description("Existing description")
        )
        let game = MinimalGame(locations: testRoom)
        let (engine, _) = await GameEngine.test(blueprint: game)
        let proxy = try await engine.location(.startRoom)

        // When
        let change = try await proxy.setProperty(.description, to: "Existing description")

        // Then
        #expect(change == nil)
    }

    // MARK: - Description Operations

    @Test("LocationProxy setDescription creates valid StateChange")
    func testSetDescriptionCreatesValidStateChange() async throws {
        // Given
        let game = MinimalGame()
        let (engine, _) = await GameEngine.test(blueprint: game)
        let startRoom = try await engine.location(.startRoom)

        // When
        try await engine.apply(
            startRoom.setDescription(to: "New description")
        )

        // Then
        #expect(try await startRoom.description == "New description")
    }

    // MARK: - Bool Property Operations

    @Test("LocationProxy setProperty Bool creates valid StateChange")
    func testSetPropertyBoolCreatesValidStateChange() async throws {
        // Given
        let game = MinimalGame()
        let (engine, _) = await GameEngine.test(blueprint: game)
        let proxy = try await engine.location(.startRoom)

        // When
        let change = try await proxy.setProperty(.isVisited, to: true)

        // Then
        #expect(change != nil)
        if let change {
            if case .setLocationProperty(let id, let property, let value) = change {
                #expect(id == .startRoom)
                #expect(property == .isVisited)
                if case .bool(let boolValue) = value {
                    #expect(boolValue == true)
                } else {
                    #expect(Bool(false), "Expected bool value")
                }
            } else {
                #expect(Bool(false), "Expected setLocationProperty case")
            }
        }
    }

    // MARK: - Int Property Operations

    @Test("LocationProxy setProperty Int creates valid StateChange")
    func testSetPropertyIntCreatesValidStateChange() async throws {
        // Given
        let game = MinimalGame()
        let (engine, _) = await GameEngine.test(blueprint: game)
        let proxy = try await engine.location(.startRoom)

        // When
        let change = try await proxy.setProperty(LocationPropertyID("visitCount"), to: 5)

        // Then
        #expect(change != nil)
        if let change {
            if case .setLocationProperty(let id, let property, let value) = change {
                #expect(id == .startRoom)
                #expect(property == LocationPropertyID("visitCount"))
                if case .int(let intValue) = value {
                    #expect(intValue == 5)
                } else {
                    #expect(Bool(false), "Expected int value")
                }
            } else {
                #expect(Bool(false), "Expected setLocationProperty case")
            }
        }
    }

    // MARK: - Name Operations

    @Test("LocationProxy setName creates valid StateChange")
    func testSetNameCreatesValidStateChange() async throws {
        // Given
        let game = MinimalGame()
        let (engine, _) = await GameEngine.test(blueprint: game)
        let proxy = try await engine.location(.startRoom)

        // When
        let change = try await proxy.setProperty(.name, to: "New Room Name")

        // Then
        #expect(change != nil)
        if let change {
            if case .setLocationProperty(let id, let property, let value) = change {
                #expect(id == .startRoom)
                #expect(property == .name)
                if case .string(let stringValue) = value {
                    #expect(stringValue == "New Room Name")
                } else {
                    #expect(Bool(false), "Expected string value")
                }
            } else {
                #expect(Bool(false), "Expected setLocationProperty case")
            }
        }
    }

    // MARK: - Complex Operations

    @Test("LocationProxy multiple flag operations")
    func testMultipleFlagOperations() async throws {
        // Given
        let testRoom = Location(
            id: .startRoom,
            .name("Test Room"),
            .inherentlyLit
        )
        let game = MinimalGame(locations: testRoom)
        let (engine, _) = await GameEngine.test(blueprint: game)
        let proxy = try await engine.location(.startRoom)

        // When/Then: Set a new flag
        let setChange = try await proxy.setFlag(.isVisited)
        #expect(setChange != nil)
        if let setChange {
            if case .setLocationProperty(let id, let property, let value) = setChange {
                #expect(id == .startRoom)
                #expect(property == .isVisited)
                if case .bool(let boolValue) = value {
                    #expect(boolValue == true)
                }
            }
        }

        // Apply the change to update the proxy's state
        try await engine.apply(setChange!)

        // Clear an existing flag
        let clearChange = try await proxy.clearFlag(.inherentlyLit)
        #expect(clearChange != nil)
        if let clearChange {
            if case .setLocationProperty(let id, let property, let value) = clearChange {
                #expect(id == .startRoom)
                #expect(property == .inherentlyLit)
                if case .bool(let boolValue) = value {
                    #expect(boolValue == false)
                }
            }
        }
    }

    @Test("LocationProxy StateValue property operations")
    func testStateValuePropertyOperations() async throws {
        // Given
        let game = MinimalGame()
        let (engine, _) = await GameEngine.test(blueprint: game)
        let proxy = try await engine.location(.startRoom)

        // When/Then: Set various property types
        let stringChange = try await proxy.setProperty(.name, to: "New Room Name")
        #expect(stringChange != nil)
        if let stringChange {
            if case .setLocationName(let id, let name) = stringChange {
                #expect(id == .startRoom)
                #expect(name == "New Room Name")
            }
        }

        // Set description property
        let descChange = try await proxy.setProperty(.description, to: "New Description")
        #expect(descChange != nil)
        if let descChange {
            if case .setLocationProperty(let id, let property, let value) = descChange {
                #expect(id == .startRoom)
                #expect(property == .description)
                if case .string(let stringValue) = value {
                    #expect(stringValue == "New Description")
                }
            }
        }
    }
}
