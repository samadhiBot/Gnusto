import CustomDump
import GnustoEngine
import GnustoTestSupport
import Testing

// MARK: - Custom Property IDs for Testing

extension ItemPropertyID {
    static let brightness = ItemPropertyID("brightness")
    static let reflectionLevel = ItemPropertyID("reflectionLevel")
    static let weight = ItemPropertyID("weight")
}

extension LocationPropertyID {
    static let ambientLight = LocationPropertyID("ambientLight")
}

@Suite("Circular Dependency Integration Tests")
struct CircularDependencyIntegrationTests {

    // MARK: - Test Data

    let testRoom = Location(
        id: .startRoom,
        .name("Test Room"),
        .description("A room for testing circular dependencies."),
        .inherentlyLit
    )

    let lamp = Item(
        id: "lamp",
        .name("magical lamp"),
        .description("A lamp whose brightness depends on nearby reflections."),
        .isTakable,
        .isLightSource,
        .in(.startRoom)
    )

    let mirror = Item(
        id: "mirror",
        .name("enchanted mirror"),
        .description("A mirror that reflects magical light."),
        .isTakable,
        .in(.startRoom)
    )

    let crystalCave = Location(
        id: "crystalCave",
        .name("Crystal Cave"),
        .description("A cave whose illumination depends on magical items."),
        .inherentlyLit
    )

    // MARK: - Computer Definitions

    /// Lamp computer that depends on mirror's reflection level
    static let lampComputer = ItemComputer(for: "lamp") {
        itemProperty(.brightness) { context in
            // This creates a circular dependency: lamp.brightness → mirror.reflectionLevel → lamp.brightness
            let mirror = await context.item("mirror")
            let reflectionLevel = await mirror.property(.reflectionLevel) ?? 0
            let baseValue = await context.item.property(.brightness)?.toInt ?? 50
            return .int(baseValue + (reflectionLevel.toInt ?? 0))
        }
    }

    /// Mirror computer that depends on lamp's brightness
    static let mirrorComputer = ItemComputer(for: "mirror") {
        itemProperty(.reflectionLevel) { context in
            // This completes the circular dependency: mirror.reflectionLevel → lamp.brightness → mirror.reflectionLevel
            let lamp = await context.item("lamp")
            let brightness = await lamp.property(.brightness) ?? .int(0)
            return .int((brightness.toInt ?? 0) / 2)
        }
    }

    /// Cave computer that depends on lamp brightness (for mixed entity circular dependency)
    static let caveComputer = LocationComputer(for: "crystalCave") {
        locationProperty(LocationPropertyID.ambientLight) { context in
            // This could create a three-way circular dependency if lamp depends on cave
            let lamp = await context.item("lamp")
            let brightness = await lamp.property(.brightness) ?? .int(0)
            return .int((brightness.toInt ?? 0) * 2)
        }
    }

    /// Lamp computer that depends on location (creates item → location → item cycle)
    static let lampLocationDependentComputer = ItemComputer(for: "lamp") {
        itemProperty(.brightness) { context in
            let location = await context.location("crystalCave")
            let ambientLight =
                await location.property(LocationPropertyID.ambientLight) ?? .int(0)
            return .int(50 + (ambientLight.toInt ?? 0))
        }
    }

    // MARK: - Test Games

    func createCircularItemGame() -> GameBlueprint {
        MinimalGame(
            items: lamp, mirror,
            itemComputers: [
                "lamp": Self.lampComputer,
                "mirror": Self.mirrorComputer,
            ]
        )
    }

    func createMixedCircularGame() -> GameBlueprint {
        MinimalGame(
            player: Player(in: "crystalCave"),
            locations: crystalCave,
            items: lamp, mirror,
            itemComputers: [
                "lamp": Self.lampLocationDependentComputer
            ],
            locationComputers: [
                "crystalCave": Self.caveComputer
            ]
        )
    }

    // MARK: - Integration Tests

    @Test("Gracefully handles circular dependency between item properties through proxies")
    func handlesItemCircularDependencyThroughProxies() async throws {
        let game = createCircularItemGame()
        let (engine, _) = await GameEngine.test(blueprint: game)

        // Accessing lamp.brightness should trigger the circular dependency detection
        // and gracefully fall back to static values (nil in this case)
        // lamp.brightness → mirror.reflectionLevel → lamp.brightness (fallback to nil)
        let lampProxy = await engine.item("lamp")

        // Should not throw an error, but successfully compute using fallback values
        // lamp.brightness calls mirror.reflectionLevel, which calls lamp.brightness (circular!)
        // Inner lamp.brightness short-circuits to nil, so mirror.reflectionLevel = 0 / 2 = 0
        // Then lamp.brightness = 50 + 0 = 50
        let brightness = await lampProxy.property(.brightness)
        #expect(brightness?.toInt == 50, "Should gracefully compute using fallback values")

        // Mirror should now compute successfully using the computed lamp brightness
        // mirror.reflectionLevel = 50 / 2 = 25
        let mirrorProxy = await engine.item("mirror")
        let reflectionLevel = await mirrorProxy.property(.reflectionLevel)
        #expect(reflectionLevel?.toInt == 25, "Should gracefully compute using computed brightness")
    }

