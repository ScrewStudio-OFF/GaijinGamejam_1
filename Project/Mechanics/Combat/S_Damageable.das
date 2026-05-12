require engine.core
require engine.math.math_utils

class SDamageable : Component {
    @export maxHealth : float = 100.0
    @export health : float = 100.0
    @export applyKnockback : bool = true
    @export knockbackUp : float = 0.20
    @export destroyOnDeath : bool = true

    def override on_initialize() : void {
        if (health <= 0.0) {
            health = maxHealth
        }

        if (health > maxHealth) {
            health = maxHealth
        }
    }

    def take_damage(amount : float; source : NodeId; knockbackForce : float = 0.0) : void {
        if (amount <= 0.0 || !nodeId.isAlive) {
            return
        }
        print("Damaged")

        health -= amount
        apply_knockback(source, knockbackForce)

        if (health <= 0.0) {
            die()
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

    def private die() : void {
        if (destroyOnDeath) {
            remove_node(nodeId)
        }
    }

    def override on_destroy() : void {
        pass
    }
}