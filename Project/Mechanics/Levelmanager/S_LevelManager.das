require engine.core
require Project.Core.Player.S_Player
require Project.Mechanics.Enemy.S_EnemyLoot
require Project.Mechanics.Enemy.S_EnemySpawner
require Project.Mechanics.StatsAndProgression.S_GameState
require Project.Assets.Lvl_Angar.S_AngarInstancePrefabs
require Project.Assets.Lvl_Greenhouse.S_GreenHouseInstancePrefabs
require Project.Assets.Lvl_Laboratory.S_LaboratoryInstancePrefabs

let DEFAULT_ENEMY_PREFAB_PATH = "Project/Mechanics/Enemy/Prefabs/P_Enemy.prefab"

struct EnemyWaveConfig {
    enemyCount : int = 1
    enemyPrefabPath : string = ""
    timeBetweenSpawns : float = 0.5
}

class SLevelManager : Component {
    @export arenaLevel : int = 1
    @export spawnerNodes : array<NodeId>
    @export spawnPointNodeName : string = "P_EnemySpawnPoint"
    @export waveConfigs : array<EnemyWaveConfig>
    @export timeBetweenWaves : float = 3.0
    @export waitForLevelLoadedBeforeSpawn : bool = true
    @export spawnAfterLevelLoadedDelay : float = 0.5
    
    currentWave : int = 0
    waveTimer : float = 0.0
    isSpawningWave : bool = false
    spawnTimer : float = 0.0
    enemiesSpawnedThisWave : int = 0
    @no_export activeEnemies : array<NodeId>
    @no_export levelCompleted : bool = false
    @no_export runtimeLevelComponentsReady : bool = false
    @no_export wavesStarted : bool = false
    @no_export spawnReadyTimer : float = 0.0

    def override on_initialize() : void {
        runtimeLevelComponentsReady = false
        isSpawningWave = false
        levelCompleted = false
        wavesStarted = false
        spawnReadyTimer = 0.0
        currentWave = 0
        enemiesSpawnedThisWave = 0
        resize(activeEnemies, 0)
        self->ensure_runtime_level_components()

        if (length(waveConfigs) == 0) {
            setup_default_waves()
        }
        self->normalize_wave_configs()

        let savedArenaLevel = progress_get_current_arena_level()
        if (savedArenaLevel > arenaLevel) {
            arenaLevel = savedArenaLevel
        }

        progress_set_arena_level(arenaLevel)
        progress_set_arena_cleared(false)
        
        self->discover_spawn_points()

        if (!waitForLevelLoadedBeforeSpawn) {
            wavesStarted = true
            spawn_next_wave()
        }
    }

    def setup_default_waves() : void {
        push(waveConfigs, EnemyWaveConfig(enemyCount = 1, enemyPrefabPath = DEFAULT_ENEMY_PREFAB_PATH, timeBetweenSpawns = 4.))
        push(waveConfigs, EnemyWaveConfig(enemyCount = 2, enemyPrefabPath = DEFAULT_ENEMY_PREFAB_PATH, timeBetweenSpawns = 3.))
        push(waveConfigs, EnemyWaveConfig(enemyCount = 3, enemyPrefabPath = DEFAULT_ENEMY_PREFAB_PATH, timeBetweenSpawns = 2.))
    }

    def normalize_wave_configs() : void {
        for (waveIndex in range(length(waveConfigs))) {
            if (waveConfigs[waveIndex].enemyCount <= 0) {
                waveConfigs[waveIndex].enemyCount = waveIndex + 1
            }

            if (length(waveConfigs[waveIndex].enemyPrefabPath) == 0) {
                waveConfigs[waveIndex].enemyPrefabPath = DEFAULT_ENEMY_PREFAB_PATH
            }
        }
    }

    def override on_update() : void {
        if (!runtimeLevelComponentsReady) {
            self->ensure_runtime_level_components()
        }

        if (!wavesStarted) {
            self->update_waiting_for_level_loaded()
            return
        }

        if (isSpawningWave) {
            update_wave_spawning()
        }
        
        check_all_enemies_dead()
    }

