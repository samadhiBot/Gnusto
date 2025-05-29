import SwiftSyntax
import SwiftSyntaxMacros
import SwiftDiagnostics

/// Macro implementation for `@GameItem`.
///
/// This macro generates global ID constants by adding extensions to ItemID.
public struct GameItemMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        
        guard let varDecl = declaration.as(VariableDeclSyntax.self),
              let binding = varDecl.bindings.first,
              let identifier = binding.pattern.as(IdentifierPatternSyntax.self) else {
            let diagnostic = Diagnostic(
                node: Syntax(declaration),
                message: GameItemMacroError.invalidDeclaration("@GameItem can only be applied to variable declarations")
            )
            context.diagnose(diagnostic)
            return []
        }
        
        let itemName = identifier.identifier.text
        
        // Generate extension to ItemID for global accessibility
        return [
            DeclSyntax("""
                extension ItemID {
                    static let \(raw: itemName) = ItemID("\(raw: itemName)")
                }
                """)
        ]
    }
}

// MARK: - Supporting Macros

public struct GameLocationMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        
        guard let varDecl = declaration.as(VariableDeclSyntax.self),
              let binding = varDecl.bindings.first,
              let identifier = binding.pattern.as(IdentifierPatternSyntax.self) else {
            let diagnostic = Diagnostic(
                node: Syntax(declaration),
                message: GameItemMacroError.invalidDeclaration("@GameLocation can only be applied to variable declarations")
            )
            context.diagnose(diagnostic)
            return []
        }
        
        let locationName = identifier.identifier.text
        
        // Generate extension to LocationID for global accessibility
        return [
            DeclSyntax("""
                extension LocationID {
                    static let \(raw: locationName) = LocationID("\(raw: locationName)")
                }
                """)
        ]
    }
}

public struct ItemEventHandlerMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // For now, just return empty - handlers are registered by the area macro
        return []
    }
}

public struct LocationEventHandlerMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // For now, just return empty - handlers are registered by the area macro
        return []
    }
}

public struct GameFuseMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // For now, just return empty - fuses are registered by the area macro
        return []
    }
}

public struct GameDaemonMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // For now, just return empty - daemons are registered by the area macro
        return []
    }
}

// MARK: - Error Types

enum GameItemMacroError: Error, DiagnosticMessage {
    case invalidDeclaration(String)
    
    var message: String {
        switch self {
        case .invalidDeclaration(let message):
            return "Invalid macro declaration: \(message)"
        }
    }
    
    var diagnosticID: MessageID {
        MessageID(domain: "GnustoMacros", id: "GameItemMacro")
    }
    
    var severity: DiagnosticSeverity {
        .error
    }
} 