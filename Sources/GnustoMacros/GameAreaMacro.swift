import SwiftSyntax
import SwiftSyntaxMacros
import SwiftSyntaxBuilder
import SwiftDiagnostics

/// Macro implementation for `@GameArea`.
///
/// This macro generates:
/// 1. Area protocol conformance via member macro
/// 2. Global ID extensions via extension macro
public struct GameAreaMacro: MemberMacro, ExtensionMacro {
    
    // MARK: - MemberMacro
    
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        
        guard declaration.is(StructDeclSyntax.self) else {
            let diagnostic = Diagnostic(
                node: Syntax(declaration),
                message: GameAreaMacroError.invalidDeclaration("@GameArea can only be applied to structs")
            )
            context.diagnose(diagnostic)
            return []
        }
        
        // Generate the required initializer and discovery properties
        return [
            DeclSyntax("init() {}"),
            DeclSyntax("""
                static var items: [Item] {
                    discoverItems()
                }
                """),
            DeclSyntax("""
                static var locations: [Location] {
                    discoverLocations()
                }
                """),
            DeclSyntax("""
                static var itemEventHandlers: [ItemID: ItemEventHandler] {
                    discoverItemEventHandlers()
                }
                """),
            DeclSyntax("""
                static var locationEventHandlers: [LocationID: LocationEventHandler] {
                    discoverLocationEventHandlers()
                }
                """),
            DeclSyntax("""
                static var fuses: [FuseDefinition] {
                    discoverFuses()
                }
                """),
            DeclSyntax("""
                static var daemons: [DaemonDefinition] {
                    discoverDaemons()
                }
                """)
        ]
    }
    
    // MARK: - ExtensionMacro
    
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        
        guard let structDecl = declaration.as(StructDeclSyntax.self) else {
            return []
        }
        
        var extensions: [ExtensionDeclSyntax] = []
        
        // Add AreaBlueprint conformance
        let areaBlueprintConformance = try ExtensionDeclSyntax("extension \(type): AreaBlueprint") {
            // Empty - conformance is provided by generated members
        }
        extensions.append(areaBlueprintConformance)
        
        // Scan for @GameItem and @GameLocation declarations to generate ID extensions
        let itemIDExtensions = try generateItemIDExtensions(from: structDecl, context: context)
        let locationIDExtensions = try generateLocationIDExtensions(from: structDecl, context: context)
        
        extensions.append(contentsOf: itemIDExtensions)
        extensions.append(contentsOf: locationIDExtensions)
        
        return extensions
    }
    
    // MARK: - Helper Methods
    
    private static func generateItemIDExtensions(
        from structDecl: StructDeclSyntax,
        context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        
        var itemNames: [String] = []
        
        // Scan all members for @GameItem annotations
        for member in structDecl.memberBlock.members {
            guard let varDecl = member.decl.as(VariableDeclSyntax.self) else { continue }
            
            // Check if this variable has a @GameItem attribute
            let hasGameItemAttribute = varDecl.attributes.contains { attr in
                guard case let .attribute(attribute) = attr else { return false }
                return attribute.attributeName.as(IdentifierTypeSyntax.self)?.name.text == "GameItem"
            }
            
            if hasGameItemAttribute {
                // Extract the variable name
                if let binding = varDecl.bindings.first,
                   let pattern = binding.pattern.as(IdentifierPatternSyntax.self) {
                    itemNames.append(pattern.identifier.text)
                }
            }
        }
        
        // Generate ItemID extension if we found any items
        if !itemNames.isEmpty {
            var memberList: [DeclSyntax] = []
            for itemName in itemNames {
                memberList.append(DeclSyntax("""
                    static let \(raw: itemName) = ItemID("\(raw: itemName)")
                    """))
            }
            
            let itemIDExtension = try ExtensionDeclSyntax("extension ItemID") {
                for member in memberList {
                    member
                }
            }
            
            return [itemIDExtension]
        }
        
        return []
    }
    
    private static func generateLocationIDExtensions(
        from structDecl: StructDeclSyntax,
        context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        
        var locationNames: [String] = []
        
        // Scan all members for @GameLocation annotations
        for member in structDecl.memberBlock.members {
            guard let varDecl = member.decl.as(VariableDeclSyntax.self) else { continue }
            
            // Check if this variable has a @GameLocation attribute
            let hasGameLocationAttribute = varDecl.attributes.contains { attr in
                guard case let .attribute(attribute) = attr else { return false }
                return attribute.attributeName.as(IdentifierTypeSyntax.self)?.name.text == "GameLocation"
            }
            
            if hasGameLocationAttribute {
                // Extract the variable name
                if let binding = varDecl.bindings.first,
                   let pattern = binding.pattern.as(IdentifierPatternSyntax.self) {
                    locationNames.append(pattern.identifier.text)
                }
            }
        }
        
        // Generate LocationID extension if we found any locations
        if !locationNames.isEmpty {
            var memberList: [DeclSyntax] = []
            for locationName in locationNames {
                memberList.append(DeclSyntax("""
                    static let \(raw: locationName) = LocationID("\(raw: locationName)")
                    """))
            }
            
            let locationIDExtension = try ExtensionDeclSyntax("extension LocationID") {
                for member in memberList {
                    member
                }
            }
            
            return [locationIDExtension]
        }
        
        return []
    }
}

// MARK: - Error Types

enum GameAreaMacroError: Error, DiagnosticMessage {
    case invalidDeclaration(String)
    
    var message: String {
        switch self {
        case .invalidDeclaration(let message):
            return "Invalid macro declaration: \(message)"
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