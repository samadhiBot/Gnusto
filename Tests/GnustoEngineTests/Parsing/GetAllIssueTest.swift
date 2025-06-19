import Testing
@testable import GnustoEngine

@Suite("Get All Issue Reproduction Tests")
struct GetAllIssueTests {
    
    @Test("Get all should not show 'all all' error")
    func testGetAllShouldNotShowAllAllError() async throws {
        // Arrange: Set up a basic game with some takable items
        let basket = Item(
            id: "basket",
            .name("wicker basket"),
            .in(.location(.startRoom)),
            .isTakable,
            .size(5)
        )
        let jug = Item(
            id: "jug",
            .name("lemonade jug"),
            .in(.location(.startRoom)),
            .isTakable,
            .size(3)
        )

        let (engine, _) = await GameEngine.test(
            blueprint: MinimalGame(
                player: Player(in: .startRoom, carryingCapacity: 20),
                items: basket, jug
            )
        )

        // Act: Parse "get all" directly
        let result = await engine.parser.parse(
            input: "get all",
            vocabulary: engine.gameState.vocabulary,
            gameState: engine.gameState
        )

        // Assert: Should successfully parse without "all all" error
        switch result {
        case .success(let command):
            #expect(command.verb == .take)
            #expect(command.isAllCommand == true)
            #expect(command.directObjects.count == 2)
            #expect(command.directObjects.contains(.item("basket")))
            #expect(command.directObjects.contains(.item("jug")))
        case .failure(let error):
            Issue.record("Expected successful parsing but got error: \(error)")
        }
    }
} 
