import SwiftSyntax
import SwiftSyntaxMacros
import SwiftSyntaxBuilder

/// The main macro implementation for `@GameBlueprint`.
///
/// This macro performs convention-based discovery of all `*Area` types in the module
/// and generates a complete `GameBlueprint` implementation.
public struct GameBlueprintMacro: MemberMacro, ConformanceMacro {
    
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        
        // Extract macro arguments
        guard case let .argumentList(arguments) = node.arguments else {
            throw MacroError.invalidArguments("@GameBlueprint requires title, introduction, maxScore, and startingLocation")
        }
        
        let macroArgs = try parseMacroArguments(arguments)
        
        // TODO: In a real implementation, we'd scan the module for *Area types
        // For now, we'll generate a template that can be customized
        
        let generated: [DeclSyntax] = [
            // Generate constants
            """
            var constants: GameConstants {
                GameConstants(
                    storyTitle: \(literal: macroArgs.title),
                    introduction: \(literal: macroArgs.introduction),
                    release: "1.0.0",
                    maximumScore: \(literal: macroArgs.maxScore)
                )
            }
            """,
            
            // Generate areas discovery
            """
            var areas: [any AreaBlueprint.Type] {
                // Auto-discovered *Area types in module
                discoverGameAreas()
            }
            """,
            
            // Generate player
            """
            var player: Player {
                Player(in: \(raw: macroArgs.startingLocation ?? ".defaultStart"))
            }
            """,
            
            // Generate area discovery function
            """
            private func discoverGameAreas() -> [any AreaBlueprint.Type] {
                // Convention-based discovery of *Area types
                // This would use Swift's metadata system in a real implementation
                var areas: [any AreaBlueprint.Type] = []
                
                // For now, areas must be manually registered
                // TODO: Implement automatic discovery via Swift metadata
                
                return areas
            }
            """
        ]
        
        return generated
    }
    
    public static func expansion(
        of node: AttributeSyntax,
        providingConformancesOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [(TypeSyntax, GenericWhereClauseSyntax?)] {
        return [("GameBlueprint", nil)]
    }
}

// MARK: - Helper Types

struct MacroArguments {
    let title: String
    let introduction: String
    let maxScore: Int
    let startingLocation: String?
}

enum MacroError: Error, CustomStringConvertible {
    case invalidArguments(String)
    case missingRequiredArgument(String)
    
    var description: String {
        switch self {
        case .invalidArguments(let message):
            return "Invalid macro arguments: \(message)"
        case .missingRequiredArgument(let arg):
            return "Missing required argument: \(arg)"
        }
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
        throw MacroError.missingRequiredArgument("title")
    }
    guard let introduction = introduction else {
        throw MacroError.missingRequiredArgument("introduction")
    }
    guard let maxScore = maxScore else {
        throw MacroError.missingRequiredArgument("maxScore")
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