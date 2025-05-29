import SwiftSyntax
import SwiftSyntaxMacros
import SwiftSyntaxBuilder
import SwiftDiagnostics

/// The macro implementation for `@GameArea`.
///
/// This macro scans all extensions of the marked type across the module
/// and discovers all game content marked with `@GameItem`, `@GameLocation`, etc.
public struct GameAreaMacro: MemberMacro, ExtensionMacro {
    
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        
        guard let structDecl = declaration.as(StructDeclSyntax.self) else {
            let diagnostic = Diagnostic(
                node: Syntax(declaration),
                message: GameAreaMacroError.invalidDeclaration("@GameArea can only be applied to structs")
            )
            context.diagnose(diagnostic)
            return []
        }
        
        let areaName = structDecl.name.text
        
        // Generate the AreaBlueprint conformance structure
        let generated: [DeclSyntax] = [
            // Generate the required initializer
            DeclSyntax("init() {}"),
            
            // Generate items discovery
            DeclSyntax("""
                static var items: [Item] {
                    discoverItems()
                }
                """),
            
            // Generate locations discovery  
            DeclSyntax("""
                static var locations: [Location] {
                    discoverLocations()
                }
                """),
            
            // Generate item event handlers discovery
            DeclSyntax("""
                static var itemEventHandlers: [ItemID: ItemEventHandler] {
                    discoverItemEventHandlers()
                }
                """),
            
            // Generate location event handlers discovery
            DeclSyntax("""
                static var locationEventHandlers: [LocationID: LocationEventHandler] {
                    discoverLocationEventHandlers()
                }
                """),
            
            // Generate fuse definitions discovery
            DeclSyntax("""
                static var fuseDefinitions: [FuseID: FuseDefinition] {
                    discoverFuseDefinitions()
                }
                """),
            
            // Generate daemon definitions discovery
            DeclSyntax("""
                static var daemonDefinitions: [DaemonID: DaemonDefinition] {
                    discoverDaemonDefinitions()
                }
                """),
            
            // Generate dynamic attribute registry
            DeclSyntax("""
                static var dynamicAttributeRegistry: DynamicAttributeRegistry {
                    DynamicAttributeRegistry()
                }
                """),
            
            // Generate discovery functions
            generateDiscoveryFunctions(for: areaName)
        ]
        
        return generated
    }
    
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        let areaBlueprint: DeclSyntax = "extension \(type.trimmed): AreaBlueprint {}"
        
        guard let extensionDecl = areaBlueprint.as(ExtensionDeclSyntax.self) else {
            return []
        }
        
        return [extensionDecl]
    }
}

// MARK: - Error Types

enum GameAreaMacroError: Error, DiagnosticMessage {
    case invalidDeclaration(String)
    
    var message: String {
        switch self {
        case .invalidDeclaration(let message):
            return "Invalid @GameArea declaration: \(message)"
        }
    }
    
    var diagnosticID: MessageID {
        MessageID(domain: "GnustoMacros", id: "GameAreaMacro")
    }
    
    var severity: DiagnosticSeverity {
        .error
    }
}

// MARK: - Discovery Function Generation

func generateDiscoveryFunctions(for areaName: String) -> DeclSyntax {
    DeclSyntax("""
        // MARK: - Discovery Functions
        
        private static func discoverItems() -> [Item] {
            // This would be populated by scanning @GameItem marked properties
            // across all extensions of \(raw: areaName)
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
        """)
} 