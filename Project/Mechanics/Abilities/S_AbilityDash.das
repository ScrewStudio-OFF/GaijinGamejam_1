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
    visualRoot : NodeId = NodeId()

    def override on_initialize() : void {
        cooldownLeft = 0.0
        dashTimeLeft = 0.0
        dashDir = float3(0)
        ghostTimer = 0.0
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

        if (is_action_just_pressed("dash") && cooldownLeft <= 0.0 && dashTimeLeft <= 0.0) {
            dashDir = ctx.facingForward
            dashDir.y = 0.0

            if (length(dashDir) > 0.001) {
                dashDir = normalize(dashDir)
                dashTimeLeft = dashDuration
                cooldownLeft = dashCooldown
                ghostTimer = 0.0

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

    def private spawn_ghost() : void {
        visualRoot = NodeId()
        find_visual_root(nodeId)

        if (!visualRoot.isAlive) {
            return
        }

        let ghost = duplicate_node(visualRoot, NodeData(
            name = "DashGhost",
            position = visualRoot.localPosition,
            rotation = visualRoot.localRotation,
            scale = visualRoot.localScale
        ))

        ghost.set_parent(nodeId.parent, AddChildStrategy.KeepWorldTransform)

        add_component(ghost, new SDashAfterImage(
            lifeTime = ghostLifeTime,
            startTint = ghostTintStart,
            endTint = ghostTintEnd,
            scaleBoost = ghostScaleBoost,
            freezeAnimation = freezeGhostAnimation,
            source = nodeId
        ))
    }

    def private find_visual_root(root : NodeId) : void {
        if (visualRoot.isAlive) {
            return
        }

        let sap = get_component(root, type<SingleAnimationPlayer>)
        if (sap != null) {
            visualRoot = root
            return
        }

        var inscope children = root.get_children()
        for (child in children) {
            find_visual_root(child)
        }
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
