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
        
        // Scan for all game content including event handlers
        let (items, locations, itemHandlers, locationHandlers) = scanForGameContent(from: enumDecl)
        
        // Generate the required discovery properties
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
        
        // Add discovery function implementations
        members.append(contentsOf: [
            generateDiscoverItemsFunction(items: items),
            generateDiscoverLocationsFunction(locations: locations),
            generateDiscoverItemEventHandlersFunction(handlers: itemHandlers),
            generateDiscoverLocationEventHandlersFunction(handlers: locationHandlers),
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
        
        guard let enumDecl = declaration.as(EnumDeclSyntax.self) else {
            return []
        }
        
        // Scan for content to generate ID extensions
        let (items, locations, _, _) = scanForGameContent(from: enumDecl)
        let itemNames = items.map { $0.name }
        let locationNames = locations.map { $0.name }
        
        var extensions: [ExtensionDeclSyntax] = []
        
        // Add AreaBlueprint conformance
        let areaBlueprintConformance = try ExtensionDeclSyntax("extension \(type): AreaBlueprint") {
            // Empty - conformance is provided by generated members
        }
        extensions.append(areaBlueprintConformance)
        
        // Generate ItemID extension if there are items
        if !itemNames.isEmpty {
            var itemIDMembers: [DeclSyntax] = []
            for itemName in itemNames {
                itemIDMembers.append(DeclSyntax("""
                    static let \(raw: itemName) = ItemID("\(raw: itemName)")
                    """))
            }
            
            let itemIDExtension: DeclSyntax = "extension ItemID {}"
            if var extensionDecl = itemIDExtension.as(ExtensionDeclSyntax.self) {
                extensionDecl.memberBlock.members = MemberBlockItemListSyntax(
                    itemIDMembers.map { MemberBlockItemSyntax(decl: $0) }
                )
                extensions.append(extensionDecl)
            }
        }
        
        // Generate LocationID extension if there are locations
        if !locationNames.isEmpty {
            var locationIDMembers: [DeclSyntax] = []
            for locationName in locationNames {
                locationIDMembers.append(DeclSyntax("""
                    static let \(raw: locationName) = LocationID("\(raw: locationName)")
                    """))
            }
            
            let locationIDExtension: DeclSyntax = "extension LocationID {}"
            if var extensionDecl = locationIDExtension.as(ExtensionDeclSyntax.self) {
                extensionDecl.memberBlock.members = MemberBlockItemListSyntax(
                    locationIDMembers.map { MemberBlockItemSyntax(decl: $0) }
                )
                extensions.append(extensionDecl)
            }
        }
        
        return extensions
    }
    
    // MARK: - Type Inference Scanning
    
    private static func scanForGameContent(from enumDecl: EnumDeclSyntax) -> ([NestedItemInfo], [NestedLocationInfo], [EventHandlerInfo], [EventHandlerInfo]) {
        var items: [NestedItemInfo] = []
        var locations: [NestedLocationInfo] = []
        var itemHandlers: [EventHandlerInfo] = []
        var locationHandlers: [EventHandlerInfo] = []
        
        // Scan all members of the enum
        for member in enumDecl.memberBlock.members {
            if let nestedEnum = member.decl.as(EnumDeclSyntax.self) {
                // Scan nested enums for items and locations
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
            } else if let varDecl = member.decl.as(VariableDeclSyntax.self) {
                // Scan top-level static properties for event handlers
                if let handlerInfo = getEventHandlerInfo(from: varDecl) {
                    if handlerInfo.type == "ItemEventHandler" {
                        itemHandlers.append(handlerInfo)
                    } else if handlerInfo.type == "LocationEventHandler" {
                        locationHandlers.append(handlerInfo)
                    }
                }
            }
        }
        
        return (items, locations, itemHandlers, locationHandlers)
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
    
    private static func getEventHandlerInfo(from varDecl: VariableDeclSyntax) -> EventHandlerInfo? {
        guard varDecl.bindingSpecifier.text == "let",
              varDecl.modifiers.contains(where: { $0.name.text == "static" }),
              let binding = varDecl.bindings.first,
              let pattern = binding.pattern.as(IdentifierPatternSyntax.self),
              let initializer = binding.initializer,
              let functionCall = initializer.value.as(FunctionCallExprSyntax.self),
              let identifierExpr = functionCall.calledExpression.as(DeclReferenceExprSyntax.self) else {
            return nil
        }
        
        let handlerName = pattern.identifier.text
        let handlerType = identifierExpr.baseName.text
        
        // Only process if it's an event handler
        guard handlerType == "ItemEventHandler" || handlerType == "LocationEventHandler" else {
            return nil
        }
        
        // Extract the target name from the handler name by removing "Handler" suffix
        guard handlerName.hasSuffix("Handler") else {
            return nil
        }
        
        let targetName = String(handlerName.dropLast("Handler".count))
        
        return EventHandlerInfo(
            name: handlerName,
            targetName: targetName,
            type: handlerType
        )
    }
    
    struct NestedItemInfo {
        let name: String
        let enumName: String
    }
    
    struct NestedLocationInfo {
        let name: String
        let enumName: String
    }
    
    struct EventHandlerInfo {
        let name: String        // e.g., "cloakHandler"
        let targetName: String  // e.g., "cloak"
        let type: String        // "ItemEventHandler" or "LocationEventHandler"
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
    
    private static func generateDiscoverItemEventHandlersFunction(handlers: [EventHandlerInfo]) -> DeclSyntax {
        if handlers.isEmpty {
            return DeclSyntax("""
                private static func discoverItemEventHandlers() -> [ItemID: ItemEventHandler] {
                    [:]
                }
                """)
        }
        
        let handlerMappings = handlers.map { handler in
            "ItemID(\"\(handler.targetName)\"): Self.\(handler.name)"
        }.joined(separator: ", ")
        
        return DeclSyntax("""
            private static func discoverItemEventHandlers() -> [ItemID: ItemEventHandler] {
                [\(raw: handlerMappings)]
            }
            """)
    }
    
    private static func generateDiscoverLocationEventHandlersFunction(handlers: [EventHandlerInfo]) -> DeclSyntax {
        if handlers.isEmpty {
            return DeclSyntax("""
                private static func discoverLocationEventHandlers() -> [LocationID: LocationEventHandler] {
                    [:]
                }
                """)
        }
        
        let handlerMappings = handlers.map { handler in
            "LocationID(\"\(handler.targetName)\"): Self.\(handler.name)"
        }.joined(separator: ", ")
        
        return DeclSyntax("""
            private static func discoverLocationEventHandlers() -> [LocationID: LocationEventHandler] {
                [\(raw: handlerMappings)]
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
