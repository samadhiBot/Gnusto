import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct GnustoMacroPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        GameAreaMacro.self,
        GameBlueprintMacro.self,
    ]
} 
