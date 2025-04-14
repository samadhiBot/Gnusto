import CustomDump
import Nitfol
import Testing

struct ConsumeTests {
    let nitfol: Nitfol

    init() throws {
        nitfol = try Nitfol()
    }

    @Test("Eat food")
    func eatFood() {
        expectNoDifference(
            nitfol.parse("eat bread"),
            ParsedCommand(verb: "eat", directObject: "bread")
        )
    }

    @Test("Eat modified food")
    func eatModifiedFood() {
        expectNoDifference(
            nitfol.parse("devour the stale cake"),
            ParsedCommand(verb: "devour", directObject: "cake", directObjectModifiers: ["stale"])
        )
    }

    @Test("Taste food")
    func tasteFood() {
        expectNoDifference(
            nitfol.parse("taste mushroom"),
            ParsedCommand(verb: "taste", directObject: "mushroom")
        )
    }

    @Test("Drink liquid")
    func drinkLiquid() {
        expectNoDifference(
            nitfol.parse("drink water"),
            ParsedCommand(verb: "drink", directObject: "water")
        )
    }

    @Test("Drink modified liquid")
    func drinkModifiedLiquid() {
        expectNoDifference(
            nitfol.parse("gulp the bubbling potion"),
            ParsedCommand(verb: "gulp", directObject: "potion", directObjectModifiers: ["bubbling"])
        )
    }

    @Test("Imbibe liquid")
    func imbibeLiquid() {
        expectNoDifference(
            nitfol.parse("imbibe elixir"),
            ParsedCommand(verb: "imbibe", directObject: "elixir")
        )
    }
}
