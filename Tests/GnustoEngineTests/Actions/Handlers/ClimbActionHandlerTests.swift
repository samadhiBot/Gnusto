import CustomDump
import Testing
@testable import GnustoEngine

@Suite("ClimbActionHandler Tests")
struct ClimbActionHandlerTests {
    let handler = ClimbActionHandler()

    // MARK: - No Object Tests

    @Test("Climb with no object asks what to climb")
    func testClimbNoObject() async throws {
        let game = MinimalGame()
        let mockIO = await MockIOHandler()
        let engine = await GameEngine(
            blueprint: game,
            parser: MockParser(),
            ioHandler: mockIO
        )

        let command = Command(verb: .climb, rawInput: "climb")
        let context = ActionContext(
            command: command,
            engine: engine
        )

        // Act
        try await handler.validate(context: context)
        let result = try await handler.process(context: context)

        // Assert
        #expect(result.message == "Climb what?")
        #expect(result.stateChanges.isEmpty)
    }

    // MARK: - Exit Traversal Tests

    @Test("Climb stairs to go up")
    func testClimbStairsGoesUp() async throws {
        // Arrange: Create locations with stairs exit
        let kitchen = Location(
            id: "kitchen",
            .name("Kitchen"),
            .exits([
                .up: .to("attic", via: "stairs")
            ]),
            .inherentlyLit,
            .localGlobals("stairs")
        )

        let attic = Location(
            id: "attic",
            .name("Attic"),
            .inherentlyLit
        )

        let stairs = Item(
            id: "stairs",
            .name("stairs"),
            .synonyms("staircase", "stairway", "steps"),
            .isClimbable,
            .in(.nowhere) // Global item
        )

        let player = Player(in: "kitchen")
        let game = MinimalGame(
            player: player,
            locations: [kitchen, attic],
            items: [stairs]
        )

        let mockIO = await MockIOHandler()
        let engine = await GameEngine(
            blueprint: game,
            parser: MockParser(),
            ioHandler: mockIO
        )

        let command = Command(
            verb: .climb,
            directObject: .item("stairs"),
            rawInput: "climb stairs"
        )
        let context = ActionContext(
            command: command,
            engine: engine
        )

        // Act
        await engine.execute(command: command)

        // Assert: Player should have moved to attic
        let finalPlayerLocation = try await engine.playerLocation()
        #expect(finalPlayerLocation.id == "attic")

        // Check that stairs is marked as touched
        let finalStairs = try await engine.item("stairs")
        #expect(finalStairs.hasFlag(.isTouched))
    }

    @Test("Climb ladder to go down")
    func testClimbLadderGoesDown() async throws {
        // Arrange: Create a scenario where ladder enables going down
        let topRoom = Location(
            id: "top",
            .name("Top"),
            .exits([
                .down: .to("bottom", via: "ladder")
            ]),
            .inherentlyLit,
            .localGlobals("ladder")
        )

        let bottomRoom = Location(
            id: "bottom",
            .name("Bottom"),
            .inherentlyLit
        )

        let ladder = Item(
            id: "ladder",
            .name("wooden ladder"),
            .synonyms("ladder"),
            .adjectives("wooden", "rickety"),
            .isClimbable,
            .in(.nowhere) // Global item
        )

        let player = Player(in: "top")
        let game = MinimalGame(
            player: player,
            locations: [topRoom, bottomRoom],
            items: [ladder]
        )

        let mockIO = await MockIOHandler()
        let engine = await GameEngine(
            blueprint: game,
            parser: MockParser(),
            ioHandler: mockIO
        )

        let command = Command(
            verb: .climb,
            directObject: .item("ladder"),
            rawInput: "climb ladder"
        )
        let context = ActionContext(
            command: command,
            engine: engine
        )

        // Act
        await engine.execute(command: command)

        // Assert: Player should have moved to bottom
        let finalPlayerLocation = try await engine.playerLocation()
        #expect(finalPlayerLocation.id == "bottom")
    }

    @Test("Climb rope enables multiple directions")
    func testClimbRopeMultipleDirections() async throws {
        // Arrange: Test rope that enables both up and down
        let middleRoom = Location(
            id: "middle",
            .name("Middle"),
            .exits([
                .up: .to("top", via: "rope"),
                .down: .to("bottom", via: "rope")
            ]),
            .inherentlyLit,
            .localGlobals("rope")
        )

        let topRoom = Location(id: "top", .name("Top"), .inherentlyLit)
        let bottomRoom = Location(id: "bottom", .name("Bottom"), .inherentlyLit)

        let rope = Item(
            id: "rope",
            .name("rope"),
            .synonyms("rope", "hemp", "coil"),
            .isClimbable,
            .in(.nowhere) // Global item
        )

        let player = Player(in: "middle")
        let game = MinimalGame(
            player: player,
            locations: [middleRoom, topRoom, bottomRoom],
            items: [rope]
        )

        let mockIO = await MockIOHandler()
        let engine = await GameEngine(
            blueprint: game,
            parser: MockParser(),
            ioHandler: mockIO
        )

        let command = Command(
            verb: .climb,
            directObject: .item("rope"),
            rawInput: "climb rope"
        )
        let context = ActionContext(
            command: command,
            engine: engine
        )

        // Act
        await engine.execute(command: command)

        // Assert: Should go in first direction found (up)
        let finalPlayerLocation = try await engine.playerLocation()
        #expect(finalPlayerLocation.id == "top")
    }

