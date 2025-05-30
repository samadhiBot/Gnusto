import MacroTesting
import SwiftSyntax
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import Testing
@testable import GnustoMacros

@Suite(.macros([
    GameBlueprintMacro.self,
    GameAreaMacro.self
]))
struct MacroSystemDemoTests {
    
    @Test
    func testCompleteGameDefinitionWithMacros() {
        // Test that @GameBlueprint generates a complete game structure
        assertMacro {
            """
            @GameBlueprint(
                title: "Macro Demo Game",
                introduction: "Welcome to the macro-powered game!",
                maxScore: 50,
                startingLocation: .startRoom
            )
            struct DemoGame {
            }
            """
        } expansion: {
            """
            struct DemoGame {

                var constants: GameConstants {
                    GameConstants(
                        storyTitle: "Macro Demo Game",
                        introduction: "Welcome to the macro-powered game!",
                        release: "1.0.0",
                        maximumScore: 50
                    )
                }

                var areas: [any AreaBlueprint.Type] {
                    // Auto-discovered *Area types in module
                    discoverGameAreas()
                }

                var player: Player {
                    Player(in: startRoom)
                }

                private func discoverGameAreas() -> [any AreaBlueprint.Type] {
                    // Convention-based discovery of *Area types
                    // This would use Swift's metadata system in a real implementation
                    var areas: [any AreaBlueprint.Type] = []

                    // For now, areas must be manually registered
                    // TODO: Implement automatic discovery via Swift metadata

                    return areas
                }
            }

            extension DemoGame: GameBlueprint {
            }
            """
        }
    }
    
    @Test
    func testGameAreaWithAutoDiscovery() {
        // Test that @GameArea generates discovery infrastructure
        assertMacro {
            """
            @GameArea
            enum StartingArea {
            }
            """
        } expansion: {
            """
            enum StartingArea {

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

            extension StartingArea: AreaBlueprint {
            }
            """
        }
    }
} 