import CustomDump
import GnustoEngine
import GnustoTestSupport
import Testing

@Suite("Command Struct Tests")
struct CommandTests {

    // - Test Data -

    let verbGo: Verb = .go
    let verbTake: Verb = .take
    let verbPut: Verb = .put
    let verbLook: Verb = .look

    let directionNorth: Direction = .north

    let lanternProxy: ProxyReference
    let caseProxy: ProxyReference
    let lampProxy: ProxyReference
    let boxProxy: ProxyReference

    let shinyModifiers = ["shiny"]
    let brassModifiers = ["brass"]
    let smallBrassModifiers = ["small", "brass"]

    let prepIn: Preposition = .in
    let prepOn: Preposition = .on
    let prepWith: Preposition = .with

    init() async throws {
        let lantern = Item(id: "lantern")
        let suitcase = Item(id: "case")
        let lamp = Item(id: "lamp")
        let box = Item(id: "box")

        let (engine, _) = await GameEngine.test(
            blueprint: MinimalGame(
                items: lantern, suitcase, lamp, box
            )
        )

        lanternProxy = await ProxyReference.item(lantern.proxy(engine))
        caseProxy = await ProxyReference.item(suitcase.proxy(engine))
        lampProxy = await ProxyReference.item(lamp.proxy(engine))
        boxProxy = await ProxyReference.item(box.proxy(engine))
    }

    // - Single Object Initializer Tests -

    @Test("Single object initializer - verb only")
    func testSingleInitVerbOnly() {
        let raw = "north"
        let command = Command(
            verb: verbGo,
            direction: directionNorth,
            rawInput: raw
        )

        #expect(command.verb == verbGo)
        #expect(command.directObject == nil)
        #expect(command.directObjects.isEmpty)
        #expect(command.directObjectModifiers.isEmpty)
        #expect(command.indirectObject == nil)
        #expect(command.indirectObjects.isEmpty)
        #expect(command.indirectObjectModifiers.isEmpty)
        #expect(command.isAllCommand == false)
        #expect(command.preposition == nil)
        #expect(command.direction == directionNorth)
        #expect(command.rawInput == raw)
    }

    @Test("Single object initializer - verb with direct object")
    func testSingleInitVerbDirect() {
        let raw = "take lantern"
        let command = Command(
            verb: verbTake,
            directObject: lanternProxy,
            rawInput: raw
        )

        #expect(command.verb == verbTake)
        #expect(command.directObject == lanternProxy)
        #expect(command.directObjects == [lanternProxy])
        #expect(command.directObjectModifiers.isEmpty)
        #expect(command.indirectObject == nil)
        #expect(command.indirectObjects.isEmpty)
        #expect(command.indirectObjectModifiers.isEmpty)
        #expect(command.isAllCommand == false)
        #expect(command.preposition == nil)
        #expect(command.direction == nil)
        #expect(command.rawInput == raw)
    }

    @Test("Single object initializer - verb with direct object and modifiers")
    func testSingleInitVerbDirectModifiers() {
        let raw = "take shiny lantern"
        let command = Command(
            verb: verbTake,
            directObject: lanternProxy,
            directObjectModifiers: shinyModifiers,
            rawInput: raw
        )

        #expect(command.verb == verbTake)
        #expect(command.directObject == lanternProxy)
        #expect(command.directObjects == [lanternProxy])
        #expect(command.directObjectModifiers == shinyModifiers)
        #expect(command.indirectObject == nil)
        #expect(command.indirectObjects.isEmpty)
        #expect(command.indirectObjectModifiers.isEmpty)
        #expect(command.isAllCommand == false)
        #expect(command.preposition == nil)
        #expect(command.direction == nil)
        #expect(command.rawInput == raw)
    }

    @Test("Single object initializer - full complexity")
    func testSingleInitFullComplexity() {
        let raw = "put shiny lantern in brass case"
        let command = Command(
            verb: verbPut,
            directObject: lanternProxy,
            directObjectModifiers: shinyModifiers,
            indirectObject: caseProxy,
            indirectObjectModifiers: brassModifiers,
            preposition: prepIn,
            rawInput: raw
        )

        #expect(command.verb == verbPut)
        #expect(command.directObject == lanternProxy)
        #expect(command.directObjects == [lanternProxy])
        #expect(command.directObjectModifiers == shinyModifiers)
        #expect(command.indirectObject == caseProxy)
        #expect(command.indirectObjects == [caseProxy])
        #expect(command.indirectObjectModifiers == brassModifiers)
        #expect(command.isAllCommand == false)
        #expect(command.preposition == prepIn)
        #expect(command.direction == nil)
        #expect(command.rawInput == raw)
    }

    // - Multi-Object Initializer Tests -

