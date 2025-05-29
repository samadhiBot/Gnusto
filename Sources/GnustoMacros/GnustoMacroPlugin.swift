import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct GnustoMacroPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        GameBlueprintMacro.self,
        GameAreaMacro.self,
        GameItemMacro.self,
        GameLocationMacro.self,
        ItemEventHandlerMacro.self,
        LocationEventHandlerMacro.self,
        GameFuseMacro.self,
        GameDaemonMacro.self,
    ]
} 