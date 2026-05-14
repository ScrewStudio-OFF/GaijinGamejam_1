require engine.core
require engine.math.math_utils
require Project.Core.Player.S_Player
require Project.Core.Player.S_CameraFollow
require Project.Mechanics.Combat.S_Damageable
require Project.Mechanics.UIUX.S_GameUI


def level_trigger_find_node_recursive(nodeId : NodeId, nodeName : string) : NodeId {
    if ( nodeId.name == nodeName ) {
        return nodeId
    }

    let children = get_children(nodeId)

    for ( child in children ) {
        let found = level_trigger_find_node_recursive(child, nodeName)

        if ( found != NodeId() ) {
            return found
        }
    }

    return NodeId()
}

class LevelTrigger : Component {

    playerNode : NodeId
    triggerNode : NodeId

    playerName : string = "P_Player"
    triggerNodeName : string = "empty_mesh"

    targetLevelPath : string = "Project/Levels/Lvl_Morgue.prefab"
    targetLevelName : string = "LoadedLevel"

    playerPrefabPath : string = "Project/Core/Player/P_Player.prefab"
    cameraPrefabPath : string = "Project/Core/Player/P_FollowCamera.prefab"
    cameraName : string = "P_FollowCamera"
    cameraOffset : float3 = float3(0.0, 10.0, -5.0)

    playerSpawnNodeName : string = "PlayerSpawn"
    playerSpawnPosition : float3 = float3(0.0, 1.0, 0.0)
    playerSpawnRotation : quat4 = quat4()

    preservePlayerHealth : bool = true

    triggerRadius : float = 3.0

    triggered : bool = false

    def override on_initialize() : void {
        print("=== LevelTrigger initialized ===")

        if ( self.playerNode == NodeId() ) {
            print("playerNode is not assigned, trying to find Player automatically")
            self->findPlayer()
        } else {
            print("Player node: {self.playerNode.hierarchyName}")
        }

        if ( self.triggerNode == NodeId() || !self.triggerNode.isAlive ) {
            self->findTriggerNode()
        }

        if ( self.triggerNode == NodeId() || !self.triggerNode.isAlive ) {
            print("WARNING: triggerNode is not assigned")
        } else {
            print("Trigger node: {self.triggerNode.hierarchyName}")
        }

        print("Target level: {self.targetLevelPath}")

        self.triggered = false
    }

    def override on_update() : void {
        if ( self.triggered ) {
            return
        }

        if ( self.playerNode == NodeId() || !self.playerNode.isAlive ) {
            self->findPlayer()
        }

        if ( self.triggerNode == NodeId() || !self.triggerNode.isAlive ) {
            self->findTriggerNode()
        }

        if ( self.playerNode == NodeId() || !self.playerNode.isAlive ) {
            return
        }

        if ( self.triggerNode == NodeId() || !self.triggerNode.isAlive ) {
            return
        }

        let playerPos = self.playerNode.worldPosition
        let triggerPos = self.triggerNode.worldPosition

        let d = length(playerPos - triggerPos)

        if ( d <= self.triggerRadius ) {
            print("PLAYER ENTERED LEVEL TRIGGER")
            print("Distance: {d}")
            print("Loading level: {self.targetLevelPath}")

            self.triggered = true
            self->loadTargetLevel()
        }
    }

    def override on_destroy() : void {
        pass
    }

    def findPlayer() : void {
        let roots = get_scene_roots()

        for ( root in roots ) {
            let found = self->findPlayerRecursive(root)

            if ( found != NodeId() ) {
                self.playerNode = found
                print("Player found: {self.playerNode.hierarchyName}")
                return
            }
        }

        print("WARNING: Player not found")
    }

    def findTriggerNode() : void {
        if ( length(self.triggerNodeName) <= 0 ) {
            return
        }

        let localFound = level_trigger_find_node_recursive(nodeId, self.triggerNodeName)

        if ( localFound != NodeId() ) {
            self.triggerNode = localFound
            print("Trigger node found: {self.triggerNode.hierarchyName}")
            return
        }

        let roots = get_scene_roots()

        for ( root in roots ) {
            let found = level_trigger_find_node_recursive(root, self.triggerNodeName)

            if ( found != NodeId() ) {
                self.triggerNode = found
                print("Trigger node found: {self.triggerNode.hierarchyName}")
                return
            }
        }
    }

    def findPlayerRecursive(n : NodeId) : NodeId {
        let player = get_component(n, type<SPlayer>)

        if ( player != null ) {
            return n
        }

        if ( n.name == self.playerName ) {
            return n
        }

        if ( find(n.hierarchyName, self.playerName) >= 0 ) {
            return n
        }

        let children = get_children(n)

        for ( child in children ) {
            let found = self->findPlayerRecursive(child)

            if ( found != NodeId() ) {
                return found
            }
        }

        return NodeId()
    }

