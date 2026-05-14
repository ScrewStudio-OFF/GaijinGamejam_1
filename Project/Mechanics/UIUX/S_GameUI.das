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

    canvasNode : NodeId
    healthTextNode : NodeId
    tipsHintNode : NodeId
    tipsPanelNode : NodeId
    tipsTextNode : NodeId
    coinsTextNode : NodeId

    tipsShown : bool = false

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
        canvasNode = create_node(NodeData(name = "GameUICanvas", parent = nodeId))
        add_component(canvasNode, new UIFrame(size = canvasSize, pivot = float2(0.0, 0.0)))
        add_component(canvasNode, new UICanvas(screenMode = ScreenMode.FitExtend, size = canvasSize))
    }

    def private create_hud() : void {
        healthTextNode = create_node(NodeData(name = "HealthText", parent = canvasNode))
        add_component(healthTextNode, new UIText(
            text = "HP: 100 / 100",
            color = float4(0.95, 0.98, 1.0, 1.0),
            fontSize = 30.0,
            wordWrapping = false,
            pivot = float2(0.0, 0.0),
            horAlignment = TextHorAlignment.Left,
            vertAlignment = TextVertAlignment.Top
        ))
        healthTextNode?.UIFrame.localPosition2D = float2(32.0, 26.0)
        healthTextNode?.UIFrame.size = float2(360.0, 52.0)

        coinsTextNode = create_node(NodeData(name = "CoinsText", parent = canvasNode))
        add_component(coinsTextNode, new UIText(
            text = "Coins: 0",
            color = float4(0.95, 0.92, 0.3, 1.0),
            fontSize = 28.0,
            wordWrapping = false,
            pivot = float2(1.0, 0.0),
            horAlignment = TextHorAlignment.Right,
            vertAlignment = TextVertAlignment.Top
        ))
        coinsTextNode?.UIFrame.localPosition2D = float2(1840.0, 26.0)
        coinsTextNode?.UIFrame.size = float2(240.0, 48.0)

        tipsHintNode = create_node(NodeData(name = "TipsHint", parent = canvasNode))
        add_component(tipsHintNode, new UIText(
            text = "F1 - tips",
            color = float4(0.82, 0.92, 1.0, 0.95),
            fontSize = 24.0,
            wordWrapping = false,
            pivot = float2(1.0, 0.0),
            horAlignment = TextHorAlignment.Right,
            vertAlignment = TextVertAlignment.Top
        ))
        tipsHintNode?.UIFrame.localPosition2D = float2(1888.0, 28.0)
        tipsHintNode?.UIFrame.size = float2(220.0, 44.0)

        tipsPanelNode = create_node(NodeData(name = "TipsPanel", parent = canvasNode))
        add_component(tipsPanelNode, new UIImage(
            color = float4(0.02, 0.04, 0.05, 0.82),
            size = float2(520.0, 260.0),
            pivot = float2(1.0, 0.0)
        ))
        tipsPanelNode?.UIFrame.localPosition2D = float2(1888.0, 82.0)

        tipsTextNode = create_node(NodeData(name = "TipsText", parent = tipsPanelNode))
        add_component(tipsTextNode, new UIText(
            text = "Controls\n\nWASD - move\nMouse - aim\nLMB - attack\nSpace - dash\nRMB + mouse - rotate camera\nF1 - hide tips",
            color = float4(0.95, 0.98, 1.0, 1.0),
            fontSize = 24.0,
            wordWrapping = true,
            pivot = float2(0.0, 0.0),
            horAlignment = TextHorAlignment.Left,
            vertAlignment = TextVertAlignment.Top
        ))
        tipsTextNode?.UIFrame.localPosition2D = float2(24.0, 20.0)
        tipsTextNode?.UIFrame.size = float2(472.0, 220.0)
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
        var healthText = "HP: 100 / 100"

        if (playerNode != NodeId() && playerNode.isAlive) {
            get_component(playerNode) $(var damageable : SDamageable?) {
                if (damageable != null) {
                    healthText = "HP: {int(damageable.health)} / {int(damageable.maxHealth)}"
                }
            }
        }

        get_component(healthTextNode) $(var text : UIText?) {
            if (text != null) {
                text.text = healthText
            }
        }
    }

    def private update_coins() : void {
        var coinsText = "Coins: 0"

        let saved = progress_get_saved_coins()
        coinsText = "Coins: {saved}"

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
