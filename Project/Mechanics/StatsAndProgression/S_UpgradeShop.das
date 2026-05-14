require engine.core
require Project.Core.Player.S_Player
require Project.Mechanics.StatsAndProgression.S_GameState
require Project.Mechanics.StatsAndProgression.S_PlayerStats

class SUpgradeShop : Component {
    @export canvasSize : float2 = float2(1920.0, 1080.0)
    
    isOpen : bool = false
    playerNode : NodeId = NodeId()
    menuRootNode : NodeId = NodeId()
    coinsTextNode : NodeId = NodeId()
    statusTextNode : NodeId = NodeId()
    hpButtonNode : NodeId = NodeId()
    damageButtonNode : NodeId = NodeId()
    speedButtonNode : NodeId = NodeId()
    closeButtonNode : NodeId = NodeId()

    def override on_initialize() : void {
        self->cache_ui_nodes()
        self->wire_buttons()

        if (menuRootNode != NodeId()) {
            menuRootNode.isActive = false
        }

        if (progress_is_arena_cleared()) {
            open_shop()
        }
    }

    def override on_update() : void {
        if (isOpen) {
            self->update_ui_text()
        }
    }

    def open_shop() : void {
        if (isOpen) {
            return
        }
        
        isOpen = true
        self->find_player()
        if (menuRootNode != NodeId()) {
            menuRootNode.isActive = true
        }
        self->update_ui_text()
        print("Upgrade shop opened")
    }

    def close_shop() : void {
        if (!isOpen) {
            return
        }
        
        isOpen = false
        if (menuRootNode != NodeId()) {
            menuRootNode.isActive = false
        }
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

    def private cache_ui_nodes() : void {
        menuRootNode = self->find_node_recursive(nodeId, "UpgradeMenuRoot")
        coinsTextNode = self->find_node_recursive(nodeId, "UpgradeCoinsText")
        statusTextNode = self->find_node_recursive(nodeId, "UpgradeStatusText")
        hpButtonNode = self->find_node_recursive(nodeId, "UpgradeHpButton")
        damageButtonNode = self->find_node_recursive(nodeId, "UpgradeDamageButton")
        speedButtonNode = self->find_node_recursive(nodeId, "UpgradeSpeedButton")
        closeButtonNode = self->find_node_recursive(nodeId, "UpgradeCloseButton")
    }

    def private wire_buttons() : void {
        if (hpButtonNode != NodeId()) {
            get_component(hpButtonNode) $(var btn : UIButton?) {
                if (btn != null) {
                    btn.onClick = @() {
                        self->buy_hp_upgrade()
                    }
                }
            }
        }

        if (damageButtonNode != NodeId()) {
            get_component(damageButtonNode) $(var btn : UIButton?) {
                if (btn != null) {
                    btn.onClick = @() {
                        self->buy_damage_upgrade()
                    }
                }
            }
        }

        if (speedButtonNode != NodeId()) {
            get_component(speedButtonNode) $(var btn : UIButton?) {
                if (btn != null) {
                    btn.onClick = @() {
                        self->buy_speed_upgrade()
                    }
                }
            }
        }

        if (closeButtonNode != NodeId()) {
            get_component(closeButtonNode) $(var btn : UIButton?) {
                if (btn != null) {
                    btn.onClick = @() {
                        self->close_shop()
                    }
                }
            }
        }
    }

    def private update_ui_text() : void {
        if (coinsTextNode != NodeId()) {
            get_component(coinsTextNode) $(var text : UIText?) {
                if (text != null) {
                    text.text = "Coins: {progress_get_saved_coins()}"
                }
            }
        }

        if (statusTextNode != NodeId()) {
            get_component(statusTextNode) $(var text : UIText?) {
                if (text != null) {
                    text.text = "HP {hpLevelText()}  DMG {damageLevelText()}  SPD {speedLevelText()}"
                }
            }
        }
    }

    def private hpLevelText() : string {
        var result = "0/3"
        get_component(playerNode) $(var stats : SPlayerStats?) {
            if (stats != null) {
                result = "{stats.hpUpgradeLevel}/3"
            }
        }
        return result
    }

    def private damageLevelText() : string {
        var result = "0/3"
        get_component(playerNode) $(var stats : SPlayerStats?) {
            if (stats != null) {
                result = "{stats.damageUpgradeLevel}/3"
            }
        }
        return result
    }

    def private speedLevelText() : string {
        var result = "0/3"
        get_component(playerNode) $(var stats : SPlayerStats?) {
            if (stats != null) {
                result = "{stats.speedUpgradeLevel}/3"
            }
        }
        return result
    }

    def private find_node_recursive(startNode : NodeId, targetName : string) : NodeId {
        if (startNode == NodeId()) {
            return NodeId()
        }

        if (startNode.name == targetName) {
            return startNode
        }

        let children = get_children(startNode)

        for (child in children) {
            let found = self->find_node_recursive(child, targetName)

            if (found != NodeId()) {
                return found
            }
        }

        return NodeId()
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
