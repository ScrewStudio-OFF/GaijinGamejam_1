require engine.core
require Project.Mechanics.Enemy.S_EnemyLoot
require Project.Mechanics.Enemy.S_EnemySpawner
require Project.Mechanics.StatsAndProgression.S_GameState
require Project.Assets.Lvl_Angar.S_AngarInstancePrefabs
require Project.Assets.Lvl_Laboratory.S_LaboratoryInstancePrefabs

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
    @no_export runtimeLevelComponentsReady : bool = false

    def override on_initialize() : void {
        runtimeLevelComponentsReady = false
        self->ensure_runtime_level_components()

        if (length(waveConfigs) == 0) {
            setup_default_waves()
        }

        progress_set_arena_level(arenaLevel)
        progress_set_arena_cleared(false)
        
        // Auto-discover enemy spawners in the scene if none assigned in the editor
        if (length(spawnerNodes) == 0) {
            var comps := find_components(type<SEnemySpawner>)
            for (c in comps) {
                if (c != null) {
                    push(spawnerNodes, c.nodeId)
                }
            }
            print("Auto-discovered {length(spawnerNodes)} spawner nodes")
        }

        spawn_next_wave()
    }

    def setup_default_waves() : void {
        let enemyPath = "Project/Mechanics/Enemy/Prefabs/P_Enemy.prefab"
        push(waveConfigs, EnemyWaveConfig(enemyCount = 1, enemyPrefabPath = enemyPath, timeBetweenSpawns = 4.))
        push(waveConfigs, EnemyWaveConfig(enemyCount = 2, enemyPrefabPath = enemyPath, timeBetweenSpawns = 3.))
        push(waveConfigs, EnemyWaveConfig(enemyCount = 3, enemyPrefabPath = enemyPath, timeBetweenSpawns = 2.))
    }

    def override on_update() : void {
        if (!runtimeLevelComponentsReady) {
            self->ensure_runtime_level_components()
        }

        if (isSpawningWave) {
            update_wave_spawning()
        }
        
        check_all_enemies_dead()
    }

    def private ensure_runtime_level_components() : void {
        let angarBase = self->find_child_by_name_recursive(nodeId, "AngarBase")
        let labBase = self->find_child_by_name_recursive(nodeId, "Labbase")

        if (angarBase == NodeId() && labBase == NodeId()) {
            runtimeLevelComponentsReady = true
            return
        }

        if (angarBase != NodeId()) {
            var hasAngarInstancer = false
            get_component(nodeId) $(var instancer : SAngarInstancePrefabs?) {
                if (instancer != null) {
                    hasAngarInstancer = true
                }
            }

            if (!hasAngarInstancer) {
                add_component(nodeId, new SAngarInstancePrefabs(
                    prefabFolder = "Project/Assets/Lvl_Angar",
                    playerName = "P_Player",
                    markerRootNodeName = "AngarBase",
                    markerSuffix = "_EMPTY",
                    numberedMarkerSeparator = ".",
                    spawnedNodePrefix = "AngarSpawned_",
                    spawnWhenPlayerAppears = true,
                    useNumberedNodesAsMarkers = true,
                    useExactPrefabNamesAsMarkers = true,
                    scanOnlyMarkerRoot = true,
                    cleanupPreviousSpawnedNodes = true,
                    removeMarkersAfterSpawn = true,
                    spawnScaleMultiplier = 0.1,
                    fixExistingSpawnedScales = true
                ))

                print("Angar instancer attached by SLevelManager")
            }
        }

        if (labBase != NodeId()) {
            var hasLaboratoryInstancer = false
            get_component(nodeId) $(var instancer : SLaboratoryInstancePrefabs?) {
                if (instancer != null) {
                    hasLaboratoryInstancer = true
                }
            }

            if (!hasLaboratoryInstancer) {
                add_component(nodeId, new SLaboratoryInstancePrefabs(
                    prefabFolder = "Project/Assets/Lvl_Laboratory",
                    prefabExtension = ".prefab",
                    playerName = "P_Player",
                    markerRootNodeName = "Labbase",
                    markerSuffix = "_EMPTY",
                    numberedMarkerSeparator = ".",
                    spawnedNodePrefix = "LabSpawned_",
                    spawnWhenPlayerAppears = true,
                    useNumberedNodesAsMarkers = true,
                    useExactPrefabNamesAsMarkers = true,
                    scanOnlyMarkerRoot = true,
                    cleanupPreviousSpawnedNodes = true,
                    removeMarkersAfterSpawn = true,
                    spawnScaleMultiplier = 1.0
                ))

                print("Laboratory instancer attached by SLevelManager")
            }
        }

        runtimeLevelComponentsReady = true
    }

    def private find_child_by_name_recursive(n : NodeId, targetName : string) : NodeId {
        if (n == NodeId() || !n.isAlive) {
            return NodeId()
        }

        if (n.name == targetName) {
            return n
        }

        let children = get_children(n)
        for (child in children) {
            let found = self->find_child_by_name_recursive(child, targetName)
            if (found != NodeId()) {
                return found
            }
        }

        return NodeId()
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
        print("Requesting enemy prefab: {prefabPath}")
        let prefab = request_prefab(prefabPath)
        if (prefab == PrefabId()) {
            print("Failed to load enemy prefab: {prefabPath}")
            return NodeId()
        }
        // Ensure we have spawner nodes available
        if (length(spawnerNodes) == 0) {
            var comps := find_components(type<SEnemySpawner>)
            for (c in comps) {
                if (c != null) {
                     push(spawnerNodes, c.nodeId) 
                     }
            }
        }

        // fallback to children of this manager node
        if (length(spawnerNodes) == 0) {
            var fallback := nodeId.get_children()
            if (length(fallback) > 0) {
                spawnerNodes <- fallback
            }
        }

        if (length(spawnerNodes) == 0) {
            print("No spawner nodes available, cannot spawn enemy")
            return NodeId()
        }

        let spawnerIdx = enemiesSpawnedThisWave % length(spawnerNodes)
        let spawnerNode = spawnerNodes[spawnerIdx]

        if (!spawnerNode.isAlive) {
            print("Selected spawner node is not alive, aborting spawn")
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
        var spawners := spawnerNodes

        // fallback: if spawnerNodes is empty, try to use children of this node
        if (length(spawners) == 0) {
            spawners <- nodeId.get_children()
        }

        for (spawner in spawners) {
            if (spawner == NodeId()) {
                 continue 
            }
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
        
        // update saved progression wave index
        progress_advance_wave()

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
