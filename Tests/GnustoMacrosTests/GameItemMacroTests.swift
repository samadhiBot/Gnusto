import MacroTesting
import SwiftSyntax
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import Testing
@testable import GnustoMacros

@Suite(.macros([
    GameItemMacro.self,
    GameLocationMacro.self,
    ItemEventHandlerMacro.self,
    LocationEventHandlerMacro.self,
    GameFuseMacro.self,
    GameDaemonMacro.self
]))
struct GameItemMacroTests {
    
    @Test
    func testGameItemMacro() {
        assertMacro {
            """
            @GameItem
            static let magicSword = Item(.name("magic sword"))
            """
        } expansion: {
            """
            static let magicSword = Item(.name("magic sword"))

            static let magicSwordID = ItemID("magicSword")
            """
        }
    }
    
    @Test
    func testGameLocationMacro() {
        assertMacro {
            """
            @GameLocation
            static let throneRoom = Location(.name("Throne Room"))
            """
        } expansion: {
            """
            static let throneRoom = Location(.name("Throne Room"))

            static let throneRoomID = LocationID("throneRoom")
            """
        }
    }
} 