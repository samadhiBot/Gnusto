import Testing
@testable import GnustoEngine

@Suite("Identifier Type Tests")
struct IdentifierTypesTests {

    @Test("LocationID Initialization and Equality")
    func testLocationID() throws {
        let id1: LocationID = "westOfHouse"
        let id2 = LocationID("westOfHouse")
        let id3: LocationID = "northOfHouse"

        #expect(id1.rawValue == "westOfHouse")
        #expect(id1 == id2)
        #expect(id1 != id3)
    }

    @Test("ItemID Initialization and Equality")
    func testItemID() throws {
        let id1: ItemID = "brassLantern"
        let id2 = ItemID("brassLantern")
        let id3: ItemID = "rustyKnife"

        #expect(id1.rawValue == "brassLantern")
        #expect(id1 == id2)
        #expect(id1 != id3)
    }

    @Test("VerbID Initialization and Equality")
    func testVerbID() throws {
        let id1: VerbID = "take"
        let id2 = VerbID("take")
        let id3: VerbID = "drop"

        #expect(id1.rawValue == "take")
        #expect(id1 == id2)
        #expect(id1 != id3)
    }

    @Test("Identifier Type Hashability")
    func testIdentifierHashability() throws {
        let locationDict = [LocationID("a"): 1, LocationID("b"): 2]
        let itemDict = [ItemID("x"): true, ItemID("y"): false]
        let verbSet: Set<VerbID> = ["go", "look", "go"]

        #expect(locationDict[LocationID("a")] == 1)
        #expect(itemDict[ItemID("x")] == true)
        #expect(verbSet.count == 2) // "go" should only appear once
        #expect(verbSet.contains("look"))
    }

    // Codable tests might be added later when persistence is implemented.
}
