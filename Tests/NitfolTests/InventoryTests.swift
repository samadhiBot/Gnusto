import CustomDump
import Nitfol
import Testing

struct InventoryTests {
    let nitfol: Nitfol

    init() throws {
        nitfol = try Nitfol()
    }

    @Test("Inventory")
    func inventory() {
        expectNoDifference(
            nitfol.parse("inventory"),
            ParsedCommand(verb: "inventory")
        )
    }

    @Test("I (abbreviation)")
    func iAbbreviation() {
        expectNoDifference(
            nitfol.parse("i"),
            ParsedCommand(verb: "i")
        )
    }
}
