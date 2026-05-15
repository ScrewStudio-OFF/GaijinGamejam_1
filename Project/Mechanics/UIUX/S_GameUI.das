require engine.core
require engine.input_core
require Project.Core.Player.S_Player
require Project.Mechanics.Combat.S_Damageable
require Project.Mechanics.StatsAndProgression.S_GameState


def game_ui_find_player_recursive(nodeId : NodeId, playerName : string) : NodeId {
    let player = get_component(nodeId, type<SPlayer>)

    if (player != null) {
        return nodeId
    }

    if (nodeId.name == playerName) {
        return nodeId
    }

    let children = get_children(nodeId)

    for (child in children) {
        let found = game_ui_find_player_recursive(child, playerName)

        if (found != NodeId()) {
            return found
        }
    }

    return NodeId()
}


class SGameUI : Component {
    @export playerNode : NodeId = NodeId()
    @export playerName : string = "P_Player"
    @export canvasSize : float2 = float2(1920.0, 1080.0)
    @export showTipsOnStart : bool = false
    @export healthHolderTexturePath : string = "Project/Assets/UI/HealthtextHolder.png"
    @export coinsHolderTexturePath : string = "Project/Assets/UI/CoinsTextHolder.png"
    @export tipsHintTexturePath : string = "Project/Assets/UI/TipsHint.png"

    canvasNode : NodeId
    healthHolderNode : NodeId
    healthTextNode : NodeId
    coinsHolderNode : NodeId
    tipsHintNode : NodeId
    tipsPanelNode : NodeId
    tipsTextNode : NodeId
    coinsTextNode : NodeId

    tipsShown : bool = false
    layoutSize : float2 = float2(1920.0, 1080.0)

    def override on_initialize() : void {
        self->init_input()
        self->setup_canvas()
        self->create_hud()
        self->set_tips_visible(showTipsOnStart)
        self->find_player()
    }

    def override on_update() : void {
        if (is_action_just_pressed("toggleTips")) {
            self->set_tips_visible(!tipsShown)
        }

        if (playerNode == NodeId() || !playerNode.isAlive) {
            self->find_player()
        }

        if (self->refresh_layout_size()) {
            self->apply_hud_layout()
        }

        self->update_health()
        self->update_coins()
    }

    def override on_destroy() : void {
        pass
    }

    def private init_input() : void {
        if (has_action_set("gameUiInput")) {
            activate_action_set("gameUiInput", true)
            return
        }

        add_and_activate_action_set("gameUiInput", {
            "toggleTips" => Action(
                buttonActions = ButtonAction(
                    keyboardButtons = [KeyboardButtonInput(idx = KeyCode.F1)]
                )
            )
        })
    }

    def private setup_canvas() : void {
        self->remove_old_canvas()

        canvasNode = create_node(NodeData(name = "GameUICanvas", parent = nodeId))
        add_component(canvasNode, new UIFrame(size = canvasSize, pivot = float2(0.0, 0.0)))
        add_component(canvasNode, new UICanvas(screenMode = ScreenMode.FitExtend, size = canvasSize))
        layoutSize = canvasSize
        self->refresh_layout_size()
    }

    def private remove_old_canvas() : void {
        let children = get_children(nodeId)

        for (child in children) {
            if (child.name == "GameUICanvas") {
                remove_node(child)
            }
        }
    }

    def private create_hud() : void {
        healthHolderNode = self->create_image_node("HealthHolder", healthHolderTexturePath, canvasNode, float2(205.0, 54.0), float2(340.0, 87.0))
        healthTextNode = self->create_text_child("HealthText", healthHolderNode, float2(184.0, 43.0), float2(132.0, 38.0), "100 / 100", 23.0, float4(0.95, 0.98, 1.0, 1.0), TextHorAlignment.Center)

        coinsHolderNode = self->create_image_node("CoinsHolder", coinsHolderTexturePath, canvasNode, float2(layoutSize.x - 205.0, 54.0), float2(340.0, 87.0))
        coinsTextNode = self->create_text_child("CoinsText", coinsHolderNode, float2(184.0, 43.0), float2(132.0, 38.0), "0", 23.0, float4(0.95, 0.98, 1.0, 1.0), TextHorAlignment.Center)

        tipsHintNode = self->create_image_node("TipsHint", tipsHintTexturePath, canvasNode, float2(layoutSize.x - 248.0, 116.0), float2(286.0, 41.0))

        tipsPanelNode = create_node(NodeData(name = "TipsPanel", parent = canvasNode))
        add_component(tipsPanelNode, new UIFrame(size = float2(520.0, 260.0), pivot = float2(1.0, 0.0)))
        tipsPanelNode?.UIFrame.localPosition2D = float2(layoutSize.x - 32.0, 152.0)
        add_component(tipsPanelNode, new UIImage(
            color = float4(0.02, 0.04, 0.05, 0.86),
            size = float2(520.0, 260.0),
            pivot = float2(1.0, 0.0)
        ))

        tipsTextNode = self->create_text_child("TipsText", tipsPanelNode, float2(-260.0, 130.0), float2(472.0, 220.0), "Controls\n\nWASD - move\nMouse - aim\nLMB - attack\nSpace - dash\nRMB + mouse - rotate camera\nScroll - camera height\nF1 - hide tips", 24.0, float4(0.95, 0.98, 1.0, 1.0), TextHorAlignment.Left)
        get_component(tipsTextNode) $(var text : UIText?) {
            if (text != null) {
                text.wordWrapping = true
                text.vertAlignment = TextVertAlignment.Top
            }
        }

        self->apply_hud_layout()
    }

