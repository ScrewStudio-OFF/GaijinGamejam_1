require engine.core
require engine.math.math_utils

// Плавное слежение камеры за сценным NodeId (указывается в инспекторе или задаётся из кода)
class SCameraFollow : Component {
    @export target : NodeId = NodeId()         // Привязать в инспекторе или установить из main.das
    @export offset : float3 = float3(0.0, 20, -5)
    @export follow_halflife : float = 0.15     // Полужизнь сглаживания: меньше = резче, больше = плавнее

    def override on_initialize() : void {
        pass
    }

    def override on_update() : void {
        if (!target.isAlive) {
            return
        }

        let desired_pos = target.localPosition + offset
        let current_pos = nodeId.localPosition

        // Экспоненциальная подстройка позиции: approach(from, to, dt, half_life)
        let new_pos = approach(current_pos, desired_pos, get_delta_time(), follow_halflife)
        nodeId.localPosition = new_pos
    }

    def override on_destroy() : void {
        pass
    }
}