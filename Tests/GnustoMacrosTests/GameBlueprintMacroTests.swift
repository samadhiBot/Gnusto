import MacroTesting
import SwiftSyntax
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import Testing
@testable import GnustoMacros

@Suite(.macros([GameBlueprintMacro.self]))
struct GameBlueprintMacroTests {
    
    @Test 
    func testBasicGameBlueprintExpansion() {
        assertMacro {
            """
            @GameBlueprint(
                title: "Test Game",
                introduction: "Welcome to the test game!",
                maxScore: 100,
                startingLocation: .startRoom
            )
            struct TestGame {
            }
            """
        } expansion: {
            """
            struct TestGame {

                var constants: GameConstants {
                    GameConstants(
                        storyTitle: "Test Game",
                        introduction: "Welcome to the test game!",
                        release: "1.0.0",
                        maximumScore: 100
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

            extension TestGame: GameBlueprint {
            }
            """
        }
    }
    
    @Test
    func testGameBlueprintWithoutStartingLocation() {
        assertMacro {
            """
            @GameBlueprint(
                title: "Minimal Game",
                introduction: "A minimal test game.",
                maxScore: 50
            )
            struct MinimalGame {
            }
            """
        } expansion: {
            """
            struct MinimalGame {

                var constants: GameConstants {
                    GameConstants(
                        storyTitle: "Minimal Game",
                        introduction: "A minimal test game.",
                        release: "1.0.0",
                        maximumScore: 50
                    )
                }

                var areas: [any AreaBlueprint.Type] {
                    // Auto-discovered *Area types in module
                    discoverGameAreas()
                }

                var player: Player {
                    Player(in: .defaultStart)
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

            extension MinimalGame: GameBlueprint {
            }
            """
        }
    }
    
    @Test
    func testGameBlueprintMissingTitle() {
        assertMacro {
            """
            @GameBlueprint(
                introduction: "Welcome!",
                maxScore: 100
            )
            struct TestGame {
            }
            """
        } diagnostics: {
            """
            @GameBlueprint(
            ╰─ 🛑 Missing required argument: title
                introduction: "Welcome!",
                maxScore: 100
            )
            struct TestGame {
            }
            """
        }
    }
    
    @Test
    func testGameBlueprintInvalidArguments() {
        assertMacro {
            """
            @GameBlueprint
            struct TestGame {
            }
            """
        } diagnostics: {
            """
            @GameBlueprint
            ┬─────────────
            ╰─ 🛑 @GameBlueprint requires title, introduction, maxScore, and startingLocation
            struct TestGame {
            }
            """
        }
    }
} 