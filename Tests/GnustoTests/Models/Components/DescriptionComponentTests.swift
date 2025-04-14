import CustomDump
import Testing

@testable import Gnusto

@Suite("Description Component Tests")
struct DescriptionComponentTests {
    @Test("Objects can be found by adjectives")
    func testAdjectiveFinding() throws {
        let world = World()

        // Create objects first
        let testRoom = Object.room(
            id: "testRoom",
            name: "Test Room",
            description: "A simple test room."
        )

        let cloak = Object.item(
            id: "cloak",
            name: "velvety cloak",
            description: "A luxurious velvet cloak.",
            flags: .wearable,
            synonyms: "cape",
            adjectives: "velvety", "luxurious", "black",
            location: "testRoom"
        )

        // Add objects to world
        world.add(testRoom, cloak)
        // Player added by default, move them
        world.movePlayer(to: "testRoom")

        // Test finding by name
        let byName = world.find(named: "cloak")
        #expect(byName.count == 1)
        #expect(byName.first?.id == "cloak")

        // Test finding by synonym
        let bySynonym = world.find(named: "cape")
        #expect(bySynonym.count == 1)
        #expect(bySynonym.first?.id == "cloak")

        // Test finding by adjective
        let byAdjective = world.find(named: "velvety")
        #expect(byAdjective.count == 1)
        #expect(byAdjective.first?.id == "cloak")

        // Test finding by multiple adjectives
        let byMultipleAdjectives = world.find(named: "luxurious black")
        #expect(byMultipleAdjectives.count == 1)
        #expect(byMultipleAdjectives.first?.id == "cloak")

        // Test finding by adjective and name
        let byAdjectiveAndName = world.find(named: "velvety cloak")
        #expect(byAdjectiveAndName.count == 1)
        #expect(byAdjectiveAndName.first?.id == "cloak")

        // Test finding by adjective and synonym
        let byAdjectiveAndSynonym = world.find(named: "black cape")
        #expect(byAdjectiveAndSynonym.count == 1)
        #expect(byAdjectiveAndSynonym.first?.id == "cloak")

        // Test finding by multiple adjectives and name
        let byMultipleAdjectivesAndName = world.find(named: "luxurious black cloak")
        #expect(byMultipleAdjectivesAndName.count == 1)
        #expect(byMultipleAdjectivesAndName.first?.id == "cloak")

        // Test finding by multiple adjectives and synonym
        let byMultipleAdjectivesAndSynonym = world.find(named: "velvety luxurious cape")
        #expect(byMultipleAdjectivesAndSynonym.count == 1)
        #expect(byMultipleAdjectivesAndSynonym.first?.id == "cloak")

        // Test finding with non-matching adjective
        let byNonMatchingAdjective = world.find(named: "red")
        #expect(byNonMatchingAdjective.isEmpty)

        // Test finding with non-matching adjective and name
        let byNonMatchingAdjectiveAndName = world.find(named: "red cloak")
        #expect(byNonMatchingAdjectiveAndName.isEmpty)
    }
}