    def loadTargetLevel() : void {
        let levelPrefab = request_prefab(self.targetLevelPath)
        let playerPrefab = request_prefab(self.playerPrefabPath)
        let cameraPrefab = request_prefab(self.cameraPrefabPath)

        if ( levelPrefab == PrefabId() ) {
            print("WARNING: target level prefab not found: {self.targetLevelPath}")
            self.triggered = false
            return
        }

        if ( playerPrefab == PrefabId() ) {
            print("WARNING: player prefab not found: {self.playerPrefabPath}")
            self.triggered = false
            return
        }

        if ( cameraPrefab == PrefabId() ) {
            print("WARNING: camera prefab not found: {self.cameraPrefabPath}")
            self.triggered = false
            return
        }

        var savedCameraOffset = self.cameraOffset
        var savedCameraYaw = 0.0
        var hasSavedCameraState = false

        let activeCameraFollow = find_component(type<SCameraFollow>)
        if ( activeCameraFollow != null ) {
            savedCameraOffset = activeCameraFollow.offset
            savedCameraYaw = activeCameraFollow.yaw
            hasSavedCameraState = true
        }

        let levelName = self.targetLevelName
        let spawnedPlayerName = self.playerName
        let spawnedCameraName = self.cameraName
        let spawnedCameraOffset = savedCameraOffset
        let spawnNodeName = self.playerSpawnNodeName
        var spawnPosition = self.playerSpawnPosition
        var spawnRotation = self.playerSpawnRotation
        let shouldPreserveHealth = self.preservePlayerHealth
        var savedPlayerHealth = -1.0
        var savedPlayerMaxHealth = -1.0

        if ( shouldPreserveHealth && self.playerNode != NodeId() && self.playerNode.isAlive ) {
            get_component(self.playerNode) $(var damageable : SDamageable?) {
                if ( damageable != null ) {
                    savedPlayerHealth = damageable.health
                    savedPlayerMaxHealth = damageable.maxHealth
                }
            }
        }

        clear_scene()

        let levelNode = instantiate_prefab(levelPrefab, NodeData(
            name = levelName
        ))

        if ( levelNode != NodeId() && length(spawnNodeName) > 0 ) {
            let spawnNode = level_trigger_find_node_recursive(levelNode, spawnNodeName)

            if ( spawnNode != NodeId() ) {
                spawnPosition = spawnNode.worldPosition
                spawnRotation = spawnNode.worldRotation
                print("Player spawn node found: {spawnNode.hierarchyName}")
            } else {
                print("WARNING: spawn node not found: {spawnNodeName}, using fallback position")
            }
        }

        let newCamera = instantiate_prefab(cameraPrefab, NodeData(
            name = spawnedCameraName,
            position = spawnPosition + spawnedCameraOffset
        ))

        let newPlayer = instantiate_prefab(playerPrefab, NodeData(
            name = spawnedPlayerName,
            position = spawnPosition,
            rotation = spawnRotation
        ))

        get_component(newCamera) $(var cameraFollow : SCameraFollow?) {
            if ( cameraFollow != null ) {
                cameraFollow.target = newPlayer
                cameraFollow.offset = spawnedCameraOffset
                cameraFollow.offset.y = clamp(cameraFollow.offset.y, cameraFollow.minCameraHeight, cameraFollow.maxCameraHeight)

                if ( hasSavedCameraState ) {
                    cameraFollow.yaw = savedCameraYaw
                    cameraFollow.targetYaw = savedCameraYaw
                }
            }
        }

        self->assignCameraToPlayer(newPlayer, newCamera)

        if ( shouldPreserveHealth && savedPlayerHealth >= 0.0 ) {
            get_component(newPlayer) $(var damageable : SDamageable?) {
                if ( damageable != null ) {
                    damageable.maxHealth = savedPlayerMaxHealth

                    if ( savedPlayerHealth > savedPlayerMaxHealth ) {
                        damageable.health = savedPlayerMaxHealth
                    } else {
                        damageable.health = savedPlayerHealth
                    }
                }
            }
        }

        let uiNode = create_node(NodeData(name = "GameUI"))
        add_component(uiNode, new SGameUI(playerNode = newPlayer))

        print("Player spawned: {newPlayer.hierarchyName}")
    }

    def assignCameraToPlayer(playerNode : NodeId, cameraRoot : NodeId) : void {
        var cameraComponent : Camera?

        get_component(cameraRoot) $(var cam : Camera?) {
            if ( cam != null ) {
                cameraComponent = cam
            }
        }

        if ( cameraComponent == null ) {
            let children = get_children(cameraRoot)
            for ( child in children ) {
                get_component(child) $(var cam : Camera?) {
                    if ( cam != null ) {
                        cameraComponent = cam
                    }
                }
            }
        }

        if ( cameraComponent != null ) {
            get_component(playerNode) $(var player : SPlayer?) {
                if ( player != null ) {
                    player.camera = cameraComponent
                }
            }
        }
    }
}
