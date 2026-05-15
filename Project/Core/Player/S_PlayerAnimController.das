require engine.core
require engine.math.math_utils
require Project.Core.Player.S_Player
require Project.Mechanics.Combat.S_PlayerCombat
require Project.Mechanics.Abilities.S_AbilityDash

class SPlayerAnimController : Component {
    @export idleAnim : AnimationId

    @export runF : AnimationId
    @export runFL : AnimationId
    @export runL : AnimationId
    @export runBL : AnimationId
    @export runB : AnimationId
    @export runBR : AnimationId
    @export runR : AnimationId
    @export runFR : AnimationId

    @export dashAnim : AnimationId

    @export locomotionSpeed : float = 1.0
    @export dashSpeed : float = 1.2
    @export attackSpeed : float = 1.0

    @export maxRunSpeed : float = 8.0
    @export speedResponse : float = 0.08

    @export attackBlendTime : float = 0.14
    @export comboBlendTime : float = 0.10
    @export postAttackHold : float = 0.08

    @no_export player : SPlayer?
    @no_export combat : SPlayerCombat?
    @no_export dash : SAbilityDash?
    @no_export animator : Animator?
    @no_export snapshotPlayer : SingleAnimationPlayer?

    @no_export currentAnim : AnimationId
    @no_export previousAnim : AnimationId
    @no_export currentProgress : float = 0.0
    @no_export previousProgress : float = 0.0
    @no_export blendLeft : float = 0.0
    @no_export stateBlendDuration : float = 0.0

    @no_export locomotionRunAnim : AnimationId
    @no_export locomotionProgress : float = 0.0
    @no_export speed01Smoothed : float = 0.0

    @no_export attackState : int = 0
    @no_export attackStage : int = -1
    @no_export attackHoldLeft : float = 0.0

    def override on_initialize() : void {
        player = get_component(nodeId, type<SPlayer>)
        combat = get_component(nodeId, type<SPlayerCombat>)
        dash = get_component(nodeId, type<SAbilityDash>)
        animator = require_component(nodeId, type<Animator>)
        snapshotPlayer = get_component(nodeId, type<SingleAnimationPlayer>)

        if (snapshotPlayer != null) {
            snapshotPlayer.enabled = false
        }

        currentAnim = idleAnim
        previousAnim = idleAnim
        currentProgress = 0.0
        previousProgress = 0.0
        blendLeft = 0.0
        stateBlendDuration = 0.0

        locomotionRunAnim = runF
        locomotionProgress = 0.0
        speed01Smoothed = 0.0

        attackState = 0
        attackStage = -1
        attackHoldLeft = 0.0
    }

