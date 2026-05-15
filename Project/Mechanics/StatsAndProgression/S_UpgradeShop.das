require engine.core
require Project.Core.Player.S_Player
require Project.Mechanics.StatsAndProgression.S_GameState
require Project.Mechanics.StatsAndProgression.S_PlayerStats

class SUpgradeShop : Component {
    @export canvasSize : float2 = float2(1920.0, 1080.0)
    @export titleTexturePath : string = "Project/Assets/UI/UpgradeTitleText.png"
    @export coinsHolderTexturePath : string = "Project/Assets/UI/UpgradeCoinsTextHolder.png"
    @export statusHolderTexturePath : string = "Project/Assets/UI/UpgradeStatusTextHolder.png"
    @export hpButtonTexturePath : string = "Project/Assets/UI/UpgradeHpButton.png"
    @export damageButtonTexturePath : string = "Project/Assets/UI/UpgradeDamageButton.png"
    @export speedButtonTexturePath : string = "Project/Assets/UI/UpgradeSpeedButton.png"
    @export closeButtonTexturePath : string = "Project/Assets/UI/UpgradeCloseButton.png"
    
    isOpen : bool = false
    playerNode : NodeId = NodeId()
    menuRootNode : NodeId = NodeId()
    titleNode : NodeId = NodeId()
    coinsTextNode : NodeId = NodeId()
    statusTextNode : NodeId = NodeId()
    hpButtonNode : NodeId = NodeId()
    damageButtonNode : NodeId = NodeId()
    speedButtonNode : NodeId = NodeId()
    closeButtonNode : NodeId = NodeId()
    layoutSize : float2 = float2(1920.0, 1080.0)

    def override on_initialize() : void {
        self->cache_ui_nodes()
        self->setup_canvas()
        self->style_ui()
        self->wire_buttons()

        if (menuRootNode != NodeId()) {
            menuRootNode.isActive = false
        }

        if (progress_is_arena_cleared()) {
            open_shop()
        }
    }

    def override on_update() : void {
        if (self->refresh_layout_size()) {
            self->style_ui()
        }

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
        self->refresh_layout_size()
        self->style_ui()
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
        titleNode = self->find_node_recursive(nodeId, "UpgradeTitleText")
        coinsTextNode = self->find_node_recursive(nodeId, "UpgradeCoinsText")
        statusTextNode = self->find_node_recursive(nodeId, "UpgradeStatusText")
        hpButtonNode = self->find_node_recursive(nodeId, "UpgradeHpButton")
        damageButtonNode = self->find_node_recursive(nodeId, "UpgradeDamageButton")
        speedButtonNode = self->find_node_recursive(nodeId, "UpgradeSpeedButton")
        closeButtonNode = self->find_node_recursive(nodeId, "UpgradeCloseButton")
    }

    def private setup_canvas() : void {
        nodeId.localPosition = float3(0.0, 0.0, 0.0)
        nodeId.localScale = float3(1.0, 1.0, 1.0)

        var hasFrame = false
        get_component(nodeId) $(var frame : UIFrame?) {
            if (frame != null) {
                hasFrame = true
                frame.size = canvasSize
                frame.pivot = float2(0.0, 0.0)
                frame.localPosition2D = float2(0.0, 0.0)
            }
        }

        if (!hasFrame) {
            add_component(nodeId, new UIFrame(size = canvasSize, pivot = float2(0.0, 0.0)))
            nodeId?.UIFrame.localPosition2D = float2(0.0, 0.0)
        }

        var hasCanvas = false
        get_component(nodeId) $(var canvas : UICanvas?) {
            if (canvas != null) {
                hasCanvas = true
                canvas.screenMode = ScreenMode.FitExtend
                canvas.size = canvasSize
            }
        }

        if (!hasCanvas) {
            add_component(nodeId, new UICanvas(screenMode = ScreenMode.FitExtend, size = canvasSize))
        }

        layoutSize = canvasSize
        self->refresh_layout_size()
    }

