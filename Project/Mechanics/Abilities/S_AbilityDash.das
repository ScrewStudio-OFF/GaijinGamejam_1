require engine.core
require engine.input.global_input_state
require engine.math.math_utils
require engine.sound_core
require Project.Mechanics.Abilities.S_AbilityBase
require Project.Mechanics.VFX.S_DashAfterImage

class SAbilityDash : SAbilityBase {
    @export dashSpeed : float = 20.0
    @export dashDuration : float = 0.12
    @export dashCooldown : float = 0.6
    @export dashPriority : int = 10

    @export ghostPrefabPath : string = "Project/Mechanics/VFX/Prefabs/P_DashGhost.prefab"
    @export ghostInterval : float = 0.04
    @export ghostLifeTime : float = 0.16
    @export ghostTintStart : float4 = float4(0.1, 0.9, 1.0, 0.6)
    @export ghostTintEnd : float4 = float4(0.5, 0.15, 1.0, 0.05)
    @export ghostScaleBoost : float = 1.06
    @export freezeGhostAnimation : bool = true

    @export dashSoundPath : string = "Project/Assets/SFX/Abilities/SFX_DashAbility.mp3"
    @export dashSoundVolume : float = 3.0

    cooldownLeft : float = 0.0
    dashTimeLeft : float = 0.0
    dashDir : float3 = float3(0)
    ghostTimer : float = 0.0

    def override on_initialize() : void {
        cooldownLeft = 0.0
        dashTimeLeft = 0.0
        dashDir = float3(0)
        ghostTimer = 0.0
    }

    def spawn_ghost() : void {
        let ghost_prefab = request_prefab("Project/Mechanics/VFX/Prefabs/P_DashGhost.prefab")
        let ghost = instantiate_prefab(ghost_prefab, NodeData(
            name = "DashGhost",
            position = nodeId.localPosition,
            rotation = nodeId.localRotation,
            scale = nodeId.localScale
        ))

        get_component(ghost) $(var comp : SDashAfterImage?) {
            if (comp != null) {
                comp.lifeTime = ghostLifeTime
                comp.startTint = ghostTintStart
                comp.endTint = ghostTintEnd
                comp.scaleBoost = ghostScaleBoost
                comp.freezeAnimation = freezeGhostAnimation
                comp.source = nodeId
            } else {
                add_component(ghost, new SDashAfterImage(
                    lifeTime = ghostLifeTime,
                    startTint = ghostTintStart,
                    endTint = ghostTintEnd,
                    scaleBoost = ghostScaleBoost,
                    freezeAnimation = freezeGhostAnimation,
                    source = nodeId
                ))
            }
        }
    }

    def play_dash_sound() : void {
        let sound = request_sound(dashSoundPath)
        let sid = play_sound(sound)
        set_volume(sid, dashSoundVolume)
    }

    def override collect_motion(ctx : AbilityContext) : AbilityMotionRequest {
        var req = AbilityMotionRequest()

        if (!isAbilityEnabled) {
            return req
        }

        if (cooldownLeft > 0.0) {
            cooldownLeft -= ctx.dt
            if (cooldownLeft < 0.0) {
                cooldownLeft = 0.0
            }
        }

        if (key_pressed(KeyCode.Space) && cooldownLeft <= 0.0 && dashTimeLeft <= 0.0) {
            dashDir = ctx.facingForward
            dashDir.y = 0.0

            if (length(dashDir) > 0.001) {
                dashDir = normalize(dashDir)
                dashTimeLeft = dashDuration
                cooldownLeft = dashCooldown
                ghostTimer = 0.0
                
                // Спавним первого призрака и проигрываем звук
                spawn_ghost()
                play_dash_sound()
            }
        }

        if (dashTimeLeft > 0.0) {
            dashTimeLeft -= ctx.dt

            ghostTimer -= ctx.dt
            if (ghostTimer <= 0.0) {
                ghostTimer = ghostInterval
                spawn_ghost()
            }

            req.addVelocity = dashDir * dashSpeed
            req.priority = dashPriority
        }

        return req
    }

    def override on_destroy() : void {
        pass
    }
}