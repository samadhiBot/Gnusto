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
            struct TestArea {
                @GameItem
                static let sword = Item(.name("sword"))
                
                @GameLocation
                static let room = Location(.name("room"))
            }
            """
        } expansion: {
            """
            struct TestArea {
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
    func testGameAreaOnNonStruct() {
        assertMacro {
            """
            @GameArea
            class TestArea {
            }
            """
        } diagnostics: {
            """
            @GameArea
            ╰─ 🛑 Invalid macro declaration: @GameArea can only be applied to structs
            class TestArea {
            }
            """
        }
    }
    
    @Test
    func testGameAreaWithExistingContent() {
        assertMacro {
            """
            @GameArea
            struct TestArea {
                let customProperty = "test"
                
                func customMethod() {
                    // Custom implementation
                }
            }
            """
        } expansion: {
            """
            struct TestArea {
                let customProperty = "test"
                
                func customMethod() {
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
            struct EmptyArea {
            }
            """
        } expansion: {
            """
            struct EmptyArea {

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
