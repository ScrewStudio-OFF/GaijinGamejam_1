require engine.core
require engine.math.math_utils

class SCameraShake : Component {
    @export maxShakeDistance : float = 30.0
    @export shakeStrength : float = 0.3
    @export shakeDuration : float = 0.1

    shakeTimeLeft : float = 0.0
    originalPos : float3 = float3(0)
    targetCamera : Camera? = null
    shakeTime : float = 0.0

    def override on_initialize() : void {
        shakeTimeLeft = 0.0
        originalPos = nodeId.localPosition
        targetCamera = get_component(nodeId, type<Camera>)
        shakeTime = 0.0
    }

    def override on_update() : void {
        if (shakeTimeLeft <= 0.0) {
            return
        }

        shakeTimeLeft -= get_delta_time()
        shakeTime += get_delta_time()

        if (shakeTimeLeft <= 0.0) {
            nodeId.localPosition = originalPos
            return
        }

        let progress = 1.0 - (shakeTimeLeft / shakeDuration)
        let strength = shakeStrength * (1.0 - progress)

        let shakeX = sin(shakeTime * 50.0) * strength
        let shakeY = cos(shakeTime * 60.0) * strength
        let shakeZ = sin(shakeTime * 70.0 + 1.5707963) * strength

        nodeId.localPosition = originalPos + float3(shakeX, shakeY, shakeZ)
    }

    def apply_shake(sourcePos : float3; magnitude : float = 1.0) : void {
        let distance = length(nodeId.worldPosition - sourcePos)
        
        if (distance > maxShakeDistance) {
            return
        }

        let distanceFalloff = max(1.0 - (distance / maxShakeDistance), 0.0)
        
        shakeTimeLeft = shakeDuration
        originalPos = nodeId.localPosition
        shakeTime = 0.0

        var adjustedStrength = shakeStrength * magnitude * distanceFalloff
        shakeTimeLeft = shakeDuration
    }

    def override on_destroy() : void {
        pass
    }
}


