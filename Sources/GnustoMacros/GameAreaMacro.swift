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
        
        guard let enumDecl = declaration.as(EnumDeclSyntax.self) else {
            let diagnostic = Diagnostic(
                node: Syntax(declaration),
                message: GameAreaMacroError.invalidDeclaration("@GameArea can only be applied to enums")
            )
            context.diagnose(diagnostic)
            return []
        }
        
        // Scan for @GameItem and @GameLocation marked properties
        let (itemNames, locationNames) = scanForGameContent(from: enumDecl)
        
        // Generate the required discovery properties (no init() needed!)
        return [
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
                static var fuseDefinitions: [FuseID: FuseDefinition] {
                    discoverFuseDefinitions()
                }
                """),
            DeclSyntax("""
                static var daemonDefinitions: [DaemonID: DaemonDefinition] {
                    discoverDaemonDefinitions()
                }
                """),
            DeclSyntax("""
                static var dynamicAttributeRegistry: DynamicAttributeRegistry {
                    DynamicAttributeRegistry()
                }
                """),
            // Discovery function implementations with actual content
            generateDiscoverItemsFunction(itemNames: itemNames),
            generateDiscoverLocationsFunction(locationNames: locationNames),
            DeclSyntax("""
                private static func discoverItemEventHandlers() -> [ItemID: ItemEventHandler] {
                    [:]
                }
                """),
            DeclSyntax("""
                private static func discoverLocationEventHandlers() -> [LocationID: LocationEventHandler] {
                    [:]
                }
                """),
            DeclSyntax("""
                private static func discoverFuseDefinitions() -> [FuseID: FuseDefinition] {
                    [:]
                }
                """),
            DeclSyntax("""
                private static func discoverDaemonDefinitions() -> [DaemonID: DaemonDefinition] {
                    [:]
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
        
        guard let enumDecl = declaration.as(EnumDeclSyntax.self) else {
            return []
        }
        
        var extensions: [ExtensionDeclSyntax] = []
        
        // Add AreaBlueprint conformance
        let areaBlueprintConformance = try ExtensionDeclSyntax("extension \(type): AreaBlueprint") {
            // Empty - conformance is provided by generated members
        }
        extensions.append(areaBlueprintConformance)
        
        // TODO: Temporarily disabled ID extensions - need to fix redeclaration conflicts
        // The macro is extending OperaHouse instead of ItemID/LocationID
        // extensions.append(contentsOf: try generateItemIDExtensions(from: enumDecl, context: context))
        // extensions.append(contentsOf: try generateLocationIDExtensions(from: enumDecl, context: context))
        
        return extensions
    }
    
    // MARK: - Helper Methods
    
    private static func scanForGameContent(from enumDecl: EnumDeclSyntax) -> ([String], [String]) {
        var itemNames: [String] = []
        var locationNames: [String] = []
        
        // Scan all members for @GameItem and @GameLocation annotations
        for member in enumDecl.memberBlock.members {
            guard let varDecl = member.decl.as(VariableDeclSyntax.self) else { continue }
            
            // Check if this variable has a @GameItem attribute
            let hasGameItemAttribute = varDecl.attributes.contains { attr in
                guard case let .attribute(attribute) = attr else { return false }
                return attribute.attributeName.as(IdentifierTypeSyntax.self)?.name.text == "GameItem"
            }
            
            // Check if this variable has a @GameLocation attribute
            let hasGameLocationAttribute = varDecl.attributes.contains { attr in
                guard case let .attribute(attribute) = attr else { return false }
                return attribute.attributeName.as(IdentifierTypeSyntax.self)?.name.text == "GameLocation"
            }
            
            if hasGameItemAttribute || hasGameLocationAttribute {
                // Extract the variable name
                if let binding = varDecl.bindings.first,
                   let pattern = binding.pattern.as(IdentifierPatternSyntax.self) {
                    let name = pattern.identifier.text
                    if hasGameItemAttribute {
                        itemNames.append(name)
                    }
                    if hasGameLocationAttribute {
                        locationNames.append(name)
                    }
                }
            }
        }
        
        return (itemNames, locationNames)
    }
    
    private static func generateDiscoverItemsFunction(itemNames: [String]) -> DeclSyntax {
        let itemsArray = itemNames.map { "Self.\($0)" }.joined(separator: ", ")
        return DeclSyntax("""
            private static func discoverItems() -> [Item] {
                [\(raw: itemsArray)]
            }
            """)
    }
    
    private static func generateDiscoverLocationsFunction(locationNames: [String]) -> DeclSyntax {
        let locationsArray = locationNames.map { "Self.\($0)" }.joined(separator: ", ")
        return DeclSyntax("""
            private static func discoverLocations() -> [Location] {
                [\(raw: locationsArray)]
            }
            """)
    }
    
    private static func generateItemIDExtensions(
        from enumDecl: EnumDeclSyntax,
        context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        
        var itemNames: [String] = []
        
        // Scan all members for @GameItem annotations
        for member in enumDecl.memberBlock.members {
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
        from enumDecl: EnumDeclSyntax,
        context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        
        var locationNames: [String] = []
        
        // Scan all members for @GameLocation annotations
        for member in enumDecl.memberBlock.members {
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