    def override on_update() : void {
        if (animator == null) {
            return
        }

        let dt = get_delta_time()

        if (currentAnim == AnimationId()) {
            currentAnim = idleAnim
            previousAnim = idleAnim
        }

        if (combat != null && combat.is_attacking()) {
            let stage = combat.current_attack_stage()
            var attackAnim = combat.attackAnim1
            if (stage == 1) {
                attackAnim = combat.attackAnim2
            } elif (stage >= 2) {
                attackAnim = combat.attackAnim3
            }

            if (attackState == 0) {
                begin_attack(attackAnim, stage, attackBlendTime)
            } elif (stage != attackStage || attackAnim != currentAnim) {
                begin_attack(attackAnim, stage, comboBlendTime)
            }

            attackState = 1
            attackStage = stage
            attackHoldLeft = postAttackHold

            update_attack_playback(attackAnim, dt)
            sample_state_pose()
            sync_single_animation_snapshot(currentAnim, currentProgress)
            return
        }

        if (attackState == 1) {
            attackState = 2
            attackHoldLeft = postAttackHold
        }

        if (attackState == 2) {
            currentProgress = advance_progress_clamped(currentAnim, currentProgress, attackSpeed, dt)

            if (attackHoldLeft > 0.0) {
                attackHoldLeft -= dt
            }

            sample_state_pose()
            sync_single_animation_snapshot(currentAnim, currentProgress)

            if (attackHoldLeft <= 0.0 && currentProgress >= 0.999) {
                begin_return_to_locomotion()
                attackState = 3
            }

            return
        }

        if (attackState == 3) {
            let vel = get_physical_velocity2()
            let speed01 = clamp(length(vel) / max(self->get_current_max_run_speed(), 0.0001), 0.0, 1.0)
            speed01Smoothed = approach(speed01Smoothed, speed01, dt, speedResponse)

            let targetRun = pick_run_anim_8dir(vel)
            if (targetRun != locomotionRunAnim) {
                locomotionRunAnim = targetRun
            }

            locomotionProgress = advance_progress(
                locomotionRunAnim,
                locomotionProgress,
                locomotionSpeed * max(speed01Smoothed, 0.2),
                dt
            )

            if (blendLeft > 0.0) {
                previousProgress = advance_progress(previousAnim, previousProgress, locomotionSpeed, dt)
                blendLeft -= dt
            }

            sample_state_pose()
            sync_single_animation_snapshot(locomotionRunAnim, locomotionProgress)

            if (blendLeft <= 0.0) {
                attackState = 0
                previousAnim = idleAnim
                previousProgress = 0.0
            }

            return
        }

        let vel = get_physical_velocity2()
        let speed01 = clamp(length(vel) / max(self->get_current_max_run_speed(), 0.0001), 0.0, 1.0)
        speed01Smoothed = approach(speed01Smoothed, speed01, dt, speedResponse)

        let targetRun = pick_run_anim_8dir(vel)
        if (targetRun != locomotionRunAnim) {
            locomotionRunAnim = targetRun
        }

        locomotionProgress = advance_progress(
            locomotionRunAnim,
            locomotionProgress,
            locomotionSpeed * max(speed01Smoothed, 0.2),
            dt
        )

        sample_locomotion_pose()

        let snapshotAnim = (speed01Smoothed > 0.5 ? locomotionRunAnim : idleAnim)
        sync_single_animation_snapshot(snapshotAnim, locomotionProgress)
    }

    def private begin_attack(targetAnim : AnimationId; stage : int; blendTime : float) : void {
        previousAnim = locomotionRunAnim
        previousProgress = locomotionProgress
        currentAnim = targetAnim
        currentProgress = 0.0
        stateBlendDuration = blendTime
        blendLeft = blendTime
        attackStage = stage
    }

    def private begin_return_to_locomotion() : void {
        previousAnim = currentAnim
        previousProgress = currentProgress
        currentAnim = locomotionRunAnim
        currentProgress = locomotionProgress
        stateBlendDuration = attackBlendTime
        blendLeft = attackBlendTime
    }

    def private get_current_max_run_speed() : float {
        var result = maxRunSpeed

        if (player != null) {
            result = player.MOVE_SPEED
        }

        return result
    }

    def private update_attack_playback(targetAnim : AnimationId; dt : float) : void {
        var synced = false

        if (combat != null) {
            let stage = combat.current_attack_stage()
            var atkDur : float = 0.0

            if (stage == 0) {
                atkDur = combat.attackDuration1
            } elif (stage == 1) {
                atkDur = combat.attackDuration2
            } else {
                atkDur = combat.attackDuration3
            }

            if (atkDur > 0.0001) {
                currentProgress = clamp(1.0 - (combat.attackTimeLeft / max(atkDur, 0.0001)), 0.0, 1.0)
                synced = true
            }
        }

        if (!synced) {
            currentProgress = advance_progress_clamped(currentAnim, currentProgress, attackSpeed, dt)
        }

        if (blendLeft > 0.0) {
            previousProgress = advance_progress(previousAnim, previousProgress, locomotionSpeed, dt)
            blendLeft -= dt
        }
    }

    def private advance_progress(anim : AnimationId; progress : float; speed : float; dt : float) : float {
        if (anim == AnimationId()) {
            return progress
        }

        var next = progress
        var updated = false

        get_animation_duration(anim) $(duration : float) {
            if (duration > 0.0001) {
                next += dt * speed / duration
                updated = true
            }
        }

        if (!updated) {
            next += dt * speed
        }

        next -= float(int(next))
        return next
    }

