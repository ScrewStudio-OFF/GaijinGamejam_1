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

        // Не учитывать хитбокс самого владельца или его детей:
        if (is_descendant_of(target, owner) || target == nodeId) {
            return
        }

        if (is_already_hit(target)) {
            return
        }

        push(alreadyHit, target)

        if (debugPrintHits) {
            print("overlap hit {target.name} (nodeId={target})")
        }

        // Защитно выберем позицию владельца: если owner не активен, используем позицию самого хитбокса
        var ownerPos = owner
        if (!ownerPos.isAlive) {
            ownerPos = nodeId
        }

        // Найдём ближайший родительский узел, который содержит SDamageable (включая сам target)
        var damaged = false
        var probe = target
        while (probe.isAlive) {
            get_component(probe) $(var damageable : SDamageable?) {
                if (damageable != null) {
                    // вычисляем направление от владельца к центру поражённого (используем ownerPos.worldPosition)
                    var dir = probe.worldPosition - ownerPos.worldPosition
                    dir.y = 0.0
                    if (length(dir) < 0.001) {
                        dir = FORWARD
                    } else {
                        dir = normalize(dir)
                    }
                    dir.y = 0.25
                    dir = normalize(dir)

                    damageable.take_damage(damage, owner, knockbackForce)
                    damaged = true

                    if (debugPrintHits) {
                        print("Damaged {probe.name} from owner {owner.name}")
                    }
                }
            }

            if (damaged) {
                break
            }

            // подняться к родителю
            probe = probe.parent
            if (probe == NodeId()) {
                break
            }
        }

        if (!damaged) {
            // Если не нашли SDamageable — попытка оттолкнуть rigidbody на том же или родительском узле
            var probe2 = target
            var applied = false
            while (probe2.isAlive) {
                get_component(probe2) $(var rb : RigidBody?) {
                    if (rb != null) {
                        var dir2 = probe2.worldPosition - ownerPos.worldPosition
                        dir2.y = 0.0
                        if (length(dir2) < 0.001) {
                            dir2 = FORWARD
                        } else {
                            dir2 = normalize(dir2)
                        }
                        dir2.y = 0.25
                        dir2 = normalize(dir2)
                        apply_rigid_body_impulse(rb, dir2 * knockbackForce)
                        applied = true
                        if (debugPrintHits) {
                            print("Applied impulse to {probe2.name}")
                        }
                    }
                }

                if (applied) {
                    break
                }

                probe2 = probe2.parent
                if (probe2 == NodeId()) {
                    break
                }
            }
        }
    }

    def private is_descendant_of(nodeA : NodeId; nodeB : NodeId) : bool {
        if (!nodeA.isAlive || !nodeB.isAlive) {
            return false
        }

        var p = nodeA
        while (p.isAlive) {
            if (p == nodeB) {
                return true
            }
            p = p.parent
            if (p == NodeId()) {
                break
            }
        }

        return false
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