    def private style_ui() : void {
        if (menuRootNode == NodeId()) {
            return
        }

        let centerX = layoutSize.x * 0.5

        self->set_frame(menuRootNode, float2(0.0, 0.0), layoutSize, float2(0.0, 0.0))
        self->set_image(menuRootNode, "", layoutSize, float2(0.0, 0.0), float4(0.0, 0.0, 0.0, 0.62))

        self->style_image_node(titleNode, titleTexturePath, float2(centerX, 150.0), float2(620.0, 113.0), true)
        self->style_image_node(coinsTextNode, coinsHolderTexturePath, float2(centerX, 245.0), float2(500.0, 50.0), false)
        self->style_image_node(statusTextNode, statusHolderTexturePath, float2(centerX, 302.0), float2(640.0, 50.0), false)
        self->style_image_node(hpButtonNode, hpButtonTexturePath, float2(centerX, 430.0), float2(560.0, 143.0), true)
        self->style_image_node(damageButtonNode, damageButtonTexturePath, float2(centerX, 570.0), float2(560.0, 143.0), true)
        self->style_image_node(speedButtonNode, speedButtonTexturePath, float2(centerX, 710.0), float2(560.0, 143.0), true)
        self->style_image_node(closeButtonNode, closeButtonTexturePath, float2(centerX, 875.0), float2(250.0, 95.0), true)

        self->set_text_style(coinsTextNode, 27.0, float4(0.96, 0.98, 1.0, 1.0), TextHorAlignment.Center)
        self->set_text_style(statusTextNode, 25.0, float4(0.96, 0.98, 1.0, 1.0), TextHorAlignment.Center)

        self->ensure_button(hpButtonNode)
        self->ensure_button(damageButtonNode)
        self->ensure_button(speedButtonNode)
        self->ensure_button(closeButtonNode)
    }

    def private refresh_layout_size() : bool {
        var newSize = canvasSize

        get_component(nodeId) $(var frame : UIFrame?) {
            if (frame != null && frame.size.x > 1.0 && frame.size.y > 1.0) {
                newSize = frame.size
            }
        }

        let dx = newSize.x - layoutSize.x
        let dy = newSize.y - layoutSize.y
        if (dx > 0.5 || dx < -0.5 || dy > 0.5 || dy < -0.5) {
            layoutSize = newSize
            return true
        }

        return false
    }

    def private style_image_node(n : NodeId, texturePath : string, pos : float2, size : float2, clearText : bool) : void {
        if (n == NodeId()) {
            return
        }

        self->set_frame(n, pos, size, float2(0.5, 0.5))
        self->set_image(n, texturePath, size, float2(0.5, 0.5), float4(1.0, 1.0, 1.0, 1.0))

        if (clearText) {
            self->set_text(n, "")
        }
    }

    def private set_frame(n : NodeId, pos : float2, size : float2, pivot : float2) : void {
        n.localPosition = float3(0.0, 0.0, 0.0)
        n.localScale = float3(1.0, 1.0, 1.0)

        var hasFrame = false
        get_component(n) $(var frame : UIFrame?) {
            if (frame != null) {
                hasFrame = true
                frame.size = size
                frame.pivot = pivot
                frame.localPosition2D = pos
            }
        }

        if (!hasFrame) {
            add_component(n, new UIFrame(size = size, pivot = pivot))
            n?.UIFrame.localPosition2D = pos
        }
    }

    def private set_image(n : NodeId, texturePath : string, size : float2, pivot : float2, color : float4) : void {
        var hasImage = false
        get_component(n) $(var image : UIImage?) {
            if (image != null) {
                hasImage = true
                if (length(texturePath) > 0) {
                    image.textureId = request_texture(texturePath)
                }
                image.color = color
                image.size = size
                image.pivot = pivot
            }
        }

        if (!hasImage) {
            if (length(texturePath) > 0) {
                add_component(n, new UIImage(
                    textureId = request_texture(texturePath),
                    color = color,
                    size = size,
                    pivot = pivot
                ))
            } else {
                add_component(n, new UIImage(
                    color = color,
                    size = size,
                    pivot = pivot
                ))
            }
        }
    }

    def private set_text_style(n : NodeId, fontSize : float, color : float4, alignment : TextHorAlignment) : void {
        get_component(n) $(var text : UIText?) {
            if (text != null) {
                text.color = color
                text.fontSize = fontSize
                text.fontScaling = false
                text.autoResizeFrame = false
                text.wordWrapping = false
                text.horAlignment = alignment
                text.vertAlignment = TextVertAlignment.Middle
                text.pivot = float2(0.5, 0.5)
            }
        }
    }

    def private set_text(n : NodeId, value : string) : void {
        get_component(n) $(var text : UIText?) {
            if (text != null) {
                text.text = value
            }
        }
    }

    def private ensure_button(n : NodeId) : void {
        if (n == NodeId()) {
            return
        }

        var hasButton = false
        get_component(n) $(var btn : UIButton?) {
            if (btn != null) {
                hasButton = true
            }
        }

        if (!hasButton) {
            add_component(n, new UIButton())
        }
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
                    text.text = "{progress_get_saved_coins()}"
                }
            }
        }

        if (statusTextNode != NodeId()) {
            get_component(statusTextNode) $(var text : UIText?) {
                if (text != null) {
                    text.text = "HP {hpLevelText()}   DMG {damageLevelText()}   SPD {speedLevelText()}"
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
