require engine.core

class SAutoDestroy : Component {
    @export lifetime : float = 0.5
    timeLeft : float = 0.0

    def override on_initialize() : void {
        timeLeft = lifetime
    }

    def override on_update() : void {
        timeLeft -= get_delta_time()
        if (timeLeft <= 0.0) {
            remove_node(nodeId)
        }
    }
}