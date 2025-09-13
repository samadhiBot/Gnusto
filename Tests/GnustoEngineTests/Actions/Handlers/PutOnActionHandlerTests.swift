import CustomDump
import GnustoEngine
import GnustoTestSupport
import Testing

@Suite("PutOnActionHandler Tests")
struct PutOnActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("PUT DIRECTOBJECT ON INDIRECTOBJECT syntax works")
    func testPutOnSyntax() async throws {
        // Given
        let book = Item(
            id: "book",
            .name("red book"),
            .description("A small red book."),
            .isTakable,
            .in(.player)
        )

        let table = Item(
            id: "table",
            .name("wooden table"),
            .description("A sturdy wooden table."),
            .isSurface,
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: book, table
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("put book on table")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > put book on table
            The red book comes to rest upon the wooden table.
            """
        )

        let finalBook = try await engine.item("book")
        let finalTable = try await engine.item("table")
        #expect(try await finalBook.parent == .item(table.proxy(engine)))
        #expect(await finalBook.hasFlag(.isTouched) == true)
        #expect(await finalTable.hasFlag(.isTouched) == true)
    }

    @Test("PLACE syntax works")
    func testPlaceSyntax() async throws {
        // Given
        let cup = Item(
            id: "cup",
            .name("coffee cup"),
            .description("A white coffee cup."),
            .isTakable,
            .in(.player)
        )

        let desk = Item(
            id: "desk",
            .name("office desk"),
            .description("A large office desk."),
            .isSurface,
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: cup, desk
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("place cup on desk")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > place cup on desk
            The coffee cup comes to rest upon the office desk.
            """
        )
    }

    @Test("SET syntax works")
    func testSetSyntax() async throws {
        // Given
        let vase = Item(
            id: "vase",
            .name("crystal vase"),
            .description("A delicate crystal vase."),
            .isTakable,
            .in(.player)
        )

        let shelf = Item(
            id: "shelf",
            .name("wooden shelf"),
            .description("A high wooden shelf."),
            .isSurface,
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: vase, shelf
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("set vase on shelf")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > set vase on shelf
            The crystal vase comes to rest upon the wooden shelf.
            """
        )
    }

    @Test("BALANCE syntax works")
    func testBalanceSyntax() async throws {
        // Given
        let ball = Item(
            id: "ball",
            .name("rubber ball"),
            .description("A bouncy rubber ball."),
            .isTakable,
            .in(.player)
        )

        let post = Item(
            id: "post",
            .name("fence post"),
            .description("A wooden fence post."),
            .isSurface,
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: ball, post
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("balance ball on post")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > balance ball on post
            The rubber ball comes to rest upon the fence post.
            """
        )
    }

    @Test("HANG syntax works")
    func testHangSyntax() async throws {
        // Given
        let coat = Item(
            id: "coat",
            .name("winter coat"),
            .description("A warm winter coat."),
            .isTakable,
            .in(.player)
        )

        let hook = Item(
            id: "hook",
            .name("coat hook"),
            .description("A metal coat hook."),
            .isSurface,
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: coat, hook
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("hang coat on hook")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > hang coat on hook
            The winter coat comes to rest upon the coat hook.
            """
        )
    }

    // MARK: - Validation Testing

    @Test("Cannot put without specifying on what")
    func testCannotPutWithoutOnWhat() async throws {
        // Given
        let book = Item(
            id: "book",
            .name("red book"),
            .description("A small red book."),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            items: book
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("put book")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > put book
            Put the red book on what?
            """
        )
    }

    @Test("Cannot put without any objects")
    func testCannotPutWithoutAnyObjects() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("put")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > put
            Put what?
            """
        )
    }

    @Test("Cannot put non-existent item")
    func testCannotPutNonExistentItem() async throws {
        // Given
        let table = Item(
            id: "table",
            .name("wooden table"),
            .description("A sturdy wooden table."),
            .isSurface,
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: table
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("put nonexistent on table")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > put nonexistent on table
            You cannot reach any such thing from here.
            """
        )
    }

    @Test("Cannot put on non-existent surface")
    func testCannotPutOnNonExistentSurface() async throws {
        // Given
        let book = Item(
            id: "book",
            .name("red book"),
            .description("A small red book."),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            items: book
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("put book on nonexistent")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > put book on nonexistent
            Any such thing remains frustratingly inaccessible.
            """
        )
    }

    @Test("Cannot put item not held")
    func testCannotPutItemNotHeld() async throws {
        // Given
        let book = Item(
            id: "book",
            .name("red book"),
            .description("A small red book."),
            .isTakable,
            .in(.startRoom)
        )

        let table = Item(
            id: "table",
            .name("wooden table"),
            .description("A sturdy wooden table."),
            .isSurface,
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: book, table
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("put book on table")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > put book on table
            You aren't holding the red book.
            """
        )
    }

    @Test("Cannot put on surface not in scope")
    func testCannotPutOnSurfaceNotInScope() async throws {
        // Given
        let anotherRoom = Location(
            id: "anotherRoom",
            .name("Another Room"),
            .inherentlyLit
        )

        let book = Item(
            id: "book",
            .name("red book"),
            .description("A small red book."),
            .isTakable,
            .in(.player)
        )

        let remoteTable = Item(
            id: "remoteTable",
            .name("remote table"),
            .description("A table in another room."),
            .isSurface,
            .in("anotherRoom")
        )

        let game = MinimalGame(
            locations: anotherRoom,
            items: book, remoteTable
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("put book on table")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > put book on table
            Any such thing remains frustratingly inaccessible.
            """
        )
    }

    @Test("Cannot put location")
    func testCannotPutLocation() async throws {
        // Given
        let table = Item(
            id: "table",
            .name("wooden table"),
            .description("A sturdy wooden table."),
            .isSurface,
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: table
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("put testRoom on table")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > put testRoom on table
            You cannot reach any such thing from here.
            """
        )
    }

    @Test("Cannot put player")
    func testCannotPutPlayer() async throws {
        // Given
        let table = Item(
            id: "table",
            .name("wooden table"),
            .description("A sturdy wooden table."),
            .isSurface,
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: table
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("put me on table")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > put me on table
            You are not an object to be placed upon things.
            """
        )
    }

    @Test("Cannot put on location")
    func testCannotPutOnLocation() async throws {
        // Given
        let book = Item(
            id: "book",
            .name("red book"),
            .description("A small red book."),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            items: book
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("put book on testRoom")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > put book on testRoom
            Any such thing remains frustratingly inaccessible.
            """
        )
    }

    @Test("Cannot put on player")
    func testCannotPutOnPlayer() async throws {
        // Given
        let book = Item(
            id: "book",
            .name("red book"),
            .description("A small red book."),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            items: book
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("put book on me")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > put book on me
            You cannot balance the red book there, physics be damned.
            """
        )
    }

    @Test("Cannot put item on itself")
    func testCannotPutItemOnItself() async throws {
        // Given
        let table = Item(
            id: "table",
            .name("wooden table"),
            .description("A sturdy wooden table."),
            .isTakable,
            .isSurface,
            .in(.player)
        )

        let game = MinimalGame(
            items: table
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("put table on table")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > put table on table
            The wooden table cannot rest upon itself--that way lies
            madness.
            """
        )
    }

    @Test("Cannot put on non-surface item")
    func testCannotPutOnNonSurfaceItem() async throws {
        // Given
        let book = Item(
            id: "book",
            .name("red book"),
            .description("A small red book."),
            .isTakable,
            .in(.player)
        )

        let rock = Item(
            id: "rock",
            .name("large rock"),
            .description("A large boulder."),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: book, rock
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("put book on rock")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > put book on rock
            You can't put things on the large rock.
            """
        )
    }

    @Test("Cannot put circular placement - container")
    func testCannotPutCircularPlacementContainer() async throws {
        // Given
        let box = Item(
            id: "box",
            .name("wooden box"),
            .description("A wooden storage box."),
            .isTakable,
            .isContainer,
            .isSurface,
            .in(.player)
        )

        let plate = Item(
            id: "plate",
            .name("dinner plate"),
            .description("A ceramic dinner plate."),
            .isTakable,
            .isSurface,
            .in(.item("box"))
        )

        let game = MinimalGame(
            items: box, plate
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("put box on plate")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > put box on plate
            You can't put the wooden box on the dinner plate because the
            dinner plate is on the wooden box.
            """
        )
    }

    @Test("Cannot put circular placement - surface")
    func testCannotPutCircularPlacementSurface() async throws {
        // Given
        let tray = Item(
            id: "tray",
            .name("serving tray"),
            .description("A silver serving tray."),
            .isTakable,
            .isSurface,
            .in(.player)
        )

        let coaster = Item(
            id: "coaster",
            .name("drink coaster"),
            .description("A cork drink coaster."),
            .isTakable,
            .isSurface,
            .in(.item("tray"))
        )

        let game = MinimalGame(
            items: tray, coaster
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("put tray on coaster")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > put tray on coaster
            You can't put the serving tray on the drink coaster because the
            drink coaster is on the serving tray.
            """
        )
    }

    @Test("Requires light to put")
    func testRequiresLight() async throws {
        // Given: Dark room with items
        let darkRoom = Location(
            id: "darkRoom",
            .name("Dark Room"),
            .description("A pitch black room.")
            // Note: No .inherentlyLit property
        )

        let book = Item(
            id: "book",
            .name("red book"),
            .description("A small red book."),
            .isTakable,
            .in(.player)
        )

        let table = Item(
            id: "table",
            .name("wooden table"),
            .description("A sturdy wooden table."),
            .isSurface,
            .in("darkRoom")
        )

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: book, table
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("put book on table")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > put book on table
            The darkness here is absolute, consuming all light and hope of
            sight.
            """
        )
    }

    // MARK: - Processing Testing

    @Test("Put item moves item to surface")
    func testPutItemMovesItemToSurface() async throws {
        // Given
        let coin = Item(
            id: "coin",
            .name("gold coin"),
            .description("A shiny gold coin."),
            .isTakable,
            .in(.player)
        )

        let counter = Item(
            id: "counter",
            .name("kitchen counter"),
            .description("A marble kitchen counter."),
            .isSurface,
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: coin, counter
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Verify initial state
        let initialCoin = try await engine.item("coin")
        #expect(try await initialCoin.playerIsHolding)

        // When
        try await engine.execute("put coin on counter")

        // Then
        let finalCoin = try await engine.item("coin")
        #expect(try await finalCoin.parent == .item(counter.proxy(engine)))

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > put coin on counter
            The gold coin comes to rest upon the kitchen counter.
            """
        )
    }

    @Test("Put item sets touched flags")
    func testPutItemSetsTouchedFlags() async throws {
        // Given
        let key = Item(
            id: "key",
            .name("brass key"),
            .description("A small brass key."),
            .isTakable,
            .in(.player)
        )

        let shelf = Item(
            id: "shelf",
            .name("wooden shelf"),
            .description("A high wooden shelf."),
            .isSurface,
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: key, shelf
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Verify initial state
        let initialKey = try await engine.item("key")
        let initialShelf = try await engine.item("shelf")
        #expect(await initialKey.hasFlag(.isTouched) == false)
        #expect(await initialShelf.hasFlag(.isTouched) == false)

        // When
        try await engine.execute("put key on shelf")

        // Then
        let finalKey = try await engine.item("key")
        let finalShelf = try await engine.item("shelf")
        #expect(await finalKey.hasFlag(.isTouched) == true)
        #expect(await finalShelf.hasFlag(.isTouched) == true)

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > put key on shelf
            The brass key comes to rest upon the wooden shelf.
            """
        )
    }

    @Test("Put item updates pronouns")
    func testPutItemUpdatesPronouns() async throws {
        // Given
        let apple = Item(
            id: "apple",
            .name("red apple"),
            .description("A crisp red apple."),
            .isTakable,
            .in(.player)
        )

        let plate = Item(
            id: "plate",
            .name("dinner plate"),
            .description("A white dinner plate."),
            .isSurface,
            .in(.startRoom)
        )

        let book = Item(
            id: "book",
            .name("old book"),
            .description("An old leather book."),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: apple, plate, book
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // First examine the book to set pronouns
        try await engine.execute(
            "examine book",
            "put apple on plate",
            "examine it"
        )

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > examine book
            An old leather book.

            > put apple on plate
            The red apple comes to rest upon the dinner plate.

            > examine it
            A crisp red apple.
            """
        )
    }

    @Test("Put multiple items on same surface")
    func testPutMultipleItemsOnSameSurface() async throws {
        // Given
        let pen = Item(
            id: "pen",
            .name("blue pen"),
            .description("A blue ballpoint pen."),
            .isTakable,
            .in(.player)
        )

        let pencil = Item(
            id: "pencil",
            .name("yellow pencil"),
            .description("A yellow #2 pencil."),
            .isTakable,
            .in(.player)
        )

        let desk = Item(
            id: "desk",
            .name("office desk"),
            .description("A large office desk."),
            .isSurface,
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: pen, pencil, desk
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When - Put pen
        try await engine.execute(
            "put pen on desk",
            "put pencil on desk"
        )

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > put pen on desk
            The blue pen comes to rest upon the office desk.

            > put pencil on desk
            You successfully put the yellow pencil on the office desk.
            """
        )

        // Then - Both items should be on the desk
        let finalPen = try await engine.item("pen")
        let finalPencil = try await engine.item("pencil")
        #expect(try await finalPen.parent == .item(desk.proxy(engine)))
        #expect(try await finalPencil.parent == .item(desk.proxy(engine)))
    }

    @Test("Put item on surface that has other items")
    func testPutItemOnSurfaceWithOtherItems() async throws {
        // Given
        let newBook = Item(
            id: "newBook",
            .name("new book"),
            .description("A brand new book."),
            .isTakable,
            .in(.player)
        )

        let oldBook = Item(
            id: "oldBook",
            .name("old book"),
            .description("An old worn book."),
            .isTakable,
            .in(.item("bookshelf"))
        )

        let bookshelf = Item(
            id: "bookshelf",
            .name("wooden bookshelf"),
            .description("A tall wooden bookshelf."),
            .isSurface,
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: newBook, oldBook, bookshelf
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("put book on bookshelf")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > put book on bookshelf
            The new book comes to rest upon the wooden bookshelf.
            """
        )

        let finalNewBook = try await engine.item("newBook")
        let finalOldBook = try await engine.item("oldBook")
        #expect(try await finalNewBook.parent == .item(bookshelf.proxy(engine)))
        #expect(try await finalOldBook.parent == .item(bookshelf.proxy(engine)))
    }

    @Test("Put ambiguous item on surface that has other items")
    func testPutItemOnSurfaceWithDisambiguation() async throws {
        // Given
        let newBook = Item(
            id: "newBook",
            .name("new book"),
            .description("A brand new book."),
            .isTakable,
            .in(.player)
        )

        let oldBook = Item(
            id: "oldBook",
            .name("old book"),
            .description("An old worn book."),
            .isTakable,
            .in(.player)
        )

        let bookshelf = Item(
            id: "bookshelf",
            .name("wooden bookshelf"),
            .description("A tall wooden bookshelf."),
            .isSurface,
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: newBook, oldBook, bookshelf
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute(
            "put book on bookshelf",
            "the new book"
        )

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > put book on bookshelf
            Which do you mean: the new book or the old book?

            > the new book
            The new book comes to rest upon the wooden bookshelf.
            """
        )

        let finalNewBook = try await engine.item("newBook")
        let finalOldBook = try await engine.item("oldBook")
        #expect(try await finalNewBook.parent == .item(bookshelf.proxy(engine)))
        #expect(try await finalOldBook.parent == .player)
    }

    @Test("Put different types of items on surfaces")
    func testPutDifferentTypesOfItemsOnSurfaces() async throws {
        // Given
        let food = Item(
            id: "food",
            .name("sandwich"),
            .description("A ham sandwich."),
            .isTakable,
            .isEdible,
            .in(.player)
        )

        let tool = Item(
            id: "tool",
            .name("hammer"),
            .description("A steel hammer."),
            .isTakable,
            .isTool,
            .in(.player)
        )

        let weapon = Item(
            id: "weapon",
            .name("dagger"),
            .description("A sharp dagger."),
            .isTakable,
            .isWeapon,
            .in(.player)
        )

        let workbench = Item(
            id: "workbench",
            .name("wooden workbench"),
            .description("A sturdy wooden workbench."),
            .isSurface,
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: food, tool, weapon, workbench
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When - Put food
        try await engine.execute("put sandwich on workbench")

        let foodOutput = await mockIO.flush()
        expectNoDifference(
            foodOutput,
            """
            > put sandwich on workbench
            The sandwich comes to rest upon the wooden workbench.
            """
        )

        // When - Put tool
        try await engine.execute("put hammer on workbench")

        let toolOutput = await mockIO.flush()
        expectNoDifference(
            toolOutput,
            """
            > put hammer on workbench
            You successfully put the hammer on the wooden workbench.
            """
        )

        // When - Put weapon
        try await engine.execute("put dagger on workbench")

        let weaponOutput = await mockIO.flush()
        expectNoDifference(
            weaponOutput,
            """
            > put dagger on workbench
            You successfully put the dagger on the wooden workbench.
            """
        )
    }

    @Test("Put item on different surface types")
    func testPutItemOnDifferentSurfaceTypes() async throws {
        // Given
        let coin = Item(
            id: "coin",
            .name("gold coin"),
            .description("A shiny gold coin."),
            .isTakable,
            .in(.player)
        )

        let altar = Item(
            id: "altar",
            .name("stone altar"),
            .description("An ancient stone altar."),
            .isSurface,
            .in(.startRoom)
        )

        let pedestal = Item(
            id: "pedestal",
            .name("marble pedestal"),
            .description("A white marble pedestal."),
            .isSurface,
            .in(.startRoom)
        )

        let mantle = Item(
            id: "mantle",
            .name("fireplace mantle"),
            .description("A wooden fireplace mantle."),
            .isSurface,
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: coin, altar, pedestal, mantle
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When - Put on altar
        try await engine.execute("put coin on altar")

        let altarOutput = await mockIO.flush()
        expectNoDifference(
            altarOutput,
            """
            > put coin on altar
            The gold coin comes to rest upon the stone altar.
            """
        )

        // Move coin back to player for next test
        try await engine.apply(
            await coin.proxy(engine).move(to: .player)
        )

        // When - Put on pedestal
        try await engine.execute("put coin on pedestal")

        let pedestalOutput = await mockIO.flush()
        expectNoDifference(
            pedestalOutput,
            """
            > put coin on pedestal
            You successfully put the gold coin on the marble pedestal.
            """
        )

        // Move coin back to player for next test
        try await engine.apply(
            await coin.proxy(engine).move(to: .player)
        )

        // When - Put on mantle
        try await engine.execute("put coin on mantle")

        let mantleOutput = await mockIO.flush()
        expectNoDifference(
            mantleOutput,
            """
            > put coin on mantle
            You successfully put the gold coin on the fireplace mantle.
            """
        )
    }

    // MARK: - Intent Testing

    @Test("Handler exposes correct Verbs")
    func testVerbs() async throws {
        let handler = PutOnActionHandler()
        #expect(handler.synonyms.contains(.put))
        #expect(handler.synonyms.contains(.place))
        #expect(handler.synonyms.contains(.set))
        #expect(handler.synonyms.contains(.balance))
        #expect(handler.synonyms.contains(.hang))
        #expect(handler.synonyms.count == 5)
    }

    @Test("Handler requires light")
    func testRequiresLightProperty() async throws {
        let handler = PutOnActionHandler()
        #expect(handler.requiresLight == true)
    }

    @Test("Handler uses correct syntax")
    func testSyntaxRules() async throws {
        let handler = PutOnActionHandler()
        expectNoDifference(
            handler.syntax,
            [
                .match(.verb, .directObject),
                .match(.verb, .directObject, .on, .indirectObject),
            ])
    }
}