    // MARK: - Global Object Validation Tests

    @Test("Climb stairs when not present in location")
    func testClimbStairsNotPresent() async throws {
        // Arrange: Location without stairs in localGlobals
        let room = Location(
            id: "room",
            .name("Empty Room"),
            .inherentlyLit
            // No localGlobals with stairs
        )

        let stairs = Item(
            id: "stairs",
            .name("stairs"),
            .isClimbable,
            .in(.nowhere) // Global item
        )

        let player = Player(in: "room")
        let game = MinimalGame(
            player: player,
            locations: [room],
            items: [stairs]
        )

        let mockIO = await MockIOHandler()
        let engine = await GameEngine(
            blueprint: game,
            parser: MockParser(),
            ioHandler: mockIO
        )

        let command = Command(
            verb: .climb,
            directObject: .item("stairs"),
            rawInput: "climb stairs"
        )
        let context = ActionContext(
            command: command,
            engine: engine
        )

        // Act
        await engine.execute(command: command)

        // Assert: Should get error message
        let output = await mockIO.flush()
        expectNoDifference(output, "There is no stairs here.")
    }

    @Test("Climb plural stairs when not present")
    func testClimbPluralStairsNotPresent() async throws {
        // Arrange: Plural stairs not present
        let room = Location(
            id: "room",
            .name("Empty Room"),
            .inherentlyLit
        )

        let pluralStairs = Item(
            id: "stairs",
            .name("stairs"),
            .isPlural,
            .isClimbable,
            .in(.nowhere)
        )

        let player = Player(in: "room")
        let game = MinimalGame(
            player: player,
            locations: [room],
            items: [pluralStairs]
        )

        let mockIO = await MockIOHandler()
        let engine = await GameEngine(
            blueprint: game,
            parser: MockParser(),
            ioHandler: mockIO
        )

        let command = Command(
            verb: .climb,
            directObject: .item("stairs"),
            rawInput: "climb stairs"
        )
        let context = ActionContext(
            command: command,
            engine: engine
        )

        // Act
        await engine.execute(command: command)

        // Assert: Should use "are" for plural
        let output = await mockIO.flush()
        expectNoDifference(output, "There are no stairs here.")
    }

    // MARK: - Regular Climbing Tests

    @Test("Climb climbable object (not used by exits)")
    func testClimbClimbableObject() async throws {
        // Arrange: Climbable tree not used by any exits
        let tree = Item(
            id: "tree",
            .name("oak tree"),
            .synonyms("tree", "oak"),
            .isClimbable,
            .in(.location(.startRoom))
        )

        let game = MinimalGame(items: [tree])
        let mockIO = await MockIOHandler()
        let engine = await GameEngine(
            blueprint: game,
            parser: MockParser(),
            ioHandler: mockIO
        )

        let command = Command(
            verb: .climb,
            directObject: .item("tree"),
            rawInput: "climb tree"
        )
        let context = ActionContext(
            command: command,
            engine: engine
        )

        // Act
        await engine.execute(command: command)

        // Assert: Should get default climbing message
        let output = await mockIO.flush()
        expectNoDifference(output, "You climb the oak tree.")

        // Check that tree is marked as touched
        let finalTree = try await engine.item("tree")
        #expect(finalTree.hasFlag(.isTouched))
    }

    @Test("Climb non-climbable object")
    func testClimbNonClimbableObject() async throws {
        // Arrange: Non-climbable table
        let table = Item(
            id: "table",
            .name("wooden table"),
            .synonyms("table"),
            .adjectives("wooden"),
            .in(.location(.startRoom))
            // No .isClimbable flag
        )

        let game = MinimalGame(items: [table])
        let mockIO = await MockIOHandler()
        let engine = await GameEngine(
            blueprint: game,
            parser: MockParser(),
            ioHandler: mockIO
        )

        let command = Command(
            verb: .climb,
            directObject: .item("table"),
            rawInput: "climb table"
        )
        let context = ActionContext(
            command: command,
            engine: engine
        )

        // Act
        await engine.execute(command: command)

        // Assert: Should get error message
        let output = await mockIO.flush()
        expectNoDifference(output, "You can't climb the wooden table.")
    }

