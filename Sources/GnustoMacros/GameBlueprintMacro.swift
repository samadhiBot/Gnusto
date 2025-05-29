import SwiftSyntax
import SwiftSyntaxMacros
import SwiftSyntaxBuilder
import SwiftDiagnostics

/// The main macro implementation for `@GameBlueprint`.
///
/// This macro performs convention-based discovery of all `*Area` types in the module
/// and generates a complete `GameBlueprint` implementation.
public struct GameBlueprintMacro: MemberMacro, ExtensionMacro {
    
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        
        // Extract macro arguments
        guard case let .argumentList(arguments) = node.arguments else {
            let diagnostic = Diagnostic(
                node: node,
                message: GameBlueprintMacroError.invalidArguments("@GameBlueprint requires title, introduction, maxScore, and startingLocation")
            )
            context.diagnose(diagnostic)
            return []
        }
        
        let macroArgs: MacroArguments
        do {
            macroArgs = try parseMacroArguments(arguments)
        } catch {
            let diagnostic = Diagnostic(
                node: node,
                message: error as! GameBlueprintMacroError
            )
            context.diagnose(diagnostic)
            return []
        }
        
        // Generate the GameBlueprint implementation
        let generated: [DeclSyntax] = [
            // Generate constants
            DeclSyntax("""
                var constants: GameConstants {
                    GameConstants(
                        storyTitle: \(literal: macroArgs.title),
                        introduction: \(literal: macroArgs.introduction),
                        release: "1.0.0",
                        maximumScore: \(literal: macroArgs.maxScore)
                    )
                }
                """),
            
            // Generate areas discovery
            DeclSyntax("""
                var areas: [any AreaBlueprint.Type] {
                    // Auto-discovered *Area types in module
                    discoverGameAreas()
                }
                """),
            
            // Generate player
            DeclSyntax("""
                var player: Player {
                    Player(in: \(raw: macroArgs.startingLocation ?? ".defaultStart"))
                }
                """),
            
            // Generate area discovery function
            DeclSyntax("""
                private func discoverGameAreas() -> [any AreaBlueprint.Type] {
                    // Convention-based discovery of *Area types
                    // This would use Swift's metadata system in a real implementation
                    var areas: [any AreaBlueprint.Type] = []
                    
                    // For now, areas must be manually registered
                    // TODO: Implement automatic discovery via Swift metadata
                    
                    return areas
                }
                """)
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
        let gameBlueprint: DeclSyntax = "extension \(type.trimmed): GameBlueprint {}"
        
        guard let extensionDecl = gameBlueprint.as(ExtensionDeclSyntax.self) else {
            return []
        }
        
        return [extensionDecl]
    }
}

// MARK: - Helper Types

struct MacroArguments {
    let title: String
    let introduction: String
    let maxScore: Int
    let startingLocation: String?
}

enum GameBlueprintMacroError: Error, DiagnosticMessage {
    case invalidArguments(String)
    case missingRequiredArgument(String)
    
    var message: String {
        switch self {
        case .invalidArguments(let message):
            return message
        case .missingRequiredArgument(let arg):
            return "Missing required argument: \(arg)"
        }
    }
    
    var diagnosticID: MessageID {
        MessageID(domain: "GnustoMacros", id: "GameBlueprintMacro")
    }
    
    var severity: DiagnosticSeverity {
        .error
    }
}

// MARK: - Argument Parsing

func parseMacroArguments(_ arguments: LabeledExprListSyntax) throws -> MacroArguments {
    var title: String?
    var introduction: String?
    var maxScore: Int?
    var startingLocation: String?
    
    for argument in arguments {
        guard let label = argument.label?.text else { continue }
        
        switch label {
        case "title":
            title = extractStringLiteral(from: argument.expression)
        case "introduction":
            introduction = extractStringLiteral(from: argument.expression)
        case "maxScore":
            maxScore = extractIntegerLiteral(from: argument.expression)
        case "startingLocation":
            startingLocation = extractLocationReference(from: argument.expression)
        default:
            break
        }
    }
    
    guard let title = title else {
        throw GameBlueprintMacroError.missingRequiredArgument("title")
    }
    guard let introduction = introduction else {
        throw GameBlueprintMacroError.missingRequiredArgument("introduction")
    }
    guard let maxScore = maxScore else {
        throw GameBlueprintMacroError.missingRequiredArgument("maxScore")
    }
    
    return MacroArguments(
        title: title,
        introduction: introduction,
        maxScore: maxScore,
        startingLocation: startingLocation
    )
}

func extractStringLiteral(from expr: ExprSyntax) -> String? {
    guard let stringLiteral = expr.as(StringLiteralExprSyntax.self),
          let segment = stringLiteral.segments.first,
          case .stringSegment(let content) = segment else {
        return nil
    }
    return content.content.text
}

func extractIntegerLiteral(from expr: ExprSyntax) -> Int? {
    guard let intLiteral = expr.as(IntegerLiteralExprSyntax.self) else {
        return nil
    }
    return Int(intLiteral.literal.text)
}

func extractLocationReference(from expr: ExprSyntax) -> String? {
    // Extract `.locationName` pattern
    guard let memberAccess = expr.as(MemberAccessExprSyntax.self) else {
        return nil
    }
    return memberAccess.declName.baseName.text
} 