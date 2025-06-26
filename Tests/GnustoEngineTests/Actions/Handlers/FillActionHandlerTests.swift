import CustomDump
import Testing

@testable import GnustoEngine

@Suite("FillActionHandler Tests")
struct FillActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("FILL DIRECTOBJECT syntax works")
    func testFillDirectObjectSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .description("A room for testing."),
            .inherentlyLit
        )

        let bucket = Item(
            id: "bucket",
            .name("metal bucket"),
            .description("A metal bucket."),
            .isContainer,
            .isOpen,
            .isTakable,
            .in(.location("testRoom"))
        )

        let well = Item(
            id: "well",
            .name("water well"),
            .description("A deep water well."),
            .isDrinkable,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: bucket, well
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("fill bucket")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > fill bucket
            You fill the metal bucket with water well.
            """)

        let finalState = try await engine.item("bucket")
        #expect(finalState.hasFlag(.isTouched) == true)
    }

    @Test("FILL DIRECTOBJECT WITH INDIRECTOBJECT syntax works")
    func testFillWithSourceSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let bottle = Item(
            id: "bottle",
            .name("glass bottle"),
            .description("A glass bottle."),
            .isContainer,
            .isOpen,
            .isTakable,
            .in(.location("testRoom"))
        )

        let stream = Item(
            id: "stream",
            .name("crystal stream"),
            .description("A crystal clear stream."),
            .isDrinkable,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: bottle, stream
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("fill bottle with stream")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > fill bottle with stream
            You fill the glass bottle with crystal stream.
            """)
    }

    @Test("FILL DIRECTOBJECT FROM INDIRECTOBJECT syntax works")
    func testFillFromSourceSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let cup = Item(
            id: "cup",
            .name("ceramic cup"),
            .description("A ceramic cup."),
            .isContainer,
            .isOpen,
            .isTakable,
            .in(.location("testRoom"))
        )

        let fountain = Item(
            id: "fountain",
            .name("marble fountain"),
            .description("A marble fountain."),
            .isDrinkable,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: cup, fountain
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("fill cup from fountain")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > fill cup from fountain
            You fill the ceramic cup with marble fountain.
            """)
    }

    // MARK: - Validation Testing

    @Test("Cannot fill without specifying target")
    func testCannotFillWithoutTarget() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("fill")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > fill
            Fill what?
            """)
    }

    @Test("Cannot fill target not in scope")
    func testCannotFillTargetNotInScope() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let anotherRoom = Location(
            id: "anotherRoom",
            .name("Another Room"),
            .inherentlyLit
        )

        let remoteBucket = Item(
            id: "remoteBucket",
            .name("remote bucket"),
            .description("A bucket in another room."),
            .isContainer,
            .isOpen,
            .in(.location("anotherRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom, anotherRoom,
            items: remoteBucket
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("fill bucket")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > fill bucket
            You can’t see any such thing.
            """)
    }

    @Test("Cannot fill non-container")
    func testCannotFillNonContainer() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let rock = Item(
            id: "rock",
            .name("large rock"),
            .description("A large boulder."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: rock
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("fill rock")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > fill rock
            The large rock is not a container.
            """)
    }

    @Test("Cannot fill closed container")
    func testCannotFillClosedContainer() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let jar = Item(
            id: "jar",
            .name("sealed jar"),
            .description("A sealed jar."),
            .isContainer,
            // Note: No .isOpen flag - container is closed
            .in(.location("testRoom"))
        )

        let well = Item(
            id: "well",
            .name("water well"),
            .description("A deep water well."),
            .isDrinkable,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: jar, well
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("fill jar")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > fill jar
            The sealed jar is closed.
            """)
    }

    @Test("Cannot fill from source not in scope")
    func testCannotFillFromSourceNotInScope() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let anotherRoom = Location(
            id: "anotherRoom",
            .name("Another Room"),
            .inherentlyLit
        )

        let bucket = Item(
            id: "bucket",
            .name("metal bucket"),
            .description("A metal bucket."),
            .isContainer,
            .isOpen,
            .in(.location("testRoom"))
        )

        let remoteWell = Item(
            id: "remoteWell",
            .name("remote well"),
            .description("A well in another room."),
            .isDrinkable,
            .in(.location("anotherRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom, anotherRoom,
            items: bucket, remoteWell
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("fill bucket from well")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > fill bucket from well
            You can’t see any such thing.
            """)
    }

    @Test("Requires light to fill")
    func testRequiresLight() async throws {
        // Given: Dark room with container
        let darkRoom = Location(
            id: "darkRoom",
            .name("Dark Room"),
            .description("A pitch black room.")
            // Note: No .inherentlyLit property
        )

        let bucket = Item(
            id: "bucket",
            .name("metal bucket"),
            .description("A metal bucket."),
            .isContainer,
            .isOpen,
            .in(.location("darkRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: bucket
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("fill bucket")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > fill bucket
            It is pitch black. You can’t see a thing.
            """)
    }

    // MARK: - Processing Testing

    @Test("Fill container from liquid source succeeds")
    func testFillFromLiquidSourceSucceeds() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let pitcher = Item(
            id: "pitcher",
            .name("water pitcher"),
            .description("A water pitcher."),
            .isContainer,
            .isOpen,
            .isTakable,
            .in(.location("testRoom"))
        )

        let tap = Item(
            id: "tap",
            .name("water tap"),
            .description("A water tap."),
            .isDrinkable,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: pitcher, tap
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("fill pitcher with tap")

        // Then: Verify state changes
        let finalState = try await engine.item("pitcher")
        #expect(finalState.hasFlag(.isTouched) == true)

        // Verify message
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > fill pitcher with tap
            You fill the water pitcher with water tap.
            """)
    }

    @Test("Fill container from non-liquid source fails")
    func testFillFromNonLiquidSourceFails() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let bottle = Item(
            id: "bottle",
            .name("empty bottle"),
            .description("An empty bottle."),
            .isContainer,
            .isOpen,
            .isTakable,
            .in(.location("testRoom"))
        )

        let box = Item(
            id: "box",
            .name("wooden box"),
            .description("A wooden box."),
            .isContainer,
            .isOpen,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: bottle, box
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("fill bottle from box")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > fill bottle from box
            There’s no liquid in the wooden box.
            """)
    }

    @Test("Fill with no source available")
    func testFillWithNoSourceAvailable() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let bucket = Item(
            id: "bucket",
            .name("metal bucket"),
            .description("A metal bucket."),
            .isContainer,
            .isOpen,
            .isTakable,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: bucket
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("fill bucket")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > fill bucket
            There’s no liquid source available.
            """)
    }

    @Test("Fill container held by player")
    func testFillContainerHeldByPlayer() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let flask = Item(
            id: "flask",
            .name("silver flask"),
            .description("A silver flask."),
            .isContainer,
            .isOpen,
            .isTakable,
            .in(.player)
        )

        let spring = Item(
            id: "spring",
            .name("natural spring"),
            .description("A natural spring."),
            .isDrinkable,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: flask, spring
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("fill flask")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > fill flask
            You fill the silver flask with natural spring.
            """)

        let finalFlaskState = try await engine.item("flask")
        #expect(finalFlaskState.parent == .player)  // Still held by player
        #expect(finalFlaskState.hasFlag(.isTouched) == true)
    }

    @Test("Fill sets touched flag on container")
    func testFillSetsTouchedFlag() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let mug = Item(
            id: "mug",
            .name("ceramic mug"),
            .description("A ceramic mug."),
            .isContainer,
            .isOpen,
            .isTakable,
            .in(.location("testRoom"))
        )

        let pond = Item(
            id: "pond",
            .name("small pond"),
            .description("A small pond."),
            .isDrinkable,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: mug, pond
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("fill mug with pond")

        // Then: Verify state changes
        let finalState = try await engine.item("mug")
        #expect(finalState.hasFlag(.isTouched) == true)

        // Verify message
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > fill mug with pond
            You fill the ceramic mug with small pond.
            """)
    }

    @Test("Fill multiple containers from different sources")
    func testFillMultipleContainers() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let bottle = Item(
            id: "bottle",
            .name("glass bottle"),
            .description("A glass bottle."),
            .isContainer,
            .isOpen,
            .isTakable,
            .in(.location("testRoom"))
        )

        let bucket = Item(
            id: "bucket",
            .name("metal bucket"),
            .description("A metal bucket."),
            .isContainer,
            .isOpen,
            .isTakable,
            .in(.location("testRoom"))
        )

        let well = Item(
            id: "well",
            .name("deep well"),
            .description("A deep well."),
            .isDrinkable,
            .in(.location("testRoom"))
        )

        let stream = Item(
            id: "stream",
            .name("flowing stream"),
            .description("A flowing stream."),
            .isDrinkable,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: bottle, bucket, well, stream
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Fill bottle from well
        try await engine.execute("fill bottle from well")

        // Then
        let output1 = await mockIO.flush()
        expectNoDifference(
            output1,
            """
            > fill bottle from well
            You fill the glass bottle with deep well.
            """)

        // When: Fill bucket from stream
        try await engine.execute("fill bucket with stream")

        // Then
        let output2 = await mockIO.flush()
        expectNoDifference(
            output2,
            """
            > fill bucket with stream
            You fill the metal bucket with flowing stream.
            """)

        // Verify both containers were touched
        let bottleState = try await engine.item("bottle")
        let bucketState = try await engine.item("bucket")
        #expect(bottleState.hasFlag(.isTouched) == true)
        #expect(bucketState.hasFlag(.isTouched) == true)
    }

    // MARK: - Intent Testing

    @Test("Handler exposes correct Intents")
    func testIntents() async throws {
        let handler = FillActionHandler()
        // FillActionHandler doesn’t specify actions, so it should be empty
        #expect(handler.actions.isEmpty)
    }

    @Test("Handler exposes correct Verbs")
    func testVerbs() async throws {
        let handler = FillActionHandler()
        #expect(handler.verbs.contains(.fill))
        #expect(handler.verbs.count == 1)
    }

    @Test("Handler requires light")
    func testRequiresLightProperty() async throws {
        let handler = FillActionHandler()
        #expect(handler.requiresLight == true)
    }
}
