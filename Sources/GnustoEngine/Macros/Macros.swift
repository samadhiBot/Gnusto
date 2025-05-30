@attached(
    member,
    names: named(items),
    named(locations),
    named(itemEventHandlers),
    named(locationEventHandlers),
    named(fuseDefinitions),
    named(daemonDefinitions),
    named(dynamicAttributeRegistry),
    named(discoverItems),
    named(discoverLocations),
    named(discoverItemEventHandlers),
    named(discoverLocationEventHandlers),
    named(discoverFuseDefinitions),
    named(discoverDaemonDefinitions),
    arbitrary
)
@attached(
    extension,
    conformances: AreaBlueprint,
    names: arbitrary
)
public macro GameArea() = #externalMacro(
    module: "GnustoMacros",
    type: "GameAreaMacro"
)

@attached(member, names: arbitrary)
@attached(
    extension,
    conformances: GameBlueprint,
    names: arbitrary
)
public macro GameBlueprint() = #externalMacro(
    module: "GnustoMacros",
    type: "GameBlueprintMacro"
) 
