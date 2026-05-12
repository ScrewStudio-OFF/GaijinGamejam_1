require engine.core
require engine.math.math_utils
require Project.Mechanics.Combat.S_Damageable

class SAttackHitbox : Component {
    @export owner : NodeId = NodeId()
    @export lifeTime : float = 0.25
    @export damage : float = 10.0
    @export knockbackForce : float = 5.0

    @export boxSize : float3 = float3(3.0, 2.0, 4.0)
    @export boxOffset : float3 = float3(0.0, 0.0, 0.0)
    @export debugPrintHits : bool = true

    timeLeft : float = 0.0
    alreadyHit : array<NodeId>

    def override on_initialize() : void {
        timeLeft = lifeTime
        resize(alreadyHit, 0)

        if (debugPrintHits) {
            print("attack hitbox spawned")
        }
    }

    def set_lifetime(value : float) : void {
        lifeTime = value
        timeLeft = value
    }

    def override on_update() : void {
        timeLeft -= get_delta_time()

        if (timeLeft <= 0.0) {
            remove_node(nodeId)
            return
        }

        let scaledSize = float3(
            boxSize.x * nodeId.localScale.x,
            boxSize.y * nodeId.localScale.y,
            boxSize.z * nodeId.localScale.z
        )

        let req = BoxQuery(
            position = nodeId.worldPosition + boxOffset,
            size = scaledSize,
            rotation = quat4(),
            collisionMask = UINT_MAX
        )

        overlap(req) $(hits) {
            for (hit in hits) {
                handle_overlap(hit.nodeId)
            }
        }
    }

    def private handle_overlap(target : NodeId) : void {
        if (!target.isAlive) {
            return
        }

        if (target == owner || target == nodeId) {
            return
        }

        if (is_already_hit(target)) {
            return
        }

        push(alreadyHit, target)

        if (debugPrintHits) {
            print("overlap hit {target.name}")
        }

        var dir = target.worldPosition - owner.worldPosition
        dir.y = 0.0

        if (length(dir) < 0.001) {
            dir = FORWARD
        } else {
            dir = normalize(dir)
        }

        dir.y = 0.25
        dir = normalize(dir)

        var damaged = false
        get_component(target) $(var damageable : SDamageable?) {
            if (damageable != null) {
                damageable.take_damage(damage, owner, knockbackForce)
                damaged = true
            }
        }

        if (!damaged) {
            get_component(target) $(var rb : RigidBody?) {
                if (rb != null) {
                    apply_rigid_body_impulse(rb, dir * knockbackForce)
                }
            }
        }
    }

    def private is_already_hit(target : NodeId) : bool {
        for (hitTarget in alreadyHit) {
            if (hitTarget == target) {
                return true
            }
        }

        return false
    }

    def override on_destroy() : void {
        pass
    }
}