    @Test("Gracefully handles circular dependency starting from mirror")
    func handlesCircularDependencyFromMirror() async throws {
        let game = createCircularItemGame()
        let (engine, _) = await GameEngine.test(blueprint: game)

        // Accessing mirror.reflectionLevel should trigger circular dependency detection
        // and gracefully fall back to static values
        // mirror.reflectionLevel → lamp.brightness → mirror.reflectionLevel (fallback to nil)
        let mirrorProxy = await engine.item("mirror")

        // Should not throw an error, but successfully compute using fallback values
        // mirror.reflectionLevel calls lamp.brightness, which calls mirror.reflectionLevel (circular!)
        // Inner mirror.reflectionLevel short-circuits to nil, so lamp.brightness = 50 + 0 = 50
        // Then mirror.reflectionLevel = 50 / 2 = 25
        let reflectionLevel = await mirrorProxy.property(.reflectionLevel)
        #expect(reflectionLevel?.toInt == 25, "Should gracefully compute using fallback values")

        // Lamp should also compute successfully when accessed fresh
        // With TaskLocal tracking, each computation starts fresh:
        // lamp.brightness → mirror.reflectionLevel → lamp.brightness (circular!)
        // Inner lamp.brightness returns nil, so mirror.reflectionLevel = 0/2 = 0
        // Final lamp.brightness = 50 + 0 = 50
        let lampProxy = await engine.item("lamp")
        let brightness = await lampProxy.property(.brightness)
        #expect(
            brightness?.toInt == 50, "Should gracefully compute with predictable fallback behavior")
    }

    @Test("Gracefully handles mixed item-location circular dependency")
    func handlesMixedCircularDependency() async throws {
        let game = createMixedCircularGame()
        let (engine, _) = await GameEngine.test(blueprint: game)

        // Accessing lamp.brightness should trigger circular dependency detection:
        // lamp.brightness → crystalCave.ambientLight → lamp.brightness (fallback to nil)
        let lampProxy = await engine.item("lamp")

        // Should not throw an error, but successfully compute using fallback values
        // When lamp.brightness tries to compute, it calls ambientLight, which calls brightness back (circular!)
        // The inner brightness call returns nil (fallback), so ambientLight = 0*2 = 0
        // Then lamp.brightness = 50 + 0 = 50
        let brightness = await lampProxy.property(.brightness)
        #expect(brightness?.toInt == 50, "Should gracefully compute using fallback values")

        // When we access ambientLight directly, it computes based on the now-computed brightness
        // ambientLight = brightness*2 = 50*2 = 100
        let caveProxy = await engine.location("crystalCave")
        let ambientLight = await caveProxy.property(LocationPropertyID.ambientLight)
        #expect(
            ambientLight?.toInt == 100, "Should gracefully compute using current brightness value")
    }

    @Test("Non-circular dependencies work correctly")
    func nonCircularDependenciesWork() async throws {
        // Create a game with a lamp that has static brightness
        let staticLamp = Item(
            id: "staticLamp",
            .name("static lamp"),
            ItemProperty(id: .brightness, rawValue: .int(75)),
            .in(.startRoom)
        )

        let dependentMirror = Item(
            id: "dependentMirror",
            .name("dependent mirror"),
            .in(.startRoom)
        )

        // Mirror depends on lamp, but lamp doesn't depend on mirror (no cycle)
        let safeMirrorComputer = ItemComputer(for: "safeMirror") {
            itemProperty(.reflectionLevel) { context in
                let lamp = await context.item("staticLamp")
                let brightness = await lamp.property(.brightness) ?? .int(0)
                return .int((brightness.toInt ?? 0) / 3)
            }
        }

        let safeGame = MinimalGame(
            items: staticLamp, dependentMirror,
            itemComputers: [
                "dependentMirror": safeMirrorComputer
            ]
        )

        let (engine, _) = await GameEngine.test(blueprint: safeGame)

        // This should work without throwing
        let mirrorProxy = await engine.item("dependentMirror")
        let reflectionLevel = await mirrorProxy.property(.reflectionLevel)

        #expect(reflectionLevel?.toInt == 25)  // 75 / 3 = 25
    }

    @Test("Computation tracker resets after circular dependency fallback")
    func computationTrackerResetsAfterCircularDependency() async throws {
        let game = createCircularItemGame()
        let (engine, _) = await GameEngine.test(blueprint: game)

        let lampProxy = await engine.item("lamp")

        // First attempt should gracefully compute using fallback values
        let brightness1 = await lampProxy.property(.brightness)
        #expect(brightness1?.toInt == 50, "Should gracefully compute using fallback values")

        // Computation tracker should be reset, so we can try again and get the same result
        let brightness2 = await lampProxy.property(.brightness)
        #expect(brightness2?.toInt == 50, "Should gracefully compute consistently")

        // Note: With the new TaskLocal-based tracking system, computation state
        // is automatically managed and cleaned up without external verification needed
    }

    @Test("Different properties on same item work independently")
    func differentPropertiesWorkIndependently() async throws {
        let testItem = Item(
            id: "complexItem",
            .name("complex item"),
            .description("Static description"),
            ItemProperty(id: .brightness, rawValue: .int(100)),
            .in(.startRoom)
        )

        // Computer that only handles weight, leaving other properties as static
        let partialComputer = ItemComputer(for: "testItem") {
            itemProperty(.weight) { context in
                return .int(42)
            }
        }

        let game = MinimalGame(
            items: testItem,
            itemComputers: [
                "complexItem": partialComputer
            ]
        )

        let (engine, _) = await GameEngine.test(blueprint: game)
        let itemProxy = await engine.item("complexItem")

        // Static properties should work normally
        let description = await itemProxy.property(.description)
        #expect(description?.toString == "Static description")

        let brightness = await itemProxy.property(.brightness)
        #expect(brightness?.toInt == 100)

        // Computed property should work
        let weight = await itemProxy.property(.weight)
        #expect(weight?.toInt == 42)
    }
}
