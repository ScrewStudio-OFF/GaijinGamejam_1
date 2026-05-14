require engine.core
require Project.Core.Player.S_Player
require Project.Mechanics.StatsAndProgression.S_GameState
require Project.Mechanics.StatsAndProgression.S_PlayerStats

class SUpgradeShop : Component {
    @export canvasSize : float2 = float2(1920.0, 1080.0)
    
    isOpen : bool = false
    playerNode : NodeId = NodeId()

    def override on_initialize() : void {
        if (progress_is_arena_cleared()) {
            open_shop()
        }
    }

    def open_shop() : void {
        if (isOpen) {
            return
        }
        
        isOpen = true
        self->find_player()
        print("Upgrade shop opened")
    }

    def close_shop() : void {
        if (!isOpen) {
            return
        }
        
        isOpen = false
        print("Upgrade shop closed")
    }

    def perform_hp_upgrade(playerNode : NodeId) : void {
        var stats = get_component(playerNode, type<SPlayerStats>)
        if (stats != null) {
            stats.upgrade_hp()
        }
    }

    def perform_damage_upgrade(playerNode : NodeId) : void {
        var stats = get_component(playerNode, type<SPlayerStats>)
        if (stats != null) {
            stats.upgrade_damage()
        }
    }

    def perform_speed_upgrade(playerNode : NodeId) : void {
        var stats = get_component(playerNode, type<SPlayerStats>)
        if (stats != null) {
            stats.upgrade_speed()
        }
    }

    def buy_hp_upgrade() : void {
        self->find_player()
        if (playerNode != NodeId() && playerNode.isAlive) {
            self->perform_hp_upgrade(playerNode)
        }
    }

    def buy_damage_upgrade() : void {
        self->find_player()
        if (playerNode != NodeId() && playerNode.isAlive) {
            self->perform_damage_upgrade(playerNode)
        }
    }

    def buy_speed_upgrade() : void {
        self->find_player()
        if (playerNode != NodeId() && playerNode.isAlive) {
            self->perform_speed_upgrade(playerNode)
        }
    }

    def private find_player() : void {
        if (playerNode != NodeId() && playerNode.isAlive) {
            return
        }

        let roots = get_scene_roots()

        for (root in roots) {
            let found = self->find_player_recursive(root)

            if (found != NodeId()) {
                playerNode = found
                return
            }
        }
    }

    def private find_player_recursive(n : NodeId) : NodeId {
        let player = get_component(n, type<SPlayer>)

        if (player != null) {
            return n
        }

        if (n.name == "P_Player") {
            return n
        }

        let children = get_children(n)

        for (child in children) {
            let found = self->find_player_recursive(child)

            if (found != NodeId()) {
                return found
            }
        }

        return NodeId()
    }

    def override on_destroy() : void {
        close_shop()
    }
}
