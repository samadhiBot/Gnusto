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
        
        let player = Player(in: .startRoom, carryingCapacity: 20)
        let game = MinimalGame(player: player, items: [basket, jug])
        let mockIO = await MockIOHandler()
        let parser = StandardParser()
        let engine = await GameEngine(blueprint: game, parser: parser, ioHandler: mockIO)
        
        // Act: Parse "get all" directly
        let vocabulary = Vocabulary.build(items: [basket, jug])
        let gameState = await engine.gameState
        
        let result = parser.parse(
            input: "get all",
            vocabulary: vocabulary,
            gameState: gameState
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