    def private update_waiting_for_level_loaded() : void {
        if (!self->is_level_ready_for_enemy_spawn()) {
            spawnReadyTimer = 0.0
            return
        }

        spawnReadyTimer += get_delta_time()
        if (spawnReadyTimer < spawnAfterLevelLoadedDelay) {
            return
        }

        wavesStarted = true
        print("Level loaded, starting enemy waves")
        spawn_next_wave()
    }

    def private is_level_ready_for_enemy_spawn() : bool {
        if (find_component(type<SPlayer>) == null) {
            return false
        }

        var ready = true

        var angarInstancers := find_components(type<SAngarInstancePrefabs>)
        for (instancer in angarInstancers) {
            if (instancer != null && !instancer.spawned) {
                ready = false
            }
        }

        var greenhouseInstancers := find_components(type<SGreenHouseInstancePrefabs>)
        for (instancer in greenhouseInstancers) {
            if (instancer != null && !instancer.spawned) {
                ready = false
            }
        }

        var laboratoryInstancers := find_components(type<SLaboratoryInstancePrefabs>)
        for (instancer in laboratoryInstancers) {
            if (instancer != null && !instancer.spawned) {
                ready = false
            }
        }

        return ready
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
        if (levelCompleted || currentWave >= length(waveConfigs)) {
            on_all_waves_completed()
            return
        }

        let config = waveConfigs[currentWave]
        resize(activeEnemies, 0)
        self->discover_spawn_points()

        enemiesSpawnedThisWave = 0
        isSpawningWave = true

        print("Wave {currentWave + 1} started on arena level {arenaLevel}, spawning {config.enemyCount} enemies")

        for (i in range(config.enemyCount)) {
            let enemy = self->spawn_enemy(config.enemyPrefabPath)
            if (enemy != NodeId() && enemy.isAlive) {
                push(activeEnemies, enemy)
                enemiesSpawnedThisWave += 1
            }
        }

        isSpawningWave = false
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

        let spawnerNode = self->get_random_spawn_point()
        if (spawnerNode == NodeId() || !spawnerNode.isAlive) {
            print("No alive spawn point available, cannot spawn enemy")
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
        if (levelCompleted) {
            return
        }

        if (isSpawningWave) {
            return
        }
        
        var hasEnemies = false

        for (enemy in activeEnemies) {
            if (enemy != NodeId() && enemy.isAlive) {
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
        if (levelCompleted) {
            return
        }

        levelCompleted = true
        print("All waves completed on arena level {arenaLevel}!")
        print("Level complete!")

        progress_set_arena_cleared(true)
    }

    def private discover_spawn_points() : void {
        if (length(spawnerNodes) > 0) {
            return
        }

        let roots = get_scene_roots()
        for (root in roots) {
            self->collect_spawn_points_recursive(root)
        }

        if (length(spawnerNodes) == 0) {
            var comps := find_components(type<SEnemySpawner>)
            for (c in comps) {
                if (c != null) {
                    push(spawnerNodes, c.nodeId)
                }
            }
        }

        if (length(spawnerNodes) == 0 && wavesStarted) {
            push(spawnerNodes, nodeId)
            print("No {spawnPointNodeName} nodes found, using level manager position as fallback")
        } else {
            print("Enemy spawn points found: {length(spawnerNodes)}")
        }
    }

    def private collect_spawn_points_recursive(n : NodeId) : void {
        if (n == NodeId() || !n.isAlive) {
            return
        }

        if (n.name == spawnPointNodeName || find(n.name, "EnemySpawnPoint") >= 0) {
            push(spawnerNodes, n)
        }

        let children = get_children(n)
        for (child in children) {
            self->collect_spawn_points_recursive(child)
        }
    }

    def private get_random_spawn_point() : NodeId {
        var result = NodeId()

        if (length(spawnerNodes) == 0) {
            self->discover_spawn_points()
        }

        if (length(spawnerNodes) > 0) {
            for (attempt in range(length(spawnerNodes))) {
                let spawnIndex = random_range(0, length(spawnerNodes))
                let candidate = spawnerNodes[spawnIndex]
                if (candidate != NodeId() && candidate.isAlive) {
                    result = candidate
                    break
                }
            }
        }

        return result
    }

    def get_coins_for_kill() : int {
        let x = int(round(float(arenaLevel + 1) / 2.0))
        return x
    }

    def override on_destroy() : void {
        pass
    }
}
