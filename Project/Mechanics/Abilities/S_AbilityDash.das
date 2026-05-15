require engine.core
require engine.math.math_utils
require engine.sound_core
require Project.Mechanics.Abilities.S_AbilityBase
require Project.Mechanics.VFX.S_DashAfterImage

class SAbilityDash : SAbilityBase {
    @export dashSpeed : float = 20.0
    @export dashDuration : float = 0.12
    @export dashCooldown : float = 0.6
    @export dashPriority : int = 10

    @export ghostInterval : float = 0.04
    @export ghostCopiesPerSpawn : int = 2
    @export ghostCopySpacing : float = 0.02
    @export ghostLifeTime : float = 0.16
    @export ghostTintStart : float4 = float4(0.1, 0.9, 1.0, 0.6)
    @export ghostTintEnd : float4 = float4(0.5, 0.15, 1.0, 0.05)
    @export ghostScaleBoost : float = 1.06
    @export freezeGhostAnimation : bool = false
    @export ghostFreezeDelay : float = 0.04
    @export ghostPrefabPath : string = "Project/Mechanics/VFX/Prefabs/P_DashGhost.prefab"

    @export dashSoundPath : string = "Project/Assets/SFX/Abilities/SFX_DashAbility.mp3"
    @export dashSoundVolume : float = 3.0

    cooldownLeft : float = 0.0
    dashTimeLeft : float = 0.0
    dashDir : float3 = float3(0)
    ghostTimer : float = 0.0
    visualRoot : NodeId = NodeId()
    firstGhostSpawned : bool = false
    lastAnimId : AnimationId = AnimationId()
    lastAnimProgress : float = 0.0
    lastAnimSpeed : float = 1.0

    def override on_initialize() : void {
        if (nodeId.name == "DashGhost") {
            return
        }

        cooldownLeft = 0.0
        dashTimeLeft = 0.0
        dashDir = float3(0)
        ghostTimer = 0.0
    }

    def override collect_motion(ctx : AbilityContext) : AbilityMotionRequest {
        var req = AbilityMotionRequest()

        if (nodeId.name == "DashGhost") {
            return req
        }

        if (!isAbilityEnabled) {
            return req
        }

        if (cooldownLeft > 0.0) {
            cooldownLeft -= ctx.dt
            if (cooldownLeft < 0.0) {
                cooldownLeft = 0.0
            }
        }

        if (is_action_just_pressed("dash") && cooldownLeft <= 0.0 && dashTimeLeft <= 0.0) {
            dashDir = ctx.facingForward
            dashDir.y = 0.0

            if (length(dashDir) > 0.001) {
                dashDir = normalize(dashDir)
                dashTimeLeft = dashDuration
                cooldownLeft = dashCooldown
                ghostTimer = 0.0
                firstGhostSpawned = false

                play_dash_sound()
            }
        }

        if (dashTimeLeft > 0.0) {
            dashTimeLeft -= ctx.dt

            // Спавнить первый ghost со небольшой задержкой (чтобы анимация инициализировалась)
            if (!firstGhostSpawned) {
                firstGhostSpawned = true
                ghostTimer = ghostInterval * 0.5
            } else {
                ghostTimer -= ctx.dt
                if (ghostTimer <= 0.0) {
                    ghostTimer = ghostInterval
                    spawn_ghost()
                }
            }

            req.addVelocity = dashDir * dashSpeed
            req.priority = dashPriority
        }
        
        return req
    }

    def private spawn_ghost() : void {
        visualRoot = nodeId

        let ghostPrefab = request_prefab(ghostPrefabPath)
        if (ghostPrefab == PrefabId()) {
            print("Dash WARNING: ghost prefab not found: {ghostPrefabPath}")
            return
        }

        for (copyIndex in range(ghostCopiesPerSpawn)) {
            let copyOffset = dashDir * (ghostCopySpacing * float(copyIndex))

            let ghost = instantiate_prefab(ghostPrefab, NodeData(
                name = "DashGhost",
                position = nodeId.localPosition - copyOffset,
                rotation = nodeId.localRotation,
                scale = nodeId.localScale
            ))

            if (!ghost.isAlive) {
                continue
            }

            ghost.set_parent(nodeId.parent, AddChildStrategy.KeepWorldTransform)

            get_component(ghost) $(var ghostSap : SingleAnimationPlayer?) {
                if (ghostSap != null) {
                    if (lastAnimId != AnimationId()) {
                        ghostSap.animation = lastAnimId
                        ghostSap.progress = clamp(lastAnimProgress, 0.0, 1.0)
                        ghostSap.speed = lastAnimSpeed
                    }
                    // Always enable at spawn so the first sample can be applied before any optional freeze.
                    ghostSap.enabled = true
                }
            }

            let afterImage = add_component(ghost, new SDashAfterImage(
                lifeTime = ghostLifeTime,
                startTint = ghostTintStart,
                endTint = ghostTintEnd,
                scaleBoost = ghostScaleBoost,
                freezeAnimation = freezeGhostAnimation,
                freezeDelay = ghostFreezeDelay,
                source = nodeId
            ))
        }
    }

    def update_ghost_anim_snapshot(anim : AnimationId; progress : float; speed : float = 1.0) : void {
        lastAnimId = anim
        lastAnimProgress = clamp(progress, 0.0, 1.0)
        lastAnimSpeed = max(speed, 0.0)
    }

    def private play_dash_sound() : void {
        let sound = request_sound(dashSoundPath)
        let sid = play_sound(sound)
        set_volume(sid, dashSoundVolume)
    }

    def is_dashing() : bool {
        return dashTimeLeft > 0.0
    }

    def override on_destroy() : void {
        pass
    }
}
