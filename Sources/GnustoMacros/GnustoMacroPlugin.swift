import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct GnustoMacroPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        GameAreaMacro.self,
        GameBlueprintMacro.self,
        GameItemMacro.self,
        GameLocationMacro.self,
        ItemEventHandlerMacro.self,
        LocationEventHandlerMacro.self,
        GameFuseMacro.self,
        GameDaemonMacro.self,
    ]
} 