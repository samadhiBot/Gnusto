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
        
        // Scan for Item and Location declarations using type inference
        let (items, locations) = scanForGameContentWithEnums(from: enumDecl)
        let itemNames = items.map { $0.name }
        let locationNames = locations.map { $0.name }
        
        // Generate the required discovery properties (no init() needed!)
        var members: [DeclSyntax] = [
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
        ]
        
        // ✅ Generate ID constants directly within this enum (which macro CAN do!)
        for itemName in itemNames {
            members.append(DeclSyntax("""
                static let \(raw: itemName) = ItemID("\(raw: itemName)")
                """))
        }
        
        for locationName in locationNames {
            members.append(DeclSyntax("""
                static let \(raw: locationName) = LocationID("\(raw: locationName)")
                """))
        }
        
        // Add discovery function implementations
        members.append(contentsOf: [
            generateDiscoverItemsFunction(items: items),
            generateDiscoverLocationsFunction(locations: locations),
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
        ])
        
        return members
    }
    
    // MARK: - ExtensionMacro
    
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclSyntaxProtocol,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        
        guard declaration.is(EnumDeclSyntax.self) else {
            return []
        }
        
        var extensions: [ExtensionDeclSyntax] = []
        
        // Add AreaBlueprint conformance
        let areaBlueprintConformance = try ExtensionDeclSyntax("extension \(type): AreaBlueprint") {
            // Empty - conformance is provided by generated members
        }
        extensions.append(areaBlueprintConformance)
        
        return extensions
    }
    
    // MARK: - Type Inference Scanning
    
    private static func scanForGameContentWithEnums(from enumDecl: EnumDeclSyntax) -> ([NestedItemInfo], [NestedLocationInfo]) {
        var items: [NestedItemInfo] = []
        var locations: [NestedLocationInfo] = []
        
        // Scan all nested enums and track which enum contains each item/location
        for member in enumDecl.memberBlock.members {
            if let nestedEnum = member.decl.as(EnumDeclSyntax.self) {
                let nestedEnumName = nestedEnum.name.text
                
                for nestedMember in nestedEnum.memberBlock.members {
                    if let varDecl = nestedMember.decl.as(VariableDeclSyntax.self) {
                        if let itemName = getItemName(from: varDecl) {
                            items.append(NestedItemInfo(name: itemName, enumName: nestedEnumName))
                        }
                        if let locationName = getLocationName(from: varDecl) {
                            locations.append(NestedLocationInfo(name: locationName, enumName: nestedEnumName))
                        }
                    }
                }
            }
        }
        
        return (items, locations)
    }
    
    private static func getItemName(from varDecl: VariableDeclSyntax) -> String? {
        guard varDecl.bindingSpecifier.text == "let",
              varDecl.modifiers.contains(where: { $0.name.text == "static" }),
              let binding = varDecl.bindings.first,
              let pattern = binding.pattern.as(IdentifierPatternSyntax.self),
              let initializer = binding.initializer,
              let functionCall = initializer.value.as(FunctionCallExprSyntax.self),
              let identifierExpr = functionCall.calledExpression.as(DeclReferenceExprSyntax.self),
              identifierExpr.baseName.text == "Item" else {
            return nil
        }
        
        return pattern.identifier.text
    }
    
    private static func getLocationName(from varDecl: VariableDeclSyntax) -> String? {
        guard varDecl.bindingSpecifier.text == "let",
              varDecl.modifiers.contains(where: { $0.name.text == "static" }),
              let binding = varDecl.bindings.first,
              let pattern = binding.pattern.as(IdentifierPatternSyntax.self),
              let initializer = binding.initializer,
              let functionCall = initializer.value.as(FunctionCallExprSyntax.self),
              let identifierExpr = functionCall.calledExpression.as(DeclReferenceExprSyntax.self),
              identifierExpr.baseName.text == "Location" else {
            return nil
        }
        
        return pattern.identifier.text
    }
    
    struct NestedItemInfo {
        let name: String
        let enumName: String
    }
    
    struct NestedLocationInfo {
        let name: String
        let enumName: String
    }
    
    private static func generateDiscoverItemsFunction(items: [NestedItemInfo]) -> DeclSyntax {
        let itemsArray = items.map { "Self.\($0.enumName).\($0.name)" }.joined(separator: ", ")
        return DeclSyntax("""
            private static func discoverItems() -> [Item] {
                [\(raw: itemsArray)]
            }
            """)
    }
    
    private static func generateDiscoverLocationsFunction(locations: [NestedLocationInfo]) -> DeclSyntax {
        let locationsArray = locations.map { "Self.\($0.enumName).\($0.name)" }.joined(separator: ", ")
        return DeclSyntax("""
            private static func discoverLocations() -> [Location] {
                [\(raw: locationsArray)]
            }
            """)
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
