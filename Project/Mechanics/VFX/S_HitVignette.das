require engine.core
require engine.math.math_utils

class SHitVignette : Component {
    @export vignetteColor : float4 = float4(1.0, 0.2, 0.2, 0.6)
    @export vignetteDuration : float = 0.15
    @export maxVignetteDistance : float = 50.0

    vignetteTimeLeft : float = 0.0
    vignetteOverlay : NodeId = NodeId()

    def override on_initialize() : void {
        vignetteTimeLeft = 0.0
        vignetteOverlay = NodeId()
    }

    def override on_update() : void {
        if (vignetteTimeLeft <= 0.0) {
            if (vignetteOverlay.isAlive) {
                remove_node(vignetteOverlay)
                vignetteOverlay = NodeId()
            }
            return
        }

        vignetteTimeLeft -= get_delta_time()

        if (vignetteOverlay.isAlive) {
            let alpha = clamp(vignetteTimeLeft / vignetteDuration, 0.0, 1.0)
            update_vignette_alpha(vignetteOverlay, alpha)
        }
    }

    def apply_vignette(sourcePos : float3; magnitude : float = 1.0) : void {
        let distance = length(nodeId.worldPosition - sourcePos)
        
        if (distance > maxVignetteDistance) {
            return
        }

        let distanceFalloff = max(1.0 - (distance / maxVignetteDistance), 0.0)
        
        vignetteTimeLeft = vignetteDuration * magnitude * distanceFalloff
        
        if (!vignetteOverlay.isAlive) {
            create_vignette_overlay()
        }
    }

    def private create_vignette_overlay() : void {
        let uiCanvas = find_component(type<UICanvas>)
        if (uiCanvas == null) {
            return
        }

        vignetteOverlay = create_node(NodeData(
            name = "VignetteOverlay",
            parent = uiCanvas.nodeId
        ))

        add_component(vignetteOverlay, new UIImage(
            color = vignetteColor,
            size = float2(2000.0, 2000.0)
        ))

        get_component(vignetteOverlay) $(var frame : UIFrame?) {
            if (frame != null) {
                frame.size = float2(2000.0, 2000.0)
            }
        }

        var anchor = add_component(vignetteOverlay, new UIAnchor())
        if (anchor != null) {
            anchor.anchorMin = float2(0, 0)
            anchor.anchorMax = float2(1, 1)
        }
    }

    def private update_vignette_alpha(overlay : NodeId; alpha : float) : void {
        get_component(overlay) $(var image : UIImage?) {
            if (image != null) {
                var col = vignetteColor
                col.w = vignetteColor.w * alpha
                image.color = col
            }
        }
    }

    def override on_destroy() : void {
        if (vignetteOverlay.isAlive) {
            remove_node(vignetteOverlay)
        }
    }
}

