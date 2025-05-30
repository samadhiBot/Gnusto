import MacroTesting
import SwiftSyntax
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import Testing
@testable import GnustoMacros

@Suite(.macros([
    GameAreaMacro.self,
    GameItemMacro.self,
    GameLocationMacro.self
]))
struct MacroSystemIntegrationTests {
    
    @Test
    func testCompleteAreaWithMacros() {
        assertMacro {
            """
            @GameArea
            enum OperaHouse {
                @GameItem
                static let cloak = Item(.name("velvet cloak"))
                
                @GameItem  
                static let hook = Item(.name("brass hook"))
                
                @GameLocation
                static let foyer = Location(.name("Foyer"))
                
                @GameLocation
                static let cloakroom = Location(.name("Cloakroom"))
            }
            """
        } expansion: {
            """
            enum OperaHouse {
                @GameItem
                static let cloak = Item(.name("velvet cloak"))
                
                @GameItem  
                static let hook = Item(.name("brass hook"))
                
                @GameLocation
                static let foyer = Location(.name("Foyer"))
                
                @GameLocation
                static let cloakroom = Location(.name("Cloakroom"))
            
                init() {}
            
                static var items: [Item] {
                    discoverItems()
                }
            
                static var locations: [Location] {
                    discoverLocations()
                }
            
                static var itemEventHandlers: [ItemID: ItemEventHandler] {
                    discoverItemEventHandlers()
                }
            
                static var locationEventHandlers: [LocationID: LocationEventHandler] {
                    discoverLocationEventHandlers()
                }
            
                static var fuses: [FuseDefinition] {
                    discoverFuses()
                }
            
                static var daemons: [DaemonDefinition] {
                    discoverDaemons()
                }
            }

            extension OperaHouse: AreaBlueprint {
            }

            extension ItemID {
                static let cloak = ItemID("cloak")
                static let hook = ItemID("hook")
            }

            extension LocationID {
                static let foyer = LocationID("foyer")
                static let cloakroom = LocationID("cloakroom")
            }
            """
        }
    }
} 