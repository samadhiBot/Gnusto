import Testing
@testable import GnustoEngine

@Suite("ItemProperty Enum Tests")
struct ItemPropertyTests {

    @Test("ItemProperty Raw Values")
    func testItemPropertyRawValues() throws {
        #expect(ItemProperty.container.rawValue == "container")
        #expect(ItemProperty.device.rawValue == "device")
        #expect(ItemProperty.door.rawValue == "door")
        #expect(ItemProperty.edible.rawValue == "edible")
        #expect(ItemProperty.female.rawValue == "female")
        #expect(ItemProperty.invisible.rawValue == "invisible")
        #expect(ItemProperty.lightSource.rawValue == "lightSource")
        #expect(ItemProperty.locked.rawValue == "locked")
        #expect(ItemProperty.narticle.rawValue == "narticle")
        #expect(ItemProperty.ndesc.rawValue == "ndesc")
        #expect(ItemProperty.on.rawValue == "on")
        #expect(ItemProperty.open.rawValue == "open")
        #expect(ItemProperty.openable.rawValue == "openable")
        #expect(ItemProperty.person.rawValue == "person")
        #expect(ItemProperty.plural.rawValue == "plural")
        #expect(ItemProperty.read.rawValue == "read")
        #expect(ItemProperty.surface.rawValue == "surface")
        #expect(ItemProperty.takable.rawValue == "takable")
        #expect(ItemProperty.touched.rawValue == "touched")
        #expect(ItemProperty.transparent.rawValue == "transparent")
        #expect(ItemProperty.trytake.rawValue == "trytake")
        #expect(ItemProperty.vowel.rawValue == "vowel")
        #expect(ItemProperty.wearable.rawValue == "wearable")
        #expect(ItemProperty.worn.rawValue == "worn")
    }

    @Test("ItemProperty CaseIterable")
    func testItemPropertyCaseIterable() throws {
        #expect(ItemProperty.allCases.count == 26)

        // Verify a few key cases are present
        #expect(ItemProperty.allCases.contains(.takable))
        #expect(ItemProperty.allCases.contains(.lightSource))
        #expect(ItemProperty.allCases.contains(.container))
        #expect(ItemProperty.allCases.contains(.worn))
    }

    // Codable tests might be added later.
}