    @Test("Multi-object initializer - empty objects")
    func testMultiInitEmpty() {
        let raw = "look"
        let command = Command(
            verb: verbLook,
            rawInput: raw
        )

        #expect(command.verb == verbLook)
        #expect(command.directObject == nil)
        #expect(command.directObjects.isEmpty)
        #expect(command.directObjectModifiers.isEmpty)
        #expect(command.indirectObject == nil)
        #expect(command.indirectObjects.isEmpty)
        #expect(command.indirectObjectModifiers.isEmpty)
        #expect(command.isAllCommand == false)
        #expect(command.preposition == nil)
        #expect(command.direction == nil)
        #expect(command.rawInput == raw)
    }

    @Test("Multi-object initializer - single direct object")
    func testMultiInitSingleDirect() {
        let raw = "take lantern"
        let command = Command(
            verb: verbTake,
            directObjects: [lanternProxy],
            directObjectModifiers: shinyModifiers,
            rawInput: raw
        )

        #expect(command.verb == verbTake)
        #expect(command.directObject == lanternProxy)
        #expect(command.directObjects == [lanternProxy])
        #expect(command.directObjectModifiers == shinyModifiers)
        #expect(command.indirectObject == nil)
        #expect(command.indirectObjects.isEmpty)
        #expect(command.indirectObjectModifiers.isEmpty)
        #expect(command.isAllCommand == false)
        #expect(command.preposition == nil)
        #expect(command.direction == nil)
        #expect(command.rawInput == raw)
    }

    @Test("Multi-object initializer - multiple direct objects with ALL")
    func testMultiInitMultipleDirectWithAll() {
        let raw = "take all"
        let command = Command(
            verb: verbTake,
            directObjects: [lanternProxy, lampProxy],
            isAllCommand: true,
            rawInput: raw
        )

        #expect(command.verb == verbTake)
        #expect(command.directObject == lanternProxy)  // First object
        #expect(command.directObjects == [lanternProxy, lampProxy])
        #expect(command.directObjectModifiers.isEmpty)
        #expect(command.indirectObject == nil)
        #expect(command.indirectObjects.isEmpty)
        #expect(command.indirectObjectModifiers.isEmpty)
        #expect(command.isAllCommand == true)
        #expect(command.preposition == nil)
        #expect(command.direction == nil)
        #expect(command.rawInput == raw)
    }

    @Test("Multi-object initializer - multiple objects with indirect")
    func testMultiInitMultipleWithIndirect() {
        let raw = "put all in case"
        let command = Command(
            verb: verbPut,
            directObjects: [lanternProxy, lampProxy],
            indirectObjects: [caseProxy],
            indirectObjectModifiers: brassModifiers,
            isAllCommand: true,
            preposition: prepIn,
            rawInput: raw
        )

        #expect(command.verb == verbPut)
        #expect(command.directObject == lanternProxy)  // First object
        #expect(command.directObjects == [lanternProxy, lampProxy])
        #expect(command.directObjectModifiers.isEmpty)
        #expect(command.indirectObject == caseProxy)  // First object
        #expect(command.indirectObjects == [caseProxy])
        #expect(command.indirectObjectModifiers == brassModifiers)
        #expect(command.isAllCommand == true)
        #expect(command.preposition == prepIn)
        #expect(command.direction == nil)
        #expect(command.rawInput == raw)
    }

    @Test("Multi-object initializer - multiple indirect objects")
    func testMultiInitMultipleIndirect() {
        let raw = "put lantern in all containers"
        let command = Command(
            verb: verbPut,
            directObjects: [lanternProxy],
            directObjectModifiers: shinyModifiers,
            indirectObjects: [caseProxy, boxProxy],
            indirectObjectModifiers: smallBrassModifiers,
            preposition: prepIn,
            rawInput: raw
        )

        #expect(command.verb == verbPut)
        #expect(command.directObject == lanternProxy)
        #expect(command.directObjects == [lanternProxy])
        #expect(command.directObjectModifiers == shinyModifiers)
        #expect(command.indirectObject == caseProxy)  // First object
        #expect(command.indirectObjects == [caseProxy, boxProxy])
        #expect(command.indirectObjectModifiers == smallBrassModifiers)
        #expect(command.isAllCommand == false)
        #expect(command.preposition == prepIn)
        #expect(command.direction == nil)
        #expect(command.rawInput == raw)
    }

    // - Computed Properties Tests -

    @Test("directObject returns first from directObjects")
    func testDirectObjectComputed() {
        let command = Command(
            verb: verbTake,
            directObjects: [lanternProxy, lampProxy, caseProxy],
            rawInput: "take all"
        )

        #expect(command.directObject == lanternProxy)
    }

