require engine.core
require engine.math.math_utils
require Project.Core.Player.S_Player
require Project.Mechanics.Enemy.S_EnemyLoot
require Project.Mechanics.Enemy.S_EnemySpawner
require Project.Mechanics.UIUX.S_DeathScreen

class SDamageable : Component {
    @export maxHealth : float = 100.0
    @export health : float = 100.0
    @export applyKnockback : bool = true
    @export knockbackUp : float = 0.20
    @export destroyOnDeath : bool = true
    @export playerDeathImagePath : string = "Project/Assets/UI/Refined.png"
    @export playerDeathMenuPath : string = "Project/Levels/Lvl_Main.prefab"
    @export playerDeathDelay : float = 5.0

    dead : bool = false

    def override on_initialize() : void {
        dead = false

        if (health <= 0.0) {
            health = maxHealth
        }

        if (health > maxHealth) {
            health = maxHealth
        }
    }

    def take_damage(amount : float; source : NodeId; knockbackForce : float = 0.0) : void {
        if (amount <= 0.0 || !nodeId.isAlive || dead) {
            return
        }
        print("Damaged")

        health -= amount
        apply_knockback(source, knockbackForce)

        if (health <= 0.0) {
            die(source)
        }
    }

    def private apply_knockback(source : NodeId; force : float) : void {
        if (!applyKnockback || force <= 0.0) {
            return
        }

        var dir = nodeId.localPosition - source.localPosition
        dir.y = 0.0

        if (length(dir) < 0.001) {
            dir = FORWARD
        } else {
            dir = normalize(dir)
        }

        dir.y = knockbackUp
        dir = normalize(dir)

        get_component(nodeId) $(var rb : RigidBody?) {
            if (rb != null) {
                rb.velocity = rb.velocity + dir * force
            }
        }
    }

    def private die(source : NodeId) : void {
        if (dead) {
            return
        }

        dead = true
        health = 0.0

        var isPlayer = false
        get_component(nodeId) $(var player : SPlayer?) {
            if (player != null) {
                isPlayer = true
            }
        }

        if (isPlayer) {
            show_player_death_screen(playerDeathImagePath, playerDeathMenuPath, playerDeathDelay)
            return
        }

        get_component(nodeId) $(var loot : SEnemyLoot?) {
            if (loot != null) {
                loot.on_enemy_died(source)
            }
        }

        if (nodeId.parent != NodeId()) {
            get_component(nodeId.parent) $(var spawner : SEnemySpawner?) {
                if (spawner != null) {
                    spawner.enemy_died()
                }
            }
        }

        if (destroyOnDeath) {
            remove_node(nodeId)
        }
    }

    def override on_destroy() : void {
        pass
    }
}
