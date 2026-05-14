require engine.core
require Project.Mechanics.StatsAndProgression.S_PlayerStats

class SEnemyLoot : Component {
    arenaLevel : int = 1

    def set_arena_level(level : int) : void {
        arenaLevel = level
    }

    def on_enemy_died(playerNode : NodeId) : void {
        let coinsEarned = calculate_coins()
        
        get_component(playerNode) $(var stats : SPlayerStats?) {
            if (stats != null) {
                stats.add_coins(coinsEarned)
                print("Player earned {coinsEarned} coins!")
            }
        }
    }

    def private calculate_coins() : int {
        let x = int(round(float(arenaLevel + 1) / 2.0))
        return x
    }

    def override on_destroy() : void {
        pass
    }
}