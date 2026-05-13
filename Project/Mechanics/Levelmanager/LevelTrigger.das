require engine.core

class LevelTrigger : Component {

    playerNode : NodeId
    triggerNode : NodeId

    playerName : string = "Player"

    targetLevelPath : string = "Project/Levels/Lvl_Morgue.prefab"

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

        if ( self.triggerNode == NodeId() ) {
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

        if ( self.playerNode == NodeId() ) {
            self->findPlayer()
            return
        }

        if ( self.triggerNode == NodeId() ) {
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

    def findPlayerRecursive(n : NodeId) : NodeId {
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

        if ( levelPrefab == PrefabId() ) {
            print("WARNING: target level prefab not found: {self.targetLevelPath}")
            self.triggered = false
            return
        }

        clear_scene()

        instantiate_prefab(levelPrefab, NodeData(
            name = "Lvl_Morgue"
        ))
    }
}