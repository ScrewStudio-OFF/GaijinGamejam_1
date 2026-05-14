require engine.core
require engine.math.math_utils
require Project.Core.Player.S_Player
require Project.Mechanics.Combat.S_AttackHitbox

class SEnemyAI : Component {
    @export patrolOffsetA : float3 = float3(-4.0, 0.0, 0.0)
    @export patrolOffsetB : float3 = float3(4.0, 0.0, 0.0)
    @export patrolWait : float = 0.6
    @export patrolSpeed : float = 1.6
    @export chaseSpeed : float = 3.6

    @export visionRange : float = 8.0
    @export visionHalfAngleDeg : float = 55.0

    @export attackRange : float = 1.4
    @export attackDuration : float = 0.7
    @export attackCooldown : float = 0.85
    @export attackHitboxDelay : float = 0.18
    @export attackDamage : float = 12.0
    @export attackKnockback : float = 12.0

    @export hitboxPrefabPath : string = "Project/Mechanics/Combat/Prefabs/P_AttackHitbox.prefab"
    @export hitboxOffset : float3 = float3(0.0, 0.9, 1.2)
    @export hitboxScale : float3 = float3(1.0)
    @export hitboxLifeTime : float = 0.16

    @no_export player : SPlayer?
    @no_export homePosition : float3 = float3(0.0)
    @no_export facingDir : float3 = FORWARD

    @no_export hasSeenPlayer : bool = false
    @no_export state : int = 0
    @no_export patrolIndex : int = 0
    @no_export patrolWaitLeft : float = 0.0

    @no_export attackTimeLeft : float = 0.0
    @no_export attackCooldownLeft : float = 0.0
    @no_export attackHitboxDelayLeft : float = 0.0
    @no_export attackHitboxSpawned : bool = false

    def override on_initialize() : void {
        player = find_component(type<SPlayer>)
        homePosition = nodeId.localPosition
        facingDir = FORWARD

        hasSeenPlayer = false
        state = 0
        patrolIndex = 0
        patrolWaitLeft = 0.0

        attackTimeLeft = 0.0
        attackCooldownLeft = 0.0
        attackHitboxDelayLeft = 0.0
        attackHitboxSpawned = false
    }

    def override on_update() : void {
        let dt = get_delta_time()

        if (player == null) {
            player = find_component(type<SPlayer>)
        }

        if (player == null) {
            stop_horizontal_motion()
            return
        }

        if (attackCooldownLeft > 0.0) {
            attackCooldownLeft -= dt
            if (attackCooldownLeft < 0.0) {
                attackCooldownLeft = 0.0
            }
        }

        if (!hasSeenPlayer && can_see_player()) {
            hasSeenPlayer = true
        }

        if (state == 2) {
            update_attack(dt)
            return
        }

        if (hasSeenPlayer) {
            update_chase(dt)
        } else {
            update_patrol(dt)
        }
    }

    def private update_patrol(dt : float) : void {
        if (patrolWaitLeft > 0.0) {
            patrolWaitLeft -= dt
            stop_horizontal_motion()
            return
        }

        let target = get_patrol_target()
        let toTarget = flat_delta(target, nodeId.worldPosition)
        let dist = length(toTarget)

        if (dist <= 0.25) {
            patrolIndex = 1 - patrolIndex
            patrolWaitLeft = patrolWait
            stop_horizontal_motion()
            return
        }

        let dir = normalize(toTarget)
        face_direction(dir)
        set_horizontal_velocity(dir, patrolSpeed)
    }

    def private update_chase(dt : float) : void {
        let targetPos = player.nodeId.worldPosition
        let toPlayer = flat_delta(targetPos, nodeId.worldPosition)
        let dist = length(toPlayer)

        if (dist <= attackRange && attackCooldownLeft <= 0.0) {
            begin_attack()
            return
        }

        if (dist > 0.001) {
            let dir = normalize(toPlayer)
            face_direction(dir)
            set_horizontal_velocity(dir, chaseSpeed)
        } else {
            stop_horizontal_motion()
        }
    }

    def private begin_attack() : void {
        state = 2
        attackTimeLeft = attackDuration
        attackHitboxDelayLeft = attackHitboxDelay
        attackHitboxSpawned = false
        stop_horizontal_motion()
    }

