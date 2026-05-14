require engine.core
require engine.input.global_input_state
require engine.math.math_utils
require engine.sound_core
require Project.Mechanics.Abilities.S_AbilityBase
require Project.Mechanics.VFX.S_DashAfterImage
require Project.Core.Player.S_Player
require Project.Mechanics.Combat.S_PlayerCombat
require Project.Mechanics.Combat.S_Damageable

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
    @export freezeGhostAnimation : bool = true

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

        if (key_pressed(KeyCode.Space) && cooldownLeft <= 0.0 && dashTimeLeft <= 0.0) {
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

        for (copyIndex in range(ghostCopiesPerSpawn)) {
            let copyOffset = dashDir * (ghostCopySpacing * float(copyIndex))

            let ghost = duplicate_node(nodeId, NodeData(
                name = "DashGhost",
                position = nodeId.localPosition - copyOffset,
                rotation = nodeId.localRotation,
                scale = nodeId.localScale
            ))

            ghost.set_parent(nodeId.parent, AddChildStrategy.KeepWorldTransform)
            strip_gameplay_components(ghost)

            let afterImage = add_component(ghost, new SDashAfterImage(
                lifeTime = ghostLifeTime,
                startTint = ghostTintStart,
                endTint = ghostTintEnd,
                scaleBoost = ghostScaleBoost,
                freezeAnimation = freezeGhostAnimation,
                source = nodeId
            ))
        }
    }

    def private strip_gameplay_components(root : NodeId) : void {
        remove_component(root, type<SPlayer>)
        remove_component(root, type<SPlayerCombat>)
        remove_component(root, type<SAbilityDash>)
        remove_component(root, type<SDamageable>)
        remove_component(root, type<RigidBody>)
        // CharacterController may not exist, so we skip it
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