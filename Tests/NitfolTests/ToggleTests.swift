import CustomDump
import Nitfol
import Testing

struct ToggleTests {
    let nitfol: Nitfol

    init() throws {
        nitfol = try Nitfol()
    }

    @Test("Turn object on")
    func turnObjectOn() {
        expectNoDifference(
            nitfol.parse("turn lamp on"),
            ParsedCommand(verb: "turn", directObject: "lamp", prepositions: "on")
        )
    }

    @Test("Turn modified object on")
    func turnModifiedObjectOn() {
        expectNoDifference(
            nitfol.parse("switch the humming machine on"),
            ParsedCommand(verb: "switch", directObject: "machine", directObjectModifiers: ["humming"], prepositions: "on")
        )
    }

    @Test("Light object")
    func lightObject() {
        expectNoDifference(
            nitfol.parse("light torch"),
            ParsedCommand(verb: "light", directObject: "torch")
        )
    }

    @Test("Turn object off")
    func turnObjectOff() {
        expectNoDifference(
            nitfol.parse("turn the lantern off"),
            ParsedCommand(verb: "turn", directObject: "lantern", prepositions: "off")
        )
    }

    @Test("Turn modified object off")
    func turnModifiedObjectOff() {
        expectNoDifference(
            nitfol.parse("switch the blinking light off"),
            ParsedCommand(verb: "switch", directObject: "light", directObjectModifiers: ["blinking"], prepositions: "off")
        )
    }

    @Test("Extinguish object")
    func extinguishObject() {
        expectNoDifference(
            nitfol.parse("extinguish candle"),
            ParsedCommand(verb: "extinguish", directObject: "candle")
        )
    }

    @Test("Douse object")
    func douseObject() {
        expectNoDifference(
            nitfol.parse("douse the roaring fire"),
            ParsedCommand(verb: "douse", directObject: "fire", directObjectModifiers: ["roaring"])
        )
    }

    @Test("Put out object")
    func putOutObject() {
        expectNoDifference(
            nitfol.parse("put out fire"),
            ParsedCommand(verb: "put", directObject: "fire", prepositions: "out")
        )
    }

    @Test("Put object out")
    func putObjectOut() {
        expectNoDifference(
            nitfol.parse("put fire out"),
            ParsedCommand(verb: "put", directObject: "fire", prepositions: "out")
        )
    }
}
