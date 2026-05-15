require engine.core
require engine.math.math_utils

class SDashAfterImage : Component {
    @export lifeTime : float = 0.16
    @export startTint : float4 = float4(0.15, 0.95, 1.0, 0.55)
    @export endTint : float4 = float4(0.4, 0.2, 1.0, 0.1)
    @export scaleBoost : float = 1.06
    @export freezeAnimation : bool = true
    @export freezeDelay : float = 0.04
    @export source : NodeId = NodeId()

    timeLeft : float = 0.0
    baseScale : float3 = float3(1.0)
    freezeLeft : float = 0.0
    freezeApplied : bool = false

    def override on_initialize() : void {
        timeLeft = lifeTime
        baseScale = nodeId.localScale
        freezeLeft = max(freezeDelay, 0.0)
        freezeApplied = false

        remove_physics_recursive(nodeId)
        tint_recursive(nodeId, startTint)
    }

    def override on_update() : void {
        timeLeft -= get_delta_time()

        if (freezeAnimation && !freezeApplied) {
            freezeLeft -= get_delta_time()
            if (freezeLeft <= 0.0) {
                set_animation_enabled_recursive(nodeId, false)
                freezeApplied = true
            }
        }

        let t = clamp(timeLeft / lifeTime, 0.0, 1.0)
        let colorLerp = float4(
            startTint.x + (endTint.x - startTint.x) * (1.0 - t),
            startTint.y + (endTint.y - startTint.y) * (1.0 - t),
            startTint.z + (endTint.z - startTint.z) * (1.0 - t),
            startTint.w * t
        )

        tint_recursive(nodeId, colorLerp)

        let grow = 1.0 + (1.0 - t) * (scaleBoost - 1.0)
        nodeId.localScale = baseScale * grow

        if (timeLeft <= 0.0) {
            remove_node(nodeId)
        }
    }

    def private tint_recursive(target : NodeId, color : float4) : void {
        get_component(target) $(var mesh : Mesh?) {
            if (mesh != null) {
                mesh.color = color
                mesh.visibility = MeshVisibility.VisibleInAnyCamera
            }
        }

        get_component(target) $(var sprite : SpriteRenderer?) {
            if (sprite != null) {
                sprite.color = color
            }
        }

        var inscope children = target.get_children()
        for (child in children) {
            tint_recursive(child, color)
        }
    }

    def private remove_physics_recursive(root : NodeId) : void {
        get_component(root) $(var rb : RigidBody?) {
            if (rb != null) {
                remove_component(root, rb)
            }
        }

        get_component(root) $(var collider : Collider?) {
            if (collider != null) {
                remove_component(root, collider)
            }
        }

        get_component(root) $(var cc : CharacterController?) {
            if (cc != null) {
                remove_component(root, cc)
            }
        }

        var inscope children = root.get_children()
        for (child in children) {
            remove_physics_recursive(child)
        }
    }

    def private set_animation_enabled_recursive(root : NodeId; enabled : bool) : void {
        get_component(root) $(var sap : SingleAnimationPlayer?) {
            if (sap != null) {
                sap.enabled = enabled
            }
        }

        var inscope children = root.get_children()
        for (child in children) {
            set_animation_enabled_recursive(child, enabled)
        }
    }

    def override on_destroy() : void {
        pass
    }
}