    @Test("directObject returns nil when directObjects is empty")
    func testDirectObjectComputedEmpty() {
        let command = Command(
            verb: verbLook,
            rawInput: "look"
        )

        #expect(command.directObject == nil)
    }

    @Test("indirectObject returns first from indirectObjects")
    func testIndirectObjectComputed() {
        let command = Command(
            verb: verbPut,
            directObjects: [lanternProxy],
            indirectObjects: [caseProxy, boxProxy],
            preposition: prepIn,
            rawInput: "put lantern in containers"
        )

        #expect(command.indirectObject == caseProxy)
    }

    @Test("indirectObject returns nil when indirectObjects is empty")
    func testIndirectObjectComputedEmpty() {
        let command = Command(
            verb: verbTake,
            directObjects: [lanternProxy],
            rawInput: "take lantern"
        )

        #expect(command.indirectObject == nil)
    }

    // - Helper Methods Tests -

    @Test("hasIntent returns true for matching intent")
    func testHasIntentMatching() {
        let command = Command(
            verb: verbTake,
            directObject: lanternProxy,
            rawInput: "take lantern"
        )

        // Assuming .take verb includes .take intent
        #expect(command.hasIntent(.take) == true)
    }

    @Test("hasIntent returns false for non-matching intent")
    func testHasIntentNonMatching() {
        let command = Command(
            verb: verbTake,
            directObject: lanternProxy,
            rawInput: "take lantern"
        )

        // Assuming .take verb doesn't include .examine intent
        #expect(command.hasIntent(.examine) == false)
    }

    @Test("verbPhrase returns verb description when no preposition")
    func testVerbPhraseNoPreposition() {
        let command = Command(
            verb: verbTake,
            directObject: lanternProxy,
            rawInput: "take lantern"
        )

        #expect(command.verbPhrase == verbTake.description)
    }

    @Test("verbPhrase returns verb with preposition for non-with prepositions")
    func testVerbPhraseWithPreposition() {
        let command = Command(
            verb: verbPut,
            directObject: lanternProxy,
            indirectObject: caseProxy,
            preposition: prepIn,
            rawInput: "put lantern in case"
        )

        #expect(command.verbPhrase == "\(verbPut) \(prepIn)")
    }

    @Test("verbPhrase returns verb only for with preposition")
    func testVerbPhraseWithWithPreposition() {
        let command = Command(
            verb: verbTake,
            directObject: lanternProxy,
            preposition: prepWith,
            rawInput: "take lantern with hand"
        )

        #expect(command.verbPhrase == verbTake.description)
    }

    // - Edge Cases and Value Semantics -

    @Test("Command is value type with proper copying")
    func testValueSemantics() {
        let original = Command(
            verb: verbTake,
            directObject: lanternProxy,
            directObjectModifiers: shinyModifiers,
            rawInput: "take shiny lantern"
        )

        let copy = original

        // Verify that the copy has the same values
        #expect(copy.verb == original.verb)
        #expect(copy.directObject == original.directObject)
        #expect(copy.directObjects == original.directObjects)
        #expect(copy.directObjectModifiers == original.directObjectModifiers)
        #expect(copy.indirectObject == original.indirectObject)
        #expect(copy.indirectObjects == original.indirectObjects)
        #expect(copy.indirectObjectModifiers == original.indirectObjectModifiers)
        #expect(copy.isAllCommand == original.isAllCommand)
        #expect(copy.preposition == original.preposition)
        #expect(copy.direction == original.direction)
        #expect(copy.rawInput == original.rawInput)
    }

    @Test("Command equality works correctly")
    func testEquality() {
        let command1 = Command(
            verb: verbTake,
            directObject: lanternProxy,
            directObjectModifiers: shinyModifiers,
            rawInput: "take shiny lantern"
        )

        let command2 = Command(
            verb: verbTake,
            directObject: lanternProxy,
            directObjectModifiers: shinyModifiers,
            rawInput: "take shiny lantern"
        )

        let command3 = Command(
            verb: verbTake,
            directObject: caseProxy,
            rawInput: "take case"
        )

        #expect(command1 == command2)
        #expect(command1 != command3)
    }

    @Test("Empty modifiers arrays work correctly")
    func testEmptyModifiers() {
        let command = Command(
            verb: verbTake,
            directObject: lanternProxy,
            directObjectModifiers: [],
            indirectObjectModifiers: [],
            rawInput: "take lantern"
        )

        #expect(command.directObjectModifiers.isEmpty)
        #expect(command.indirectObjectModifiers.isEmpty)
    }

    @Test("Nil raw input works correctly")
    func testNilRawInput() {
        let command = Command(
            verb: verbTake,
            directObject: lanternProxy,
            rawInput: nil
        )

        #expect(command.rawInput == nil)
    }
}