    // MARK: - Error Cases

    @Test("Climb item not in scope fails validation")
    func testClimbItemNotInScope() async throws {
        // Arrange: Item exists but not reachable
        let distantTree = Item(
            id: "tree",
            .name("distant tree"),
            .isClimbable,
            .in(.location("distantPlace")) // Not in player's location
        )

        let game = MinimalGame(items: [distantTree])
        let mockIO = await MockIOHandler()
        let engine = await GameEngine(
            blueprint: game,
            parser: MockParser(),
            ioHandler: mockIO
        )

        let command = Command(
            verb: .climb,
            directObject: .item("tree"),
            rawInput: "climb tree"
        )
        let context = ActionContext(
            command: command,
            engine: engine
        )

        // Act & Assert: Should fail validation
        do {
            try await handler.validate(context: context)
            #expect(Bool(false), "Expected validation to fail")
        } catch {
            #expect(error is ActionResponse)
        }
    }

    @Test("Climb nonexistent item fails validation")
    func testClimbNonexistentItem() async throws {
        let game = MinimalGame()
        let mockIO = await MockIOHandler()
        let engine = await GameEngine(
            blueprint: game,
            parser: MockParser(),
            ioHandler: mockIO
        )

        let command = Command(
            verb: .climb,
            directObject: .item("nonexistent"),
            rawInput: "climb nonexistent"
        )
        let context = ActionContext(
            command: command,
            engine: engine
        )

        // Act & Assert: Should fail validation
        do {
            try await handler.validate(context: context)
            #expect(Bool(false), "Expected validation to fail")
        } catch {
            #expect(error is ActionResponse)
        }
    }

    @Test("Climb non-item entity")
    func testClimbNonItemEntity() async throws {
        let game = MinimalGame()
        let mockIO = await MockIOHandler()
        let engine = await GameEngine(
            blueprint: game,
            parser: MockParser(),
            ioHandler: mockIO
        )

        let command = Command(
            verb: .climb,
            directObject: .player, // Try to climb the player
            rawInput: "climb me"
        )
        let context = ActionContext(
            command: command,
            engine: engine
        )

        // Act & Assert: Should fail validation
        do {
            try await handler.validate(context: context)
            #expect(Bool(false), "Expected validation to fail")
        } catch {
            #expect(error is ActionResponse)
        }
    }

    // MARK: - Movement Failure Tests

    @Test("Climb stairs with blocked exit")
    func testClimbStairsBlockedExit() async throws {
        // Arrange: Stairs present but exit is blocked
        let room = Location(
            id: "room",
            .name("Room"),
            .exits([
                .up: .blocked("The ceiling is too low.") // Blocked exit
            ]),
            .inherentlyLit,
            .localGlobals("stairs")
        )

        let stairs = Item(
            id: "stairs",
            .name("stairs"),
            .isClimbable,
            .in(.nowhere)
        )

        let player = Player(in: "room")
        let game = MinimalGame(
            player: player,
            locations: [room],
            items: [stairs]
        )

        let mockIO = await MockIOHandler()
        let engine = await GameEngine(
            blueprint: game,
            parser: MockParser(),
            ioHandler: mockIO
        )

        let command = Command(
            verb: .climb,
            directObject: .item("stairs"),
            rawInput: "climb stairs"
        )
        let context = ActionContext(
            command: command,
            engine: engine
        )

        // Act
        await engine.execute(command: command)

        // Assert: Should get the blocked exit message
        let output = await mockIO.flush()
        expectNoDifference(output, "The ceiling is too low.")
    }

    @Test("Climb stairs with no exit fails")
    func testClimbStairsNoExit() async throws {
        // Arrange: Stairs present but no exit in any direction
        let room = Location(
            id: "room",
            .name("Room"),
            .inherentlyLit,
            .localGlobals("stairs")
            // No exits at all
        )

        let stairs = Item(
            id: "stairs",
            .name("stairs"),
            .isClimbable,
            .in(.nowhere)
        )

        let player = Player(in: "room")
        let game = MinimalGame(
            player: player,
            locations: [room],
            items: [stairs]
        )

        let mockIO = await MockIOHandler()
        let engine = await GameEngine(
            blueprint: game,
            parser: MockParser(),
            ioHandler: mockIO
        )

        let command = Command(
            verb: .climb,
            directObject: .item("stairs"),
            rawInput: "climb stairs"
        )
        let context = ActionContext(
            command: command,
            engine: engine
        )

        // Act
        try await handler.validate(context: context)
        let result = try await handler.process(context: context)

        // Assert: Should default to regular climbing behavior since no exit uses stairs
        #expect(result.message == "You climb the stairs.")
        #expect(result.stateChanges.count == 2) // Touched and pronoun changes
    }
}
