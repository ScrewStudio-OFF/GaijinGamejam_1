require engine.core
require Project.Mechanics.Enemy.S_EnemyLoot
require Project.Mechanics.StatsAndProgression.S_GameState

struct EnemyWaveConfig {
    enemyCount : int = 1
    enemyPrefabPath : string = ""
    timeBetweenSpawns : float = 0.5
}

class SLevelManager : Component {
    @export arenaLevel : int = 1
    @export spawnerNodes : array<NodeId>
    @export waveConfigs : array<EnemyWaveConfig>
    @export timeBetweenWaves : float = 3.0
    
    currentWave : int = 0
    waveTimer : float = 0.0
    isSpawningWave : bool = false
    spawnTimer : float = 0.0
    enemiesSpawnedThisWave : int = 0

    def override on_initialize() : void {
        if (length(waveConfigs) == 0) {
            setup_default_waves()
        }

        progress_set_arena_level(arenaLevel)
        progress_set_arena_cleared(false)
        
        spawn_next_wave()
    }

    def setup_default_waves() : void {
        push(waveConfigs, EnemyWaveConfig(enemyCount = 3, enemyPrefabPath = "Prefab resource not found: Project/Assets/Test/Enemy.prefab", timeBetweenSpawns = 0.5))
        push(waveConfigs, EnemyWaveConfig(enemyCount = 5, enemyPrefabPath = "Prefab resource not found: Project/Assets/Test/Enemy.prefab", timeBetweenSpawns = 0.4))
        push(waveConfigs, EnemyWaveConfig(enemyCount = 7, enemyPrefabPath = "Prefab resource not found: Project/Assets/Test/Enemy.prefab", timeBetweenSpawns = 0.3))
    }

    def override on_update() : void {
        if (isSpawningWave) {
            update_wave_spawning()
        }
        
        check_all_enemies_dead()
    }

    def spawn_next_wave() : void {
        if (currentWave >= length(waveConfigs)) {
            on_all_waves_completed()
            return
        }
        
        isSpawningWave = true
        spawnTimer = 0.0
        enemiesSpawnedThisWave = 0
        
        print("Wave {currentWave + 1} started on arena level {arenaLevel}")
    }

    def private update_wave_spawning() : void {
        let config = waveConfigs[currentWave]
        
        spawnTimer -= get_delta_time()
        
        if (spawnTimer <= 0.0 && enemiesSpawnedThisWave < config.enemyCount) {
            spawn_enemy(config.enemyPrefabPath)
            enemiesSpawnedThisWave += 1
            spawnTimer = config.timeBetweenSpawns
        }
        
        if (enemiesSpawnedThisWave >= config.enemyCount) {
            isSpawningWave = false
        }
    }

    def private spawn_enemy(prefabPath : string) : NodeId {
        let prefab = request_prefab(prefabPath)
        if (prefab == PrefabId()) {
            print("Failed to load enemy prefab: {prefabPath}")
            return NodeId()
        }
        
        let spawnerIdx = enemiesSpawnedThisWave % length(spawnerNodes)
        let spawnerNode = spawnerNodes[spawnerIdx]
        
        if (!spawnerNode.isAlive) {
            return NodeId()
        }
        
        let enemy = instantiate_prefab(prefab, NodeData(
            parent = spawnerNode,
            position = spawnerNode.worldPosition
        ))
        
        var loot = get_component(enemy, type<SEnemyLoot>)
        if (loot != null) {
            loot.set_arena_level(arenaLevel)
        }
        
        return enemy
    }

    def private check_all_enemies_dead() : void {
        if (isSpawningWave) {
            return
        }
        
        var hasEnemies = false
        var spawners = nodeId.get_children()
        
        for (spawner in spawners) {
            var children = spawner.get_children()
            if (length(children) > 0) {
                hasEnemies = true
                break
            }
        }
        
        if (!hasEnemies) {
            on_wave_completed()
        }
    }

    def private on_wave_completed() : void {
        currentWave += 1
        waveTimer = timeBetweenWaves
        
        print("Wave completed! Next wave in {timeBetweenWaves}s")
        
        if (currentWave >= length(waveConfigs)) {
            on_all_waves_completed()
        } else {
            spawn_next_wave()
        }
    }

    def private on_all_waves_completed() : void {
        print("All waves completed on arena level {arenaLevel}!")
        print("Level complete!")

        progress_set_arena_cleared(true)
    }

    def get_coins_for_kill() : int {
        let x = int(round(float(arenaLevel + 1) / 2.0))
        return x
    }

    def override on_destroy() : void {
        pass
    }
}