    def private advance_progress_clamped(anim : AnimationId; progress : float; speed : float; dt : float) : float {
        if (anim == AnimationId()) {
            return progress
        }

        var next = progress
        var updated = false

        get_animation_duration(anim) $(duration : float) {
            if (duration > 0.0001) {
                next += dt * speed / duration
                updated = true
            }
        }

        if (!updated) {
            next += dt * speed
        }

        if (next < 0.0) {
            next = 0.0
        }

        if (next > 1.0) {
            next = 1.0
        }

        return next
    }

    def private sample_state_pose() : void {
        let targetNode = resolve_anim_target_node(nodeId)
        if (!targetNode.isAlive) {
            return
        }

        if (blendLeft > 0.0 && previousAnim != AnimationId()) {
            let alpha = clamp(1.0 - blendLeft / max(stateBlendDuration, 0.0001), 0.0, 1.0)
            let animations <- [previousAnim, currentAnim]
            let ratios <- [previousProgress, currentProgress]
            let weights <- [1.0 - alpha, alpha]
            sample_animation_and_blend(targetNode, animations, ratios, weights)
        } else {
            let animations <- [currentAnim]
            let ratios <- [currentProgress]
            let weights <- [1.0]
            sample_animation_and_blend(targetNode, animations, ratios, weights)
        }
    }

    def private sample_locomotion_pose() : void {
        let targetNode = resolve_anim_target_node(nodeId)
        if (!targetNode.isAlive) {
            return
        }

        let idleW = clamp(1.0 - speed01Smoothed, 0.0, 1.0)
        let runW = clamp(speed01Smoothed, 0.0, 1.0)

        let animations <- [idleAnim, locomotionRunAnim]
        let ratios <- [locomotionProgress, locomotionProgress]
        let weights <- [idleW, runW]
        sample_animation_and_blend(targetNode, animations, ratios, weights)
    }

    def private sync_single_animation_snapshot(anim : AnimationId; progress : float) : void {
        if (snapshotPlayer == null || anim == AnimationId()) {
            return
        }

        snapshotPlayer.animation = anim
        snapshotPlayer.progress = clamp(progress, 0.0, 1.0)
        snapshotPlayer.speed = 1.0

        if (dash != null) {
            dash.update_ghost_anim_snapshot(anim, snapshotPlayer.progress, snapshotPlayer.speed)
        }
    }

    def private get_physical_velocity2() : float2 {
        if (player == null) {
            return float2(0)
        }

        if (player.character_controller != null) {
            let v = player.character_controller.velocity
            return float2(v.x, v.z)
        }

        return float2(player.move_direction.x, player.move_direction.z)
    }

    def private pick_run_anim_8dir(worldMove : float2) : AnimationId {
        if (length(worldMove) < 0.0001) {
            return locomotionRunAnim
        }

        let worldMove3 = float3(worldMove.x, 0.0, worldMove.y)
        let localMove3 = inverse(nodeId.localRotation) * worldMove3
        var localMove = float2(localMove3.x, localMove3.z)

        if (length(localMove) < 0.0001) {
            return locomotionRunAnim
        }

        localMove = normalize(localMove)

        let angle = atan2(localMove.x, localMove.y)

        if (angle >= -0.392699 && angle < 0.392699) {
            return runF
        } elif (angle >= 0.392699 && angle < 1.178097) {
            return runFR
        } elif (angle >= 1.178097 && angle < 1.963495) {
            return runR
        } elif (angle >= 1.963495 && angle < 2.748894) {
            return runBR
        } elif (angle >= 2.748894 || angle < -2.748894) {
            return runB
        } elif (angle >= -2.748894 && angle < -1.963495) {
            return runBL
        } elif (angle >= -1.963495 && angle < -1.178097) {
            return runL
        }

        return runFL
    }

    def private resolve_anim_target_node(root : NodeId) : NodeId {
        let hasAnim = get_component(root, type<Animator>)
        if (hasAnim != null) {
            return root
        }

        var inscope children = root.get_children()
        for (child in children) {
            let found = resolve_anim_target_node(child)
            if (found.isAlive) {
                return found
            }
        }

        return NodeId()
    }

    def override on_destroy() : void {
        pass
    }
}
