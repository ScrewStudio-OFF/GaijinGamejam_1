require engine.core
require engine.math.math_utils

class SDashAfterImage : Component {
    @export lifeTime : float = 0.16
    @export startTint : float4 = float4(0.15, 0.95, 1.0, 0.55)
    @export endTint : float4 = float4(0.4, 0.2, 1.0, 0.1)
    @export scaleBoost : float = 1.06
    @export freezeAnimation : bool = true
    @export source : NodeId = NodeId()

    timeLeft : float = 0.0
    baseScale : float3 = float3(1.0)

    def override on_initialize() : void {
        timeLeft = lifeTime
        baseScale = nodeId.localScale

        if (source.isAlive) {
            copy_hierarchy(source, nodeId)
        }

        tint_recursive(nodeId, startTint)

        if (freezeAnimation) {
            get_component(nodeId) $(var animator : Animator?) {
                if (animator != null) {
                    animator.enabled = false
                }
            }

            get_component(nodeId) $(var singleAnimation : SingleAnimationPlayer?) {
                if (singleAnimation != null) {
                    singleAnimation.enabled = false
                }
            }
        }
    }

    def override on_update() : void {
        timeLeft -= get_delta_time()

        let t = clamp(timeLeft / lifeTime, 0.0, 1.0)
        
        // Интерполяция цвета: начальный → конечный
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

    def private copy_hierarchy(src : NodeId, dst : NodeId) : void {
        dst.localPosition = src.localPosition
        dst.localRotation = src.localRotation
        dst.localScale = src.localScale

        var inscope srcChildren = src.get_children()
        var inscope dstChildren = dst.get_children()

        for (s in srcChildren) {
            for (d in dstChildren) {
                if (d.name == s.name) {
                    d.localPosition = s.localPosition
                    d.localRotation = s.localRotation
                    d.localScale = s.localScale
                    copy_hierarchy(s, d)
                    break
                }
            }
        }
    }

    def override on_destroy() : void {
        pass
    }
}