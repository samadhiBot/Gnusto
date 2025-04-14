import CustomDump
import Nitfol
import Testing

struct AttackTests {
    let nitfol: Nitfol

    init() throws {
        // Assuming Nitfol initialization doesn't fail in tests
        nitfol = try Nitfol()
    }

    @Test("Attack enemy")
    func attackEnemy() {
        expectNoDifference(
            nitfol.parse("attack troll"),
            ParsedCommand(verb: "attack", directObject: "troll")
        )
    }

    @Test("Attack modified enemy")
    func attackModifiedEnemy() {
        expectNoDifference(
            nitfol.parse("hit the vicious orc"),
            ParsedCommand(verb: "hit", directObject: "orc", directObjectModifiers: ["vicious"])
        )
    }

    @Test("Attack enemy with weapon")
    func attackEnemyWithWeapon() {
        expectNoDifference(
            nitfol.parse("stab goblin with dagger"),
            ParsedCommand(verb: "stab", directObject: "goblin", prepositions: "with", indirectObject: "dagger")
        )
    }

    @Test("Attack modified enemy with modified weapon")
    func attackModifiedEnemyWithModifiedWeapon() {
        expectNoDifference(
            nitfol.parse("slay the evil dragon with the enchanted sword"),
            ParsedCommand(
                verb: "slay",
                directObject: "dragon",
                directObjectModifiers: ["evil"],
                prepositions: "with",
                indirectObject: "sword",
                indirectObjectModifiers: ["enchanted"]
            )
        )
    }

    @Test("Bite enemy")
    func biteEnemy() {
        expectNoDifference(
            nitfol.parse("bite adventurer"),
            ParsedCommand(verb: "bite", directObject: "adventurer")
        )
    }
}
