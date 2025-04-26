import Foundation
import Testing

@testable import GnustoEngine

@Suite("DescriptionHandler Tests")
struct DescriptionHandlerTests {
    @Test("DescriptionHandlerID Initialization and Comparison")
    func testDescriptionHandlerIDInitializationAndComparison() {
        let id1: DescriptionHandlerID = "handler_1"
        let id2 = DescriptionHandlerID("handler_2")
        let id1_copy: DescriptionHandlerID = "handler_1"

        #expect(id1.rawValue == "handler_1")
        #expect(id2.rawValue == "handler_2")
        #expect(id1 == id1_copy)
        #expect(id1 != id2)
        #expect(id1 < id2)
        #expect(id2 > id1)
    }

    @Test("DescriptionHandler Static Initialization (StringLiteral)")
    func testStaticInitialization() {
        let handler: DescriptionHandler = "This is a static description."
        #expect(handler.id == nil)
        #expect(handler.rawStaticDescription == "This is a static description.")
        #expect(handler.staticDescription == "This is a static description.")
    }

    @Test("DescriptionHandler Dynamic Initialization (.id)")
    func testDynamicInitialization() {
        let handler = DescriptionHandler.id("dynamic_handler")
        #expect(handler.id == "dynamic_handler")
        #expect(handler.rawStaticDescription == nil)
        #expect(handler.staticDescription == nil)
    }

    @Test("DescriptionHandler Dynamic Initialization with Fallback")
    func testDynamicInitializationWithFallback() {
        let handler = DescriptionHandler.id("dynamic_handler", fallback: "Static fallback.")
        #expect(handler.id == "dynamic_handler")
        #expect(handler.rawStaticDescription == "Static fallback.")
        #expect(handler.staticDescription == "Static fallback.")
    }

    @Test("DescriptionHandler Static Description Processing (Markdown)")
    func testStaticDescriptionProcessing() {
        let handler: DescriptionHandler = "  *Emphasis* and **strong** text.  \n  "
        #expect(handler.staticDescription == "*Emphasis* and **strong** text.") // Check trimming and Markdown passthrough
    }
}