    def private refresh_layout_size() : bool {
        var newSize = canvasSize

        if (canvasNode != NodeId()) {
            get_component(canvasNode) $(var frame : UIFrame?) {
                if (frame != null && frame.size.x > 1.0 && frame.size.y > 1.0) {
                    newSize = frame.size
                }
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

    def private apply_hud_layout() : void {
        self->set_frame(healthHolderNode, float2(205.0, 54.0), float2(340.0, 87.0), float2(0.5, 0.5))
        self->set_frame(coinsHolderNode, float2(layoutSize.x - 205.0, 54.0), float2(340.0, 87.0), float2(0.5, 0.5))
        self->set_frame(tipsHintNode, float2(layoutSize.x - 248.0, 116.0), float2(286.0, 41.0), float2(0.5, 0.5))
        self->set_frame(tipsPanelNode, float2(layoutSize.x - 32.0, 152.0), float2(520.0, 260.0), float2(1.0, 0.0))
    }

    def private set_frame(n : NodeId, pos : float2, size : float2, pivot : float2) : void {
        if (n == NodeId()) {
            return
        }

        get_component(n) $(var frame : UIFrame?) {
            if (frame != null) {
                frame.size = size
                frame.pivot = pivot
                frame.localPosition2D = pos
            }
        }

        get_component(n) $(var image : UIImage?) {
            if (image != null) {
                image.size = size
                image.pivot = pivot
            }
        }
    }

    def private create_image_node(name : string, texturePath : string, parentNode : NodeId, pos : float2, size : float2) : NodeId {
        let n = create_node(NodeData(name = name, parent = parentNode))
        add_component(n, new UIFrame(size = size, pivot = float2(0.5, 0.5)))
        add_component(n, new UIImage(
            textureId = request_texture(texturePath),
            color = float4(1.0, 1.0, 1.0, 1.0),
            size = size,
            pivot = float2(0.5, 0.5)
        ))
        n?.UIFrame.size = size
        n?.UIFrame.pivot = float2(0.5, 0.5)
        n?.UIFrame.localPosition2D = pos
        return n
    }

    def private create_text_child(name : string, parentNode : NodeId, pos : float2, size : float2, value : string, fontSize : float, color : float4, alignment : TextHorAlignment) : NodeId {
        let n = create_node(NodeData(name = name, parent = parentNode))
        add_component(n, new UIFrame(size = size, pivot = float2(0.5, 0.5)))
        add_component(n, new UIText(
            text = value,
            color = color,
            fontSize = fontSize,
            fontScaling = false,
            autoResizeFrame = false,
            wordWrapping = false,
            pivot = float2(0.5, 0.5),
            horAlignment = alignment,
            vertAlignment = TextVertAlignment.Middle
        ))
        n?.UIFrame.size = size
        n?.UIFrame.pivot = float2(0.5, 0.5)
        n?.UIFrame.localPosition2D = pos
        return n
    }

    def private find_player() : void {
        let roots = get_scene_roots()

        for (root in roots) {
            let found = game_ui_find_player_recursive(root, playerName)

            if (found != NodeId()) {
                playerNode = found
                return
            }
        }
    }

    def private update_health() : void {
        var healthText = "100 / 100"

        if (playerNode != NodeId() && playerNode.isAlive) {
            var currentHealth = 100
            var maxHealth = 100

            get_component(playerNode) $(var damageable : SDamageable?) {
                if (damageable != null) {
                    currentHealth = int(damageable.health)
                    maxHealth = int(damageable.maxHealth)
                }
            }

            healthText = "{currentHealth} / {maxHealth}"
        }

        get_component(healthTextNode) $(var text : UIText?) {
            if (text != null) {
                text.text = healthText
            }
        }
    }

    def private update_coins() : void {
        var coinsText = "0"

        let saved = progress_get_saved_coins()
        coinsText = "{saved}"

        get_component(coinsTextNode) $(var text : UIText?) {
            if (text != null) {
                text.text = coinsText
            }
        }
    }

    def private set_tips_visible(value : bool) : void {
        tipsShown = value

        if (tipsPanelNode != NodeId()) {
            tipsPanelNode.isActive = tipsShown
        }
    }
}
