require engine.core
require engine.math.math_utils
require Project.Mechanics.Combat.S_AttackHitbox

class SPlayerCombat : Component {
    @export attackAnim1 : AnimationId
    @export attackAnim2 : AnimationId
    @export attackAnim3 : AnimationId

    @export attackDuration1 : float = 0.38
    @export attackDuration2 : float = 0.42
    @export attackDuration3 : float = 0.48

    @export comboWindowOpen1 : float = 0.16
    @export comboWindowOpen2 : float = 0.18
    @export comboWindowOpen3 : float = 0.20

    @export hitboxDelay1 : float = 0.08
    @export hitboxDelay2 : float = 0.09
    @export hitboxDelay3 : float = 0.10

    @export hitboxLife1 : float = 0.10
    @export hitboxLife2 : float = 0.11
    @export hitboxLife3 : float = 0.12

    @export damage1 : float = 10.0
    @export damage2 : float = 12.0
    @export damage3 : float = 16.0

    @export knockback1 : float = 5.0
    @export knockback2 : float = 6.0
    @export knockback3 : float = 8.0

    @export hitboxPrefabPath : string = "Project/Mechanics/Combat/Prefabs/P_AttackHitbox.prefab"
    @export hitboxOffset : float3 = float3(0.0, 0.9, 1.2)
    @export hitboxScale : float3 = float3(1.0)

    comboStage : int = 0
    attackTimeLeft : float = 0.0
    hitboxSpawnDelayLeft : float = 0.0
    hitboxSpawned : bool = false
    queuedNextAttack : bool = false

    def override on_initialize() : void {
        comboStage = 0
        attackTimeLeft = 0.0
        hitboxSpawnDelayLeft = 0.0
        hitboxSpawned = false
        queuedNextAttack = false

    }

    def override on_update() : void {
        let dt = get_delta_time()

        if (is_action_just_pressed("attack"))
        {
            if (attackTimeLeft <= 0.0) {
                start_attack(0)
            } elif (attackTimeLeft <= combo_window_open(comboStage)) {
                queuedNextAttack = true
            }
        }

        if (attackTimeLeft > 0.0) {
            attackTimeLeft -= dt
            hitboxSpawnDelayLeft -= dt

            if (!hitboxSpawned && hitboxSpawnDelayLeft <= 0.0) {
                spawn_hitbox(comboStage)
                hitboxSpawned = true
            }

            if (attackTimeLeft <= 0.0) {
                if (queuedNextAttack && comboStage < 2) {
                    start_attack(comboStage + 1)
                } else {
                    reset_combo()
                }
            }
        }
    }

    def private start_attack(stage : int) : void {
        comboStage = stage
        queuedNextAttack = false
        hitboxSpawned = false
        attackTimeLeft = attack_duration(stage)
        hitboxSpawnDelayLeft = hitbox_delay(stage)
    }

    def private reset_combo() : void {
        comboStage = 0
        attackTimeLeft = 0.0
        hitboxSpawnDelayLeft = 0.0
        hitboxSpawned = false
        queuedNextAttack = false
    }

    def private spawn_hitbox(stage : int) : void {
        let hitbox_prefab = request_prefab(hitboxPrefabPath)
        let hitbox = instantiate_prefab(hitbox_prefab, NodeData(name = "AttackHitbox"))

        hitbox.set_parent(nodeId, AddChildStrategy.KeepLocalTransform)
        hitbox.localPosition = hitboxOffset
        hitbox.localScale = hitboxScale

        get_component(hitbox) $(var hb : SAttackHitbox?) {
            if (hb != null) {
                hb.owner = nodeId
                hb.damage = attack_damage(stage)
                hb.knockbackForce = attack_knockback(stage)
                hb.set_lifetime(hitbox_life(stage))
            }
        }
    }

    def is_attacking() : bool {
        return attackTimeLeft > 0.0
    }

    def current_attack_stage() : int {
        return comboStage
    }

    def private attack_animation(stage : int) : AnimationId {
        if (stage == 0) {
            return attackAnim1
        } elif (stage == 1) {
            return attackAnim2
        } else {
            return attackAnim3
        }
    }

    def private attack_duration(stage : int) : float {
        if (stage == 0) {
            return attackDuration1
        } elif (stage == 1) {
            return attackDuration2
        } else {
            return attackDuration3
        }
    }

    def private combo_window_open(stage : int) : float {
        if (stage == 0) {
            return comboWindowOpen1
        } elif (stage == 1) {
            return comboWindowOpen2
        } else {
            return comboWindowOpen3
        }
    }

    def private hitbox_delay(stage : int) : float {
        if (stage == 0) {
            return hitboxDelay1
        } elif (stage == 1) {
            return hitboxDelay2
        } else {
            return hitboxDelay3
        }
    }

    def private hitbox_life(stage : int) : float {
        if (stage == 0) {
            return hitboxLife1
        } elif (stage == 1) {
            return hitboxLife2
        } else {
            return hitboxLife3
        }
    }

    def private attack_damage(stage : int) : float {
        if (stage == 0) {
            return damage1
        } elif (stage == 1) {
            return damage2
        } else {
            return damage3
        }
    }

    def private attack_knockback(stage : int) : float {
        if (stage == 0) {
            return knockback1
        } elif (stage == 1) {
            return knockback2
        } else {
            return knockback3
        }
    }

    def override on_destroy() : void {
        pass
    }
}