import Testing
import CustomDump
@testable import GnustoEngine

@Suite("Lighting Change Detection Tests")
struct LightingChangeTests {
    
    @Test("Location isVisited flag cleared when lighting changes from dark to lit")
    func testLightingChangeFromDarkToLit() async throws {
        // Arrange: Create a dark room that starts unvisited
        let darkRoom = Location(
            id: "darkRoom",
            .name("Dark Room"),
            .description("A room that can be lit or dark.")
        )
        
        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: [darkRoom]
        )
        
        let mockIO = await MockIOHandler()
        let engine = await GameEngine(
            blueprint: game,
            parser: MockParser(),
            ioHandler: mockIO
        )
        
        // Initially the room should be dark and unvisited
        #expect(await engine.isLocationLit(at: "darkRoom") == false)
        #expect(try engine.location("darkRoom").hasFlag(.isVisited) == false)
        
        // Mark the room as visited
        let markVisitedChange = StateChange(
            entityID: .location("darkRoom"),
            attributeID: .locationAttribute(.isVisited),
            oldValue: false,
            newValue: true
        )
        try await engine.apply(markVisitedChange)
        
        // Verify the room is now marked as visited
        #expect(try engine.location("darkRoom").hasFlag(.isVisited) == true)
        
        // Act: Change the room from dark to lit
        let location = try engine.location("darkRoom")
        if let lightChange = await engine.setFlag(.isLit, on: location) {
            try await engine.apply(lightChange)
        }
        
        // Assert: The room should now be lit and the isVisited flag should be cleared
        #expect(await engine.isLocationLit(at: "darkRoom") == true)
        #expect(try engine.location("darkRoom").hasFlag(.isVisited) == false)
    }
    
    @Test("Location isVisited flag cleared when lighting changes from lit to dark")
    func testLightingChangeFromLitToDark() async throws {
        // Arrange: Create a room that starts lit
        let litRoom = Location(
            id: "litRoom",
            .name("Lit Room"),
            .description("A room that starts lit."),
            .isLit
        )
        
        let game = MinimalGame(
            player: Player(in: "litRoom"),
            locations: [litRoom]
        )
        
        let mockIO = await MockIOHandler()
        let engine = await GameEngine(
            blueprint: game,
            parser: MockParser(),
            ioHandler: mockIO
        )
        
        // Initially the room should be lit and unvisited
        #expect(await engine.isLocationLit(at: "litRoom") == true)
        #expect(try engine.location("litRoom").hasFlag(.isVisited) == false)
        
        // Mark the room as visited
        let markVisitedChange = StateChange(
            entityID: .location("litRoom"),
            attributeID: .locationAttribute(.isVisited),
            oldValue: false,
            newValue: true
        )
        try await engine.apply(markVisitedChange)
        
        // Verify the room is now marked as visited
        #expect(try engine.location("litRoom").hasFlag(.isVisited) == true)
        
        // Act: Change the room from lit to dark
        let location = try engine.location("litRoom")
        if let darkChange = await engine.clearFlag(.isLit, on: location) {
            try await engine.apply(darkChange)
        }
        
        // Assert: The room should now be dark and the isVisited flag should be cleared
        #expect(await engine.isLocationLit(at: "litRoom") == false)
        #expect(try engine.location("litRoom").hasFlag(.isVisited) == false)
    }
    
    @Test("Location isVisited flag not affected when lighting doesn't change")
    func testNoLightingChange() async throws {
        // Arrange: Create a room that starts lit
        let litRoom = Location(
            id: "litRoom",
            .name("Lit Room"),
            .description("A room that stays lit."),
            .isLit
        )
        
        let game = MinimalGame(
            player: Player(in: "litRoom"),
            locations: [litRoom]
        )
        
        let mockIO = await MockIOHandler()
        let engine = await GameEngine(
            blueprint: game,
            parser: MockParser(),
            ioHandler: mockIO
        )
        
        // Mark the room as visited
        let markVisitedChange = StateChange(
            entityID: .location("litRoom"),
            attributeID: .locationAttribute(.isVisited),
            oldValue: false,
            newValue: true
        )
        try await engine.apply(markVisitedChange)
        
        // Verify the room is marked as visited
        #expect(try engine.location("litRoom").hasFlag(.isVisited) == true)
        
        // Act: Try to set the isLit flag again (no actual change since it's already lit)
        let location = try engine.location("litRoom")
        let noOpChange = await engine.setFlag(.isLit, on: location)
        
        // Assert: No change should be created since the flag is already set
        #expect(noOpChange == nil)
        
        // Verify the room is still visited (no lighting change occurred)
        #expect(try engine.location("litRoom").hasFlag(.isVisited) == true)
    }
    
    @Test("Location isVisited flag not cleared if room was never visited")
    func testLightingChangeUnvisitedRoom() async throws {
        // Arrange: Create a dark room that is never visited
        let darkRoom = Location(
            id: "darkRoom",
            .name("Dark Room"),
            .description("A room that starts dark and unvisited.")
        )
        
        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: [darkRoom]
        )
        
        let mockIO = await MockIOHandler()
        let engine = await GameEngine(
            blueprint: game,
            parser: MockParser(),
            ioHandler: mockIO
        )
        
        // Verify the room starts unvisited
        #expect(try engine.location("darkRoom").hasFlag(.isVisited) == false)
        
        // Act: Change the room from dark to lit (but it was never visited)
        let location = try engine.location("darkRoom")
        if let lightChange = await engine.setFlag(.isLit, on: location) {
            try await engine.apply(lightChange)
        }
        
        // Assert: The room should be lit but still unvisited (no change to visited flag)
        #expect(await engine.isLocationLit(at: "darkRoom") == true)
        #expect(try engine.location("darkRoom").hasFlag(.isVisited) == false)
    }
} 