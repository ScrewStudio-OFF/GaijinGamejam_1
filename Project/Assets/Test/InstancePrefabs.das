require engine.core

struct SpawnPoint {
    baseName   : string
    prefabName : string
    position   : float3
    rotation   : quat4
}

class InstancePrefabs : Component {

    spawnPoints : array<SpawnPoint>

    def override on_initialize() : void {
        print("=== InstancePrefabs START ===")

        self->collectSpawnPoints()

        print("Spawn points found: {length(self.spawnPoints)}")

        self->spawnAll()

        print("=== InstancePrefabs END ===")
    }

    def override on_update() : void {
        pass
    }

    def override on_destroy() : void {
        pass
    }

    def getPrefabPath(baseName : string) : string {
        if ( baseName == "Barrier" ) {
            return "Project/Assets/Test/Barrier.prefab"
        } elif ( baseName == "CapCam" ) {
            return "Project/Assets/Test/CapCam.prefab"
        } elif ( baseName == "Cart" ) {
            return "Project/Assets/Test/Cart.prefab"
        } elif ( baseName == "ChirurgStol" ) {
            return "Project/Assets/Test/ChirurgStol.prefab"
        } elif ( baseName == "Door" ) {
            return "Project/Assets/Test/Door.prefab"
        } elif ( baseName == "EmissivePart" ) {
            return "Project/Assets/Test/EmissivePart.prefab"
        } elif ( baseName == "OperableTable" ) {
            return "Project/Assets/Test/OperableTable.prefab"
        } elif ( baseName == "Shelves" ) {
            return "Project/Assets/Test/Shelves.prefab"
        } elif ( baseName == "ShelfCorp" ) {
            return "Project/Assets/Test/Shelves.prefab"
        } elif ( baseName == "Shelv" ) {
            return "Project/Assets/Test/Shelves.prefab"
        } elif ( baseName == "Stool" ) {
            return "Project/Assets/Test/Stool.prefab"
        } elif ( baseName == "ThermoCorps" ) {
            return "Project/Assets/Test/ThermoCorps.prefab"
        }

        return ""
    }

    def getBaseName(nodeName : string) : string {
        var result = nodeName

        // Barrier.003_EMPTY.001 -> Barrier.003
        let emptyIdx = find(result, "_EMPTY")

        if ( emptyIdx >= 0 ) {
            result = slice(result, 0, emptyIdx)
        }

        // Barrier.003 -> Barrier
        let dotIdx = find(result, ".")

        if ( dotIdx >= 0 ) {
            result = slice(result, 0, dotIdx)
        }

        return result
    }

    def collectSpawnPoints() : void {
        let roots = get_scene_roots()

        print("Scene roots count: {length(roots)}")

        for ( root in roots ) {
            self->collectFromNode(root)
        }
    }

    def collectFromNode(nodeId : NodeId) : void {
        let nodeName = nodeId.name

        if ( find(nodeName, "_EMPTY") >= 0 ) {
            let baseName = self->getBaseName(nodeName)
            let prefabPath = self->getPrefabPath(baseName)

            print("FOUND SPAWN EMPTY: {nodeName}")
            print("BASE NAME: {baseName}")
            print("PREFAB PATH: {prefabPath}")

            if ( length(prefabPath) > 0 ) {
                var sp : SpawnPoint

                sp.baseName   = baseName
                sp.prefabName = prefabPath
                sp.position   = nodeId.worldPosition
                sp.rotation   = nodeId.worldRotation

                // CapCam и ThermoCorps опускаем на 1 метр по Y
                if ( baseName == "CapCam" ) {
                    sp.position.y = sp.position.y - 1.0
                } elif ( baseName == "ThermoCorps" ) {
                    sp.position.y = sp.position.y - 1.0
                    sp.position.z = sp.position.z + 0.5
                }

                // Shelves опускаем на 0.5 метра по Y
                if ( baseName == "Shelves" ) {
                    sp.position.y = sp.position.y - 0.5
                } elif ( baseName == "ShelfCorp" ) {
                    sp.position.y = sp.position.y - 0.5
                } elif ( baseName == "Shelv" ) {
                    sp.position.y = sp.position.y - 0.5
                }

                self.spawnPoints |> push(sp)
            } else {
                print("WARNING: prefab path not found for base name: {baseName}")
            }
        }

        let children = get_children(nodeId)

        for ( child in children ) {
            self->collectFromNode(child)
        }
    }

    def addLightToEmissivePart(parentNode : NodeId) : void {
        print("ADDING SPOT LIGHT TO EMISSIVE PART")

        let lightNode = create_node(NodeData(
            name = "spot_light",
            parent = parentNode,

            position = float3(0.0, 2.8888, 0.3552),
            rotation = quat4(0.610865, 0.0, 0.0),
            scale = float3(1.0, 1.0, 1.0)
        ))

        add_component(lightNode, new SpotLight(
            castShadows = true,
            castShadowsOnlyForStatic = false,

            intensity = 1.0,
            color = float3(1.0, 1.0, 1.0),

            radius = 8.08,
            angle = 1.04883,
            attenuation = 0.55
        ))
    }

    def spawnAll() : void {
        for ( sp in self.spawnPoints ) {
            print("Trying to spawn prefab: {sp.prefabName}")

            let prefab = request_prefab(sp.prefabName)

            if ( prefab == PrefabId() ) {
                print("WARNING: prefab not found: {sp.prefabName}")
                continue
            }

            let node = instantiate_prefab(prefab, NodeData(
                position = sp.position,
                rotation = sp.rotation
            ))

            print("SPAWNED OK: {sp.prefabName}")

            if ( sp.baseName == "EmissivePart" ) {
                self->addLightToEmissivePart(node)
            }
        }
    }
}