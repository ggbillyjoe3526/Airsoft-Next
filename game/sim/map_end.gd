class_name MapEnd
extends RefCounted
## One end of a map (map data): where a team starts and where its hit players wait. Teams swap ends at half time
## (Character.end).

var spawns: Array[SpawnPoint] = []
var dead_zone: Array[SpawnPoint] = []
