require engine.core
require Project.Core.Player.S_Player


struct GreenHouseSpawnPoint {
    baseName : string
    prefabPath : string
    markerNode : NodeId
    position : float3
    rotation : quat4
    scale : float3
}


class SGreenHouseInstancePrefabs : Component {
    prefabFolder : string = "Project/Assets/Lvl_Greenhouse"
    playerName : string = "P_Player"
    markerSuffix : string = "_EMPTY"
    numberedMarkerSeparator : string = "."
    spawnedNodePrefix : string = "GHSpawned_"

    spawnWhenPlayerAppears : bool = true
    useNumberedNodesAsMarkers : bool = true
    cleanupPreviousSpawnedNodes : bool = true
    removeMarkersAfterSpawn : bool = true

    gardenSquareYOffset : float = -0.5
    waterTankYOffset : float = -1.1

    @no_export spawned : bool = false
    @no_export playerNode : NodeId = NodeId()
    @no_export spawnPoints : array<GreenHouseSpawnPoint>

    def override on_initialize() : void {
        print("=== GreenHouse prefab instancer initialized ===")

        spawned = false
        playerNode = NodeId()
        resize(spawnPoints, 0)

        if (!spawnWhenPlayerAppears) {
            self->spawn_scene_prefabs()
        }
    }

    def override on_update() : void {
        if (spawned) {
            return
        }

        if (spawnWhenPlayerAppears) {
            if (playerNode == NodeId() || !playerNode.isAlive) {
                self->find_player()
            }

            if (playerNode == NodeId() || !playerNode.isAlive) {
                return
            }
        }

        self->spawn_scene_prefabs()
    }

    def override on_destroy() : void {
        pass
    }

    def private spawn_scene_prefabs() : void {
        spawned = true

        if (cleanupPreviousSpawnedNodes) {
            self->cleanup_previous_spawned_nodes()
        }

        self->collect_spawn_points()
        print("GreenHouse spawn points found: {length(spawnPoints)}")

        for (sp in spawnPoints) {
            self->spawn_prefab(sp)
        }

        print("=== GreenHouse prefab instancer done ===")
    }

    def private collect_spawn_points() : void {
        resize(spawnPoints, 0)

        let roots = get_scene_roots()
        for (root in roots) {
            self->collect_from_node(root)
        }
    }

    def private collect_from_node(n : NodeId) : void {
        if (n == NodeId() || !n.isAlive) {
            return
        }

        let nodeName = n.name
        if (self->is_spawn_marker(nodeName)) {
            let baseName = self->get_base_name(nodeName)
            let prefabPath = self->get_prefab_path(baseName)

            if (length(prefabPath) > 0) {
                var sp : GreenHouseSpawnPoint
                sp.baseName = baseName
                sp.prefabPath = prefabPath
                sp.markerNode = n
                sp.position = n.worldPosition
                sp.position.y = sp.position.y + self->get_spawn_y_offset(baseName)
                sp.rotation = n.worldRotation
                sp.scale = n.localScale

                spawnPoints |> push(sp)

                print("GreenHouse marker: {nodeName} -> {prefabPath}")
            } else {
                print("GreenHouse WARNING: prefab path not found for marker: {nodeName}")
            }
        }

        let children = get_children(n)
        for (child in children) {
            self->collect_from_node(child)
        }
    }

    def private is_spawn_marker(nodeName : string) : bool {
        if (find(nodeName, spawnedNodePrefix) == 0) {
            return false
        }

        if (find(nodeName, markerSuffix) >= 0) {
            return true
        }

        if (useNumberedNodesAsMarkers && find(nodeName, numberedMarkerSeparator) >= 0) {
            return true
        }

        return false
    }

    def private get_base_name(nodeName : string) : string {
        var result = nodeName

        let suffixIdx = find(result, markerSuffix)
        if (suffixIdx >= 0) {
            result = slice(result, 0, suffixIdx)
        }

        let numberIdx = find(result, numberedMarkerSeparator)
        if (useNumberedNodesAsMarkers && numberIdx >= 0) {
            result = slice(result, 0, numberIdx)
        }

        return result
    }

    def private get_spawn_y_offset(baseName : string) : float {
        if (baseName == "garden_square" || find(baseName, "garden_square.") == 0) {
            return gardenSquareYOffset
        } elif (baseName == "water_tank" || baseName == "water_tank.001" || find(baseName, "water_tank.") == 0) {
            return waterTankYOffset
        }

        return 0.0
    }

    def private get_prefab_path(baseName : string) : string {
        if (baseName == "shelf" || baseName == "Shelf" || find(baseName, "shelf.") == 0 || find(baseName, "Shelf.") == 0) {
            return "{prefabFolder}/shelf.prefab"
        } elif (baseName == "water_tank" || baseName == "water_tank.001" || baseName == "WaterTank" || find(baseName, "water_tank.") == 0) {
            return "{prefabFolder}/water_tank.001.prefab"
        }

        var prefabName = baseName
        let dotIdx = find(prefabName, ".")
        if (dotIdx >= 0) {
            prefabName = slice(prefabName, 0, dotIdx)
        }

        return "{prefabFolder}/{prefabName}.prefab"
    }

    def private spawn_prefab(sp : GreenHouseSpawnPoint) : void {
        let prefab = request_prefab(sp.prefabPath)

        if (prefab == PrefabId()) {
            print("GreenHouse WARNING: prefab not found: {sp.prefabPath}")
            return
        }

        let spawnedNode = instantiate_prefab(prefab, NodeData(
            name = "{spawnedNodePrefix}{sp.baseName}",
            position = sp.position,
            rotation = sp.rotation,
            scale = sp.scale
        ))

        if (spawnedNode == NodeId()) {
            print("GreenHouse WARNING: failed to spawn prefab: {sp.prefabPath}")
            return
        }

        print("GreenHouse spawned: {sp.prefabPath}")

        if (removeMarkersAfterSpawn && sp.markerNode != NodeId() && sp.markerNode.isAlive) {
            remove_node(sp.markerNode)
        }
    }

    def private cleanup_previous_spawned_nodes() : void {
        let roots = get_scene_roots()
        for (root in roots) {
            self->cleanup_previous_spawned_recursive(root)
        }
    }

    def private cleanup_previous_spawned_recursive(n : NodeId) : void {
        if (n == NodeId() || !n.isAlive) {
            return
        }

        let children = get_children(n)
        for (child in children) {
            self->cleanup_previous_spawned_recursive(child)
        }

        if (find(n.name, spawnedNodePrefix) == 0) {
            remove_node(n)
        }
    }

    def private find_player() : void {
        let roots = get_scene_roots()

        for (root in roots) {
            let found = self->find_player_recursive(root)
            if (found != NodeId()) {
                playerNode = found
                return
            }
        }
    }

    def private find_player_recursive(n : NodeId) : NodeId {
        if (n == NodeId() || !n.isAlive) {
            return NodeId()
        }

        let player = get_component(n, type<SPlayer>)
        if (player != null) {
            return n
        }

        if (n.name == playerName) {
            return n
        }

        let children = get_children(n)
        for (child in children) {
            let found = self->find_player_recursive(child)
            if (found != NodeId()) {
                return found
            }
        }

        return NodeId()
    }
}