    def private update_attack(dt : float) : void {
        let targetPos = player.nodeId.worldPosition
        let toPlayer = flat_delta(targetPos, nodeId.worldPosition)
        let dist = length(toPlayer)

        if (dist > 0.001) {
            face_direction(normalize(toPlayer))
        }

        stop_horizontal_motion()

        attackTimeLeft -= dt
        attackHitboxDelayLeft -= dt

        if (!attackHitboxSpawned && attackHitboxDelayLeft <= 0.0) {
            spawn_attack_hitbox()
            attackHitboxSpawned = true
        }

        if (attackTimeLeft <= 0.0) {
            attackCooldownLeft = attackCooldown
            state = 1
        }
    }

    def private spawn_attack_hitbox() : void {
        let prefab = request_prefab(hitboxPrefabPath)
        let hitbox = instantiate_prefab(prefab, NodeData(name = "EnemyAttackHitbox"))

        hitbox.set_parent(nodeId, AddChildStrategy.KeepLocalTransform)
        hitbox.localPosition = hitboxOffset
        hitbox.localScale = hitboxScale

        get_component(hitbox) $(var hb : SAttackHitbox?) {
            if (hb != null) {
                hb.owner = nodeId
                hb.damage = attackDamage
                hb.knockbackForce = attackKnockback
                hb.set_lifetime(hitboxLifeTime)
                // enable debug prints temporarily to verify hits
                hb.debugPrintHits = true
            }
        }
    }

    def private can_see_player() : bool {
        let toPlayer = flat_delta(player.nodeId.worldPosition, nodeId.worldPosition)
        let dist = length(toPlayer)

        if (dist > visionRange) {
            return false
        }

        if (dist < 0.001) {
            return true
        }

        let dirToPlayer = normalize(toPlayer)
        let forward = get_forward_dir()
        let cosHalfAngle = cos(visionHalfAngleDeg * PI / 180.0)

        return dot(forward, dirToPlayer) >= cosHalfAngle
    }

    def private get_patrol_target() : float3 {
        if (patrolIndex == 0) {
            return homePosition + patrolOffsetA
        }

        return homePosition + patrolOffsetB
    }

    def private get_forward_dir() : float3 {
        var fwd = facingDir
        fwd.y = 0.0

        if (length(fwd) < 0.001) {
            return FORWARD
        }

        return normalize(fwd)
    }

    def private face_direction(dir : float3) : void {
        var flatDir = dir
        flatDir.y = 0.0

        if (length(flatDir) < 0.001) {
            return
        }

        flatDir = normalize(flatDir)
        facingDir = flatDir

        let yaw = atan2(flatDir.x, flatDir.z)
        nodeId.localRotation = quat4(0.0, yaw, 0.0)
    }

    def private set_horizontal_velocity(dir : float3; speed : float) : void {
        // Prefer CharacterController movement when available (collides with world)
        get_component(nodeId) $(var cc : CharacterController?) {
            if (cc != null) {
                var v = cc.velocity
                v.x = dir.x * speed
                v.z = dir.z * speed
                cc.velocity = v
                return
            }
        }

        // Fallback to RigidBody velocity if no CharacterController
        get_component(nodeId) $(var rb : RigidBody?) {
            if (rb != null) {
                var velocity = rb.velocity
                velocity.x = dir.x * speed
                velocity.z = dir.z * speed
                rb.velocity = velocity
            }
        }
    }

    def private stop_horizontal_motion() : void {
        // Prefer CharacterController stop when available
        get_component(nodeId) $(var cc : CharacterController?) {
            if (cc != null) {
                var v = cc.velocity
                v.x = 0.0
                v.z = 0.0
                cc.velocity = v
                return
            }
        }

        // Fallback to stopping RigidBody
        get_component(nodeId) $(var rb : RigidBody?) {
            if (rb != null) {
                var velocity = rb.velocity
                velocity.x = 0.0
                velocity.z = 0.0
                rb.velocity = velocity
            }
        }
    }

    def private flat_delta(a : float3; b : float3) : float3 {
        var d = a - b
        d.y = 0.0
        return d
    }

    def override on_destroy() : void {
        pass
    }
}