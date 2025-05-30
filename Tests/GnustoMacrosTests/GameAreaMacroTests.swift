import MacroTesting
import SwiftSyntax
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import Testing
@testable import GnustoMacros

@Suite(.macros([GameAreaMacro.self]))
struct GameAreaMacroTests {
    
    @Test
    func testBasicGameAreaExpansion() {
        assertMacro {
            """
            @GameArea
            enum TestArea {
                @GameItem
                static let sword = Item(.name("sword"))
                
                @GameLocation
                static let room = Location(.name("room"))
            }
            """
        } expansion: {
            """
            enum TestArea {
                @GameItem
                static let sword = Item(.name("sword"))
                
                @GameLocation
                static let room = Location(.name("room"))

                init() {
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

                static var fuses: [FuseDefinition] {
                    discoverFuses()
                }

                static var daemons: [DaemonDefinition] {
                    discoverDaemons()
                }
            }

            extension TestArea: AreaBlueprint {
            }

            extension ItemID {
                static let sword = ItemID("sword")
            }

            extension LocationID {
                static let room = LocationID("room")
            }
            """
        }
    }
    
    @Test
    func testGameAreaOnNonEnum() {
        assertMacro {
            """
            @GameArea
            struct TestArea {
            }
            """
        } diagnostics: {
            """
            @GameArea
            ╰─ 🛑 Invalid macro declaration: @GameArea can only be applied to enums
            struct TestArea {
            }
            """
        }
    }
    
    @Test
    func testGameAreaWithExistingContent() {
        assertMacro {
            """
            @GameArea
            enum TestArea {
                static let customProperty = "test"
                
                static func customMethod() {
                    // Custom implementation
                }
            }
            """
        } expansion: {
            """
            enum TestArea {
                static let customProperty = "test"
                
                static func customMethod() {
                    // Custom implementation
                }

                init() {
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

                static var fuses: [FuseDefinition] {
                    discoverFuses()
                }

                static var daemons: [DaemonDefinition] {
                    discoverDaemons()
                }
            }

            extension TestArea: AreaBlueprint {
            }
            """
        }
    }
    
    @Test
    func testGameAreaWithoutItems() {
        assertMacro {
            """
            @GameArea
            enum EmptyArea {
            }
            """
        } expansion: {
            """
            enum EmptyArea {

                init() {
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

                static var fuses: [FuseDefinition] {
                    discoverFuses()
                }

                static var daemons: [DaemonDefinition] {
                    discoverDaemons()
                }
            }

            extension EmptyArea: AreaBlueprint {
            }
            """
        }
    }
} 
