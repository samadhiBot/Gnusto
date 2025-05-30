import MacroTesting
import SwiftSyntax
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import Testing
@testable import GnustoMacros

@Suite(.macros([
    GameAreaMacro.self,
    GameBlueprintMacro.self
]))
struct MacroSystemIntegrationTests {
    
    @Test
    func testCompleteAreaWithMacros() {
        assertMacro {
            """
            @GameArea
            enum OperaHouse {
                enum Items {
                    static let cloak = Item(.name("velvet cloak"))
                    static let hook = Item(.name("brass hook"))
                }
                
                enum Locations {
                    static let foyer = Location(.name("Foyer"))
                    static let cloakroom = Location(.name("Cloakroom"))
                }
            }
            """
        } expansion: {
            """
            enum OperaHouse {
                enum Items {
                    static let cloak = Item(.name("velvet cloak"))
                    static let hook = Item(.name("brass hook"))
                }
                
                enum Locations {
                    static let foyer = Location(.name("Foyer"))
                    static let cloakroom = Location(.name("Cloakroom"))
                }
            
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
            
                static var fuseDefinitions: [FuseID: FuseDefinition] {
                    discoverFuseDefinitions()
                }
            
                static var daemonDefinitions: [DaemonID: DaemonDefinition] {
                    discoverDaemonDefinitions()
                }
            
                static var dynamicAttributeRegistry: DynamicAttributeRegistry {
                    DynamicAttributeRegistry()
                }
            
                private static func discoverItems() -> [Item] {
                    [Self.Items.cloak, Self.Items.hook]
                }
            
                private static func discoverLocations() -> [Location] {
                    [Self.Locations.foyer, Self.Locations.cloakroom]
                }
            
                private static func discoverItemEventHandlers() -> [ItemID: ItemEventHandler] {
                    [:]
                }
            
                private static func discoverLocationEventHandlers() -> [LocationID: LocationEventHandler] {
                    [:]
                }
            
                private static func discoverFuseDefinitions() -> [FuseID: FuseDefinition] {
                    [:]
                }
            
                private static func discoverDaemonDefinitions() -> [DaemonID: DaemonDefinition] {
                    [:]
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