require engine.core

class SEnemySpawner : Component {
    @export enemyPrefabPath : string = "sdsada"
    @export maxEnemies : int = 5
    
    currentEnemyCount : int = 0

    def spawn_enemy(arenaLevel : int) : NodeId {
        if (currentEnemyCount >= maxEnemies) {
            return NodeId()
        }
        
        let prefab = request_prefab(enemyPrefabPath)
        if (prefab == PrefabId()) {
            print("Failed to load enemy prefab: {enemyPrefabPath}")
            return NodeId()
        }
        
        let enemy = instantiate_prefab(prefab, NodeData(
            parent = nodeId,
            position = nodeId.worldPosition
        ))
        
        if (enemy.isAlive) {
            currentEnemyCount += 1
            print("Enemy spawned. Count: {currentEnemyCount}")
        }
        
        return enemy
    }

    def enemy_died() : void {
        currentEnemyCount -= 1
        if (currentEnemyCount < 0) {
            currentEnemyCount = 0
        }
        print("Enemy died. Count: {currentEnemyCount}")
    }

    def override on_destroy() : void {
        pass
    }
}