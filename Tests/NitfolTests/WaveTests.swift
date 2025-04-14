import CustomDump
import Nitfol
import Testing

struct WaveTests {
    let nitfol: Nitfol

    init() throws {
        nitfol = try Nitfol()
    }

    @Test("Wave")
    func wave() {
        expectNoDifference(
            nitfol.parse("wave"),
            ParsedCommand(verb: "wave")
        )
    }

    @Test("Wave object")
    func waveObject() {
        expectNoDifference(
            nitfol.parse("wave hand"),
            ParsedCommand(verb: "wave", directObject: "hand")
        )
    }

    @Test("Wave modified object")
    func waveModifiedObject() {
        expectNoDifference(
            nitfol.parse("wave the white flag"),
            ParsedCommand(verb: "wave", directObject: "flag", directObjectModifiers: ["white"])
        )
    }

    @Test("Wave at target")
    func waveAtTarget() {
        expectNoDifference(
            nitfol.parse("wave at guard"),
            ParsedCommand(verb: "wave", directObject: "guard", prepositions: "at")
        )
    }

    @Test("Wave to target")
    func waveToTarget() {
        expectNoDifference(
            nitfol.parse("wave to the guard"),
            ParsedCommand(verb: "wave", directObject: "guard", prepositions: "to")
        )
    }

    @Test("Wave at modified target")
    func waveAtModifiedTarget() {
        expectNoDifference(
            nitfol.parse("wave at the surprised elf"),
            ParsedCommand(
                verb: "wave",
                directObject: "elf",
                directObjectModifiers: ["surprised"],
                prepositions: "at"
            )
        )
    }
}
