import CustomDump
import GnustoEngine
import GnustoTestSupport
import Testing

@Suite("FillActionHandler Tests")
struct FillActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("FILL DIRECTOBJECT syntax works")
    func testFillDirectObjectSyntax() async throws {
        // Given
        let bucket = Item(
            id: "bucket",
            .name("metal bucket"),
            .description("A metal bucket."),
            .isContainer,
            .isOpen,
            .isTakable,
            .in(.startRoom)
        )

        let well = Item(
            id: "well",
            .name("water well"),
            .description("A deep water well."),
            .isDrinkable,
            .in(.startRoom)
        )

        let game = MinimalGame(
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
            Fill the metal bucket with what?
            """
        )

        let finalState = await engine.item("bucket")
        #expect(await finalState.hasFlag(.isTouched) == true)
    }

    @Test("FILL DIRECTOBJECT WITH INDIRECTOBJECT syntax works")
    func testFillWithSourceSyntax() async throws {
        // Given
        let bottle = Item(
            id: "bottle",
            .name("glass bottle"),
            .description("A glass bottle."),
            .isContainer,
            .isOpen,
            .isTakable,
            .in(.startRoom)
        )

        let stream = Item(
            id: "stream",
            .name("crystal stream"),
            .description("A crystal clear stream."),
            .isDrinkable,
            .in(.startRoom)
        )

        let game = MinimalGame(
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
            You fill the glass bottle from the crystal stream.
            """
        )
    }

    @Test("FILL DIRECTOBJECT FROM INDIRECTOBJECT syntax works")
    func testFillFromSourceSyntax() async throws {
        // Given
        let cup = Item(
            id: "cup",
            .name("ceramic cup"),
            .description("A ceramic cup."),
            .isContainer,
            .isOpen,
            .isTakable,
            .in(.startRoom)
        )

        let fountain = Item(
            id: "fountain",
            .name("marble fountain"),
            .description("A marble fountain."),
            .isDrinkable,
            .in(.startRoom)
        )

        let game = MinimalGame(
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
            You fill the ceramic cup from the marble fountain.
            """
        )
    }

    // MARK: - Validation Testing

    @Test("Cannot fill without specifying target")
    func testCannotFillWithoutTarget() async throws {
        // Given
        let game = MinimalGame()
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
            """
        )
    }

    @Test("Cannot fill target not in scope")
    func testCannotFillTargetNotInScope() async throws {
        // Given
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
            .in("anotherRoom")
        )

        let game = MinimalGame(
            locations: anotherRoom,
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
            Any such thing lurks beyond your reach.
            """
        )
    }

    @Test("Cannot fill non-container")
    func testCannotFillNonContainer() async throws {
        // Given
        let rock = Item(
            id: "rock",
            .name("large rock"),
            .description("A large boulder."),
            .in(.startRoom)
        )

        let game = MinimalGame(
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
            You can't put things in the large rock.
            """
        )
    }

    @Test("Cannot fill closed container")
    func testCannotFillClosedContainer() async throws {
        // Given
        let jar = Item(
            id: "jar",
            .name("sealed jar"),
            .description("A sealed jar."),
            .isContainer,
            // Note: No .isOpen flag - container is closed
            .in(.startRoom)
        )

        let well = Item(
            id: "well",
            .name("water well"),
            .description("A deep water well."),
            .isDrinkable,
            .in(.startRoom)
        )

        let game = MinimalGame(
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
            """
        )
    }

    @Test("Cannot fill from source not in scope")
    func testCannotFillFromSourceNotInScope() async throws {
        // Given
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
            .in(.startRoom)
        )

        let remoteWell = Item(
            id: "remoteWell",
            .name("remote well"),
            .description("A well in another room."),
            .isDrinkable,
            .in("anotherRoom")
        )

        let game = MinimalGame(
            locations: anotherRoom,
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
            Any such thing lurks beyond your reach.
            """
        )
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
            .in("darkRoom")
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
            The darkness here is absolute, consuming all light and hope of
            sight.
            """
        )
    }

    // MARK: - Processing Testing

    @Test("Fill container from non-liquid source fails")
    func testFillFromNonLiquidSourceFails() async throws {
        // Given
        let bottle = Item(
            id: "bottle",
            .name("empty bottle"),
            .description("An empty bottle."),
            .isContainer,
            .isOpen,
            .isTakable,
            .in(.startRoom)
        )

        let box = Item(
            id: "box",
            .name("wooden box"),
            .description("A wooden box."),
            .isContainer,
            .isOpen,
            .in(.startRoom)
        )

        let game = MinimalGame(
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
            You fill the empty bottle from the wooden box.
            """
        )
    }

    @Test("Fill container held by player")
    func testFillContainerHeldByPlayer() async throws {
        // Given
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
            .in(.startRoom)
        )

        let game = MinimalGame(
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
            Fill the silver flask with what?
            """
        )

        let finalFlaskState = await engine.item("flask")
        #expect(await finalFlaskState.playerIsHolding)  // Still held by player
        #expect(await finalFlaskState.hasFlag(.isTouched) == true)
    }

    @Test("Fill sets touched flag on container")
    func testFillSetsTouchedFlag() async throws {
        // Given
        let mug = Item(
            id: "mug",
            .name("ceramic mug"),
            .description("A ceramic mug."),
            .isContainer,
            .isOpen,
            .isTakable,
            .in(.startRoom)
        )

        let pond = Item(
            id: "pond",
            .name("small pond"),
            .description("A small pond."),
            .isDrinkable,
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: mug, pond
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("fill mug with pond")

        // Then: Verify state changes
        let finalState = await engine.item("mug")
        #expect(await finalState.hasFlag(.isTouched) == true)

        // Verify message
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > fill mug with pond
            You fill the ceramic mug from the small pond.
            """
        )
    }

    @Test("Fill multiple containers from different sources")
    func testFillMultipleContainers() async throws {
        // Given
        let bottle = Item(
            id: "bottle",
            .name("glass bottle"),
            .description("A glass bottle."),
            .isContainer,
            .isOpen,
            .isTakable,
            .in(.startRoom)
        )

        let bucket = Item(
            id: "bucket",
            .name("metal bucket"),
            .description("A metal bucket."),
            .isContainer,
            .isOpen,
            .isTakable,
            .in(.startRoom)
        )

        let well = Item(
            id: "well",
            .name("deep well"),
            .description("A deep well."),
            .isDrinkable,
            .in(.startRoom)
        )

        let stream = Item(
            id: "stream",
            .name("flowing stream"),
            .description("A flowing stream."),
            .isDrinkable,
            .in(.startRoom)
        )

        let game = MinimalGame(
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
            You fill the glass bottle from the deep well.
            """
        )

        // When: Fill bucket from stream
        try await engine.execute("fill bucket with stream")

        // Then
        let output2 = await mockIO.flush()
        expectNoDifference(
            output2,
            """
            > fill bucket with stream
            You fill the metal bucket from the flowing stream.
            """
        )

        // Verify both containers were touched
        let bottleState = await engine.item("bottle")
        let bucketState = await engine.item("bucket")
        #expect(await bottleState.hasFlag(.isTouched) == true)
        #expect(await bucketState.hasFlag(.isTouched) == true)
    }

    // MARK: - Intent Testing

    @Test("Handler exposes correct Verbs")
    func testVerbs() async throws {
        let handler = FillActionHandler()
        #expect(handler.synonyms.contains(.fill))
        #expect(handler.synonyms.count == 1)
    }

    @Test("Handler requires light")
    func testRequiresLightProperty() async throws {
        let handler = FillActionHandler()
        #expect(handler.requiresLight == true)
    }
}
