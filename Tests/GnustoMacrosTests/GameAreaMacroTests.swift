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
                enum Items {
                    static let sword = Item(.name("sword"))
                }
                
                enum Locations {
                    static let room = Location(.name("room"))
                }
            }
            """
        } expansion: {
            """
            enum TestArea {
                enum Items {
                    static let sword = Item(.name("sword"))
                }
                
                enum Locations {
                    static let room = Location(.name("room"))
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
                    [Self.Items.sword]
                }

                private static func discoverLocations() -> [Location] {
                    [Self.Locations.room]
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
                    []
                }

                private static func discoverLocations() -> [Location] {
                    []
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
                    []
                }

                private static func discoverLocations() -> [Location] {
                    []
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

            extension EmptyArea: AreaBlueprint {
            }
            """
        }
    }
} 
