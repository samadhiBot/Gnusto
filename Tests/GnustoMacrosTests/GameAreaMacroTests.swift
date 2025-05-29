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
            }
            """
        } expansion: {
            """
            struct TestArea {
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
                static var fuseDefinitions: [FuseID: FuseDefinition] {
                    discoverFuseDefinitions()
                }
                static var daemonDefinitions: [DaemonID: DaemonDefinition] {
                    discoverDaemonDefinitions()
                }
                static var dynamicAttributeRegistry: DynamicAttributeRegistry {
                    DynamicAttributeRegistry()
                }
                // MARK: - Discovery Functions
                
                private static func discoverItems() -> [Item] {
                    // This would be populated by scanning @GameItem marked properties
                    // across all extensions of TestArea
                    var items: [Item] = []
                    
                    // Auto-generated item registrations would go here
                    // Example: items.append(Self.basket.withID(.basket))
                    
                    return items
                }
                
                private static func discoverLocations() -> [Location] {
                    // This would be populated by scanning @GameLocation marked properties
                    var locations: [Location] = []
                    
                    // Auto-generated location registrations would go here
                    // Example: locations.append(Self.yourCottage.withID(.yourCottage))
                    
                    return locations
                }
                
                private static func discoverItemEventHandlers() -> [ItemID: ItemEventHandler] {
                    // This would be populated by scanning @ItemEventHandler marked properties
                    var handlers: [ItemID: ItemEventHandler] = [:]
                    
                    // Auto-generated handler registrations would go here
                    // Example: handlers[.basket] = Self.basketHandler
                    
                    return handlers
                }
                
                private static func discoverLocationEventHandlers() -> [LocationID: LocationEventHandler] {
                    // This would be populated by scanning @LocationEventHandler marked properties
                    var handlers: [LocationID: LocationEventHandler] = [:]
                    
                    // Auto-generated handler registrations would go here
                    // Example: handlers[.stoneBridge] = Self.bridgeHandler
                    
                    return handlers
                }
                
                private static func discoverFuseDefinitions() -> [FuseID: FuseDefinition] {
                    // This would be populated by scanning @GameFuse marked properties
                    var fuses: [FuseID: FuseDefinition] = [:]
                    
                    // Auto-generated fuse registrations would go here
                    // Example: fuses[.hungerTimer] = Self.hungerFuse.withID(.hungerTimer)
                    
                    return fuses
                }
                
                private static func discoverDaemonDefinitions() -> [DaemonID: DaemonDefinition] {
                    // This would be populated by scanning @GameDaemon marked properties
                    var daemons: [DaemonID: DaemonDefinition] = [:]
                    
                    // Auto-generated daemon registrations would go here
                    // Example: daemons[.weatherSystem] = Self.weatherDaemon.withID(.weatherSystem)
                    
                    return daemons
                }
            }

            extension TestArea: AreaBlueprint {
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
            ┬────────
            ╰─ 🛑 Invalid @GameArea declaration: @GameArea can only be applied to structs
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
                static var fuseDefinitions: [FuseID: FuseDefinition] {
                    discoverFuseDefinitions()
                }
                static var daemonDefinitions: [DaemonID: DaemonDefinition] {
                    discoverDaemonDefinitions()
                }
                static var dynamicAttributeRegistry: DynamicAttributeRegistry {
                    DynamicAttributeRegistry()
                }
                // MARK: - Discovery Functions
                
                private static func discoverItems() -> [Item] {
                    // This would be populated by scanning @GameItem marked properties
                    // across all extensions of TestArea
                    var items: [Item] = []
                    
                    // Auto-generated item registrations would go here
                    // Example: items.append(Self.basket.withID(.basket))
                    
                    return items
                }
                
                private static func discoverLocations() -> [Location] {
                    // This would be populated by scanning @GameLocation marked properties
                    var locations: [Location] = []
                    
                    // Auto-generated location registrations would go here
                    // Example: locations.append(Self.yourCottage.withID(.yourCottage))
                    
                    return locations
                }
                
                private static func discoverItemEventHandlers() -> [ItemID: ItemEventHandler] {
                    // This would be populated by scanning @ItemEventHandler marked properties
                    var handlers: [ItemID: ItemEventHandler] = [:]
                    
                    // Auto-generated handler registrations would go here
                    // Example: handlers[.basket] = Self.basketHandler
                    
                    return handlers
                }
                
                private static func discoverLocationEventHandlers() -> [LocationID: LocationEventHandler] {
                    // This would be populated by scanning @LocationEventHandler marked properties
                    var handlers: [LocationID: LocationEventHandler] = [:]
                    
                    // Auto-generated handler registrations would go here
                    // Example: handlers[.stoneBridge] = Self.bridgeHandler
                    
                    return handlers
                }
                
                private static func discoverFuseDefinitions() -> [FuseID: FuseDefinition] {
                    // This would be populated by scanning @GameFuse marked properties
                    var fuses: [FuseID: FuseDefinition] = [:]
                    
                    // Auto-generated fuse registrations would go here
                    // Example: fuses[.hungerTimer] = Self.hungerFuse.withID(.hungerTimer)
                    
                    return fuses
                }
                
                private static func discoverDaemonDefinitions() -> [DaemonID: DaemonDefinition] {
                    // This would be populated by scanning @GameDaemon marked properties
                    var daemons: [DaemonID: DaemonDefinition] = [:]
                    
                    // Auto-generated daemon registrations would go here
                    // Example: daemons[.weatherSystem] = Self.weatherDaemon.withID(.weatherSystem)
                    
                    return daemons
                }
            }

            extension TestArea: AreaBlueprint {
            }
            """
        }
    }
} 