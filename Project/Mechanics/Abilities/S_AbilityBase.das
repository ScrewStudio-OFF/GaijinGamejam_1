require engine.core
require engine.math.math_utils

// Контекст кадра, который Player передает всем способностям
struct AbilityContext {
    dt : float = 0.0
    moveInput : float2 = float2(0)
    facingForward : float3 = FORWARD
    isGrounded : bool = false
    owner : NodeId = NodeId()
    ownerPosition : float3 = float3(0)
}

// Результат способности для текущего кадра
struct AbilityMotionRequest {
    addVelocity : float3 = float3(0)

    // Если true — способность хочет переопределить горизонтальную скорость
    overrideVelocity : bool = false
    overrideHorizontal : float3 = float3(0)

    // Кто выше priority, тот выигрывает override
    priority : int = 0
}

// Базовый контракт для всех способностей
class SAbilityBase : Component {
    @export isAbilityEnabled : bool = true

    // Переопределяется конкретными способностями
    def collect_motion(ctx : AbilityContext) : AbilityMotionRequest {
        return AbilityMotionRequest()
    }
}