import SwiftSyntax
import SwiftSyntaxMacros
import SwiftDiagnostics

/// Macro implementation for `@GameItem`.
///
/// This is a peer macro that doesn't generate anything itself,
/// but marks items for processing by the GameArea extension macro.
public struct GameItemMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // This macro doesn't generate peers directly.
        // The GameArea extension macro will scan for @GameItem annotations
        // and generate the appropriate ID extensions.
        return []
    }
}

// MARK: - Supporting Macros

public struct GameLocationMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // This macro doesn't generate peers directly.
        // The GameArea extension macro will scan for @GameLocation annotations
        // and generate the appropriate ID extensions.
        return []
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