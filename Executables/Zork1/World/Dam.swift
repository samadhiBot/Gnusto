import GnustoEngine

enum Dam {
    static let damLobby = Location(
        id: .damLobby,
        .name("Dam Lobby"),
        .description("""
            This room appears to have been the waiting room for groups touring
            the dam. There are open doorways here to the north and east marked
            "Private", and there is a path leading south over the top of the dam.
            """),
        .exits([
            .south: .to(.damRoom),
            .north: .to(.maintenanceRoom),
            .east: .to(.maintenanceRoom)
        ]),
        .isLand,
        .inherentlyLit
    )

    static let damRoom = Location(
        id: .damRoom,
        .name("Dam"),
        .description("""
            You are standing on top of the Flood Control Dam #3.
            """),
        .exits([
            .south: .to(.deepCanyon),
            .down: .to(.damBase),
            .east: .to(.damBase),
            .north: .to(.damLobby),
            .west: .to(.reservoirSouth)
        ]),
        .isLand,
        .inherentlyLit,
        .localGlobals(.globalWater)
    )

    static let maintenanceRoom = Location(
        id: .maintenanceRoom,
        .name("Maintenance Room"),
        .description("""
            This is what appears to have been the maintenance room for Flood
            Control Dam #3. Apparently, this room has been ransacked recently, for
            most of the valuable equipment is gone. On the wall in front of you is a
            group of buttons colored blue, yellow, brown, and red. There are doorways to
            the west and south.
            """),
        .exits([
            .south: .to(.damLobby),
            .west: .to(.damLobby)
        ]),
        .isLand
    )
}
