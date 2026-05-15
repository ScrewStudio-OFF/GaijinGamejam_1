require engine.core
require Project.Core.Player.S_Player


struct AngarSpawnPoint {
    baseName : string
    prefabPath : string
    markerNode : NodeId
    position : float3
    rotation : quat4
    scale : float3
}


class SAngarInstancePrefabs : Component {
    prefabFolder : string = "Project/Assets/Lvl_Angar"
    playerName : string = "P_Player"
    markerRootNodeName : string = "AngarBase"
    markerSuffix : string = "_EMPTY"
    numberedMarkerSeparator : string = "."
    spawnedNodePrefix : string = "AngarSpawned_"

    spawnWhenPlayerAppears : bool = true
    useNumberedNodesAsMarkers : bool = true
    useExactPrefabNamesAsMarkers : bool = true
    scanOnlyMarkerRoot : bool = true
    cleanupPreviousSpawnedNodes : bool = true
    removeMarkersAfterSpawn : bool = true
    spawnScaleMultiplier : float = 0.1
    fixExistingSpawnedScales : bool = true

    @no_export spawned : bool = false
    @no_export existingSpawnedScalesFixed : bool = false
    @no_export playerNode : NodeId = NodeId()
    @no_export markerRootNode : NodeId = NodeId()
    @no_export spawnPoints : array<AngarSpawnPoint>

    def override on_initialize() : void {
        print("=== Angar prefab instancer initialized ===")

        spawned = false
        existingSpawnedScalesFixed = false
        playerNode = NodeId()
        markerRootNode = NodeId()
        resize(spawnPoints, 0)

        if (!spawnWhenPlayerAppears) {
            self->spawn_scene_prefabs()
        }
    }

    def override on_update() : void {
        if (fixExistingSpawnedScales && !existingSpawnedScalesFixed) {
            self->fix_existing_spawned_scales()
            existingSpawnedScalesFixed = true
        }

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
        print("Angar spawn points found: {length(spawnPoints)}")

        for (sp in spawnPoints) {
            self->spawn_prefab(sp)
        }

        print("=== Angar prefab instancer done ===")
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

            print("Angar WARNING: marker root has no spawn points: {markerRootNodeName}, scanning whole scene")
        }

        if (scanOnlyMarkerRoot && (markerRootNode == NodeId() || !markerRootNode.isAlive)) {
            print("Angar WARNING: marker root not found: {markerRootNodeName}")
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
                var sp : AngarSpawnPoint
                sp.baseName = baseName
                sp.prefabPath = prefabPath
                sp.markerNode = n
                sp.position = n.worldPosition
                sp.rotation = n.worldRotation
                sp.scale = self->get_spawn_scale(n.localScale)

                spawnPoints |> push(sp)

                print("Angar marker: {nodeName} -> {prefabPath}")
            } else {
                print("Angar WARNING: prefab path not found for marker: {nodeName}")
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
        if (baseName == "Barrel" || baseName == "barrel") {
            return true
        } elif (baseName == "Box1" || baseName == "box1") {
            return true
        } elif (baseName == "Box2" || baseName == "box2") {
            return true
        } elif (baseName == "Box3" || baseName == "box3") {
            return true
        } elif (baseName == "Box4" || baseName == "box4") {
            return true
        } elif (baseName == "Container" || baseName == "container") {
            return true
        } elif (baseName == "Crate" || baseName == "crate") {
            return true
        } elif (baseName == "Doors" || baseName == "doors") {
            return true
        } elif (baseName == "ElectricCoil" || baseName == "electricCoil") {
            return true
        } elif (baseName == "MetalPipes" || baseName == "metalPipes") {
            return true
        } elif (baseName == "Loader" || baseName == "loader") {
            return true
        } elif (baseName == "Pallet" || baseName == "pallet") {
            return true
        } elif (baseName == "Shelf" || baseName == "shelf") {
            return true
        }

        return false
    }

    def private get_prefab_path(baseName : string) : string {
        if (baseName == "Barrel" || baseName == "barrel") {
            return "{prefabFolder}/Barrel.prefab"
        } elif (baseName == "Box1" || baseName == "box1") {
            return "{prefabFolder}/Box1.prefab"
        } elif (baseName == "Box2" || baseName == "box2") {
            return "{prefabFolder}/Box2.prefab"
        } elif (baseName == "Box3" || baseName == "box3") {
            return "{prefabFolder}/Box3.prefab"
        } elif (baseName == "Box4" || baseName == "box4") {
            return "{prefabFolder}/Box4.prefab"
        } elif (baseName == "Container" || baseName == "container") {
            return "{prefabFolder}/Container.prefab"
        } elif (baseName == "Crate" || baseName == "crate") {
            return "{prefabFolder}/Crate.prefab"
        } elif (baseName == "Doors" || baseName == "doors") {
            return "{prefabFolder}/Doors.prefab"
        } elif (baseName == "ElectricCoil" || baseName == "electricCoil") {
            return "{prefabFolder}/ElectricCoil.prefab"
        } elif (baseName == "Loader" || baseName == "loader") {
            return "{prefabFolder}/Loader.prefab"
        } elif (baseName == "MetalPipes" || baseName == "metalPipes") {
            return "{prefabFolder}/MetalPipes.prefab"
        } elif (baseName == "Pallet" || baseName == "pallet") {
            return "{prefabFolder}/Pallet.prefab"
        } elif (baseName == "Shelf" || baseName == "shelf") {
            return "{prefabFolder}/Shelf.prefab"
        }

        return ""
    }

    def private spawn_prefab(sp : AngarSpawnPoint) : void {
        let prefab = request_prefab(sp.prefabPath)

        if (prefab == PrefabId()) {
            print("Angar WARNING: prefab not found: {sp.prefabPath}")
            return
        }

        let spawnedNode = instantiate_prefab(prefab, NodeData(
            name = "{spawnedNodePrefix}{sp.baseName}",
            position = sp.position,
            rotation = sp.rotation,
            scale = sp.scale
        ))

        if (spawnedNode == NodeId()) {
            print("Angar WARNING: failed to spawn prefab: {sp.prefabPath}")
            return
        }

        print("Angar spawned: {sp.prefabPath}")

        if (removeMarkersAfterSpawn && sp.markerNode != NodeId() && sp.markerNode.isAlive) {
            remove_node(sp.markerNode)
        }
    }

    def private fix_existing_spawned_scales() : void {
        let roots = get_scene_roots()
        for (root in roots) {
            self->fix_existing_spawned_scales_recursive(root)
        }
    }

    def private fix_existing_spawned_scales_recursive(n : NodeId) : void {
        if (n == NodeId() || !n.isAlive) {
            return
        }

        if (find(n.name, spawnedNodePrefix) == 0) {
            let scale = n.localScale
            if (scale.x > 0.5 || scale.y > 0.5 || scale.z > 0.5) {
                n.localScale = self->get_spawn_scale(scale)
                print("Angar fixed spawned scale: {n.name}")
            }

            return
        }

        let children = get_children(n)
        for (child in children) {
            self->fix_existing_spawned_scales_recursive(child)
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
