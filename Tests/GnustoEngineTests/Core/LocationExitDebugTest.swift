import CustomDump
import Foundation
import GnustoEngine
import GnustoTestSupport
import Testing

@Suite("Location Exit Debug Tests")
struct LocationExitDebugTest {
    @Test("Location exits are stored correctly with chained syntax")
    func testLocationExitsAreStored() async throws {
        // Given: Create a location with chained .north() syntax
        let roundRoom = Location("roundRoom")
            .name("Round Room")
            .description("A room for testing.")
            .inherentlyLit
            .north("northRoom")

        // Then: Check that the exits property is set correctly
        let exitsProperty = roundRoom.properties[.exits]
        #expect(exitsProperty != nil, "Exits property should be set")

        if case .exits(let exitSet) = exitsProperty {
            #expect(exitSet.count == 1, "Should have exactly 1 exit")

            let exit = exitSet.first!
            #expect(exit.direction == Direction.north, "Exit should be in north direction")
            #expect(exit.destinationID == "northRoom", "Exit should lead to northRoom")
        } else {
            Issue.record("Exits property should be a .exits case")
        }
    }

    @Test("Location exits work through proxy")
    func testLocationExitsThroughProxy() async throws {
        // Given
        let roundRoom = Location("roundRoom")
            .name("Round Room")
            .description("A room for testing.")
            .inherentlyLit
            .north("northRoom")

        let northRoom = Location("northRoom")
            .name("North Room")
            .description("A room to the north.")
            .inherentlyLit

        let game = MinimalGame(
            player: Player(in: "roundRoom"),
            locations: roundRoom, northRoom
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        // When: Get the location through the engine
        let locationProxy = await engine.location("roundRoom")
        let exits = await locationProxy.exits

        // Then: Check that exits are accessible through proxy
        #expect(exits.count == 1, "Should have exactly 1 exit through proxy")

        if let exit = exits.first {
            #expect(exit.direction == Direction.north, "Exit should be in north direction")
            #expect(exit.destinationID == "northRoom", "Exit should lead to northRoom")
        } else {
            Issue.record("Should have found an exit")
        }
    }

    @Test("Multiple chained direction methods work")
    func testMultipleChainedDirections() async throws {
        // Given: Create a location with multiple chained direction methods
        let crossroads = Location("crossroads")
            .name("Crossroads")
            .inherentlyLit
            .north("northRoom")
            .south("southRoom")
            .east("eastRoom")
            .west("westRoom")

        // Then: Check that all exits are stored
        if case .exits(let exitSet) = crossroads.properties[.exits] {
            #expect(exitSet.count == 4, "Should have exactly 4 exits")

            let directions = Set(exitSet.map { $0.direction })
            #expect(directions.contains(Direction.north))
            #expect(directions.contains(Direction.south))
            #expect(directions.contains(Direction.east))
            #expect(directions.contains(Direction.west))
        } else {
            Issue.record("Exits property should be a .exits case")
        }
    }
}
