require engine.core
require Project.Core.Player.S_Player


struct LaboratorySpawnPoint {
    baseName : string
    prefabPath : string
    markerNode : NodeId
    position : float3
    rotation : quat4
    scale : float3
}


class SLaboratoryInstancePrefabs : Component {
    prefabFolder : string = "Project/Assets/Lvl_Laboratory"
    prefabExtension : string = ".prefab"
    playerName : string = "P_Player"
    markerRootNodeName : string = "Labbase"
    markerSuffix : string = "_EMPTY"
    numberedMarkerSeparator : string = "."
    spawnedNodePrefix : string = "LabSpawned_"

    spawnWhenPlayerAppears : bool = true
    useNumberedNodesAsMarkers : bool = true
    useExactPrefabNamesAsMarkers : bool = true
    scanOnlyMarkerRoot : bool = true
    cleanupPreviousSpawnedNodes : bool = true
    removeMarkersAfterSpawn : bool = true
    spawnScaleMultiplier : float = 1.0

    @no_export spawned : bool = false
    @no_export playerNode : NodeId = NodeId()
    @no_export markerRootNode : NodeId = NodeId()
    @no_export spawnPoints : array<LaboratorySpawnPoint>

    def override on_initialize() : void {
        print("=== Laboratory prefab instancer initialized ===")

        self->normalize_prefab_extension()

        spawned = false
        playerNode = NodeId()
        markerRootNode = NodeId()
        resize(spawnPoints, 0)

        if (!spawnWhenPlayerAppears) {
            self->spawn_scene_prefabs()
        }
    }

    def override on_update() : void {
        self->normalize_prefab_extension()

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

    def private normalize_prefab_extension() : void {
        if (prefabExtension == ".glb") {
            prefabExtension = ".prefab"
            print("Laboratory prefab extension switched to .prefab")
        }
    }

    def private spawn_scene_prefabs() : void {
        spawned = true

        if (cleanupPreviousSpawnedNodes) {
            self->cleanup_previous_spawned_nodes()
        }

        self->collect_spawn_points()
        print("Laboratory spawn points found: {length(spawnPoints)}")

        for (sp in spawnPoints) {
            self->spawn_prefab(sp)
        }

        print("=== Laboratory prefab instancer done ===")
    }

    def private collect_spawn_points() : void {
        resize(spawnPoints, 0)

        markerRootNode = self->find_node_by_name(markerRootNodeName)
        if (scanOnlyMarkerRoot && markerRootNode != NodeId() && markerRootNode.isAlive) {
            let children = get_children(markerRootNode)
            for (child in children) {
                self->collect_from_node(child)
            }

            if (length(spawnPoints) > 0) {
                return
            }

            print("Laboratory WARNING: marker root has no spawn points: {markerRootNodeName}, scanning whole scene")
        }

        if (scanOnlyMarkerRoot && (markerRootNode == NodeId() || !markerRootNode.isAlive)) {
            print("Laboratory WARNING: marker root not found: {markerRootNodeName}")
        }

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
                var sp : LaboratorySpawnPoint
                sp.baseName = baseName
                sp.prefabPath = prefabPath
                sp.markerNode = n
                sp.position = n.worldPosition
                sp.rotation = n.worldRotation
                sp.scale = self->get_spawn_scale(n.localScale)

                spawnPoints |> push(sp)

                print("Laboratory marker: {nodeName} -> {prefabPath}")
            } else {
                print("Laboratory WARNING: prefab path not found for marker: {nodeName}")
            }

            return
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

        if (nodeName == markerRootNodeName) {
            return false
        }

        if (find(nodeName, markerSuffix) >= 0) {
            return true
        }

        if (useNumberedNodesAsMarkers && find(nodeName, numberedMarkerSeparator) >= 0) {
            return self->is_known_prefab_base(self->get_base_name(nodeName))
        }

        if (useExactPrefabNamesAsMarkers) {
            return self->is_known_prefab_base(nodeName)
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

    def private get_spawn_scale(markerScale : float3) : float3 {
        return float3(
            markerScale.x * spawnScaleMultiplier,
            markerScale.y * spawnScaleMultiplier,
            markerScale.z * spawnScaleMultiplier
        )
    }

    def private is_known_prefab_base(baseName : string) : bool {
        if (baseName == "kolba3f" || baseName == "Kolba3f") {
            return true
        } elif (baseName == "Machine" || baseName == "machine") {
            return true
        } elif (baseName == "machine1" || baseName == "Machine1") {
            return true
        } elif (baseName == "micro" || baseName == "Micro") {
            return true
        } elif (baseName == "microscopefinal" || baseName == "Microscopefinal") {
            return true
        } elif (baseName == "Server" || baseName == "server") {
            return true
        } elif (baseName == "Table" || baseName == "table") {
            return true
        } elif (baseName == "Tanks" || baseName == "tanks") {
            return true
        }

        return false
    }

    def private get_prefab_path(baseName : string) : string {
        if (baseName == "kolba3f" || baseName == "Kolba3f") {
            return "{prefabFolder}/kolba3f.glb"
        } elif (baseName == "Machine" || baseName == "machine") {
            return "{prefabFolder}/Machine{prefabExtension}"
        } elif (baseName == "machine1" || baseName == "Machine1") {
            return "{prefabFolder}/machine1{prefabExtension}"
        } elif (baseName == "micro" || baseName == "Micro") {
            return "{prefabFolder}/micro{prefabExtension}"
        } elif (baseName == "microscopefinal" || baseName == "Microscopefinal") {
            return "{prefabFolder}/microscopefinal{prefabExtension}"
        } elif (baseName == "Server" || baseName == "server") {
            return "{prefabFolder}/Server{prefabExtension}"
        } elif (baseName == "Table" || baseName == "table") {
            return "{prefabFolder}/Table{prefabExtension}"
        } elif (baseName == "Tanks" || baseName == "tanks") {
            return "{prefabFolder}/Tanks{prefabExtension}"
        }

        return ""
    }

    def private spawn_prefab(sp : LaboratorySpawnPoint) : void {
        let prefab = request_prefab(sp.prefabPath)

        if (prefab == PrefabId()) {
            print("Laboratory WARNING: prefab not found: {sp.prefabPath}")
            return
        }

        let spawnedNode = instantiate_prefab(prefab, NodeData(
            name = "{spawnedNodePrefix}{sp.baseName}",
            position = sp.position,
            rotation = sp.rotation,
            scale = sp.scale
        ))

        if (spawnedNode == NodeId()) {
            print("Laboratory WARNING: failed to spawn prefab: {sp.prefabPath}")
            return
        }

        print("Laboratory spawned: {sp.prefabPath}")

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

    def private find_node_by_name(targetName : string) : NodeId {
        if (length(targetName) <= 0) {
            return NodeId()
        }

        let roots = get_scene_roots()
        for (root in roots) {
            let found = self->find_node_by_name_recursive(root, targetName)
            if (found != NodeId()) {
                return found
            }
        }

        return NodeId()
    }

    def private find_node_by_name_recursive(n : NodeId, targetName : string) : NodeId {
        if (n == NodeId() || !n.isAlive) {
            return NodeId()
        }

        if (n.name == targetName) {
            return n
        }

        let children = get_children(n)
        for (child in children) {
            let found = self->find_node_by_name_recursive(child, targetName)
            if (found != NodeId()) {
                return found
            }
        }

        return NodeId()
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
