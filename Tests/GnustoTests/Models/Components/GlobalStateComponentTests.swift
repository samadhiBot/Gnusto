//import Testing
//import CustomDump
//
//@testable import Gnusto
//
//@Suite("GlobalStateComponent Tests")
//struct GlobalStateComponentTests {
//    @Test("Basic component functionality")
//    func testBasicComponentFunctionality() {
//        var component = GlobalStateComponent()
//        component.set(42, for: "answer")
//        component.set(true, for: "flag")
//        component.set("hello", for: "greeting")
//
//        #expect(component.get("answer") == 42)
//        #expect(component.get("flag") == true)
//        #expect(component.get("greeting") == "hello")
//
//        #expect(component.has("answer"))
//        #expect(!component.has("nonexistent"))
//
//        component.remove("flag")
//        #expect(!component.has("flag"))
//
//        component.clear()
//        #expect(!component.has("answer"))
//        #expect(!component.has("greeting"))
//    }
//
//    @Test("World global state integration")
//    func testWorldGlobalState() throws {
//        let world = World()
//        world.setGlobalState(42, for: "answer")
//        world.setGlobalState(true, for: "light_on")
//        world.setGlobalState("active", for: "game_state")
//
//        #expect(world.getGlobalState("answer") == 42)
//        #expect(world.getGlobalState("light_on") == true)
//
//        // Use expectNoDifference for string comparison as per project conventions
//        expectNoDifference(world.getGlobalState("game_state"), "active")
//
//        #expect(world.hasGlobalState("answer"))
//        #expect(!world.hasGlobalState("nonexistent"))
//
//        world.removeGlobalState("light_on")
//        #expect(!world.hasGlobalState("light_on"))
//
//        // Make sure the world object persists
//        guard let worldObject = world.find("world") else {
//            throw TestFailure("Failed to get world object")
//        }
//
//        guard let _ = worldObject.find(GlobalStateComponent.self) else {
//            throw TestFailure("Failed to get global state component from world object")
//        }
//    }
//
//    @Test("Complex types in global state")
//    func testComplexTypesInGlobalState() {
//        let world = World()
//
//        // Test with array
//        let array = ["one", "two", "three"]
//        world.setGlobalState(array, for: "string_array")
//        expectNoDifference(world.getGlobalState("string_array"), ["one", "two", "three"])
//
//        // Test with dictionary
//        let dictionary = ["name": "player", "role": "adventurer"]
//        world.setGlobalState(dictionary, for: "player_info")
//        expectNoDifference(world.getGlobalState("player_info"), ["name": "player", "role": "adventurer"])
//
//        // Test with custom struct
//        struct GameScore: Sendable, Equatable {
//            let points: Int
//            let level: Int
//        }
//
//        let score = GameScore(points: 100, level: 5)
//        world.setGlobalState(score, for: "game_score")
//        expectNoDifference(world.getGlobalState("game_score"), GameScore(points: 100, level: 5))
//    }
//}
