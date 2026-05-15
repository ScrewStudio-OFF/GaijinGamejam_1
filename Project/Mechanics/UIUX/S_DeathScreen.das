require engine.core
require Project.Mechanics.UIUX.S_MusicPlaylist


var playerDeathScreenActive : bool = false


class SDeathScreen : Component {
    @export canvasSize : float2 = float2(1920.0, 1080.0)
    @export imageSourceSize : float2 = float2(1920.0, 1080.0)
    @export deathImagePath : string = "Project/Assets/UI/Refined.png"
    @export mainMenuPrefabPath : string = "Project/Levels/Lvl_Main.prefab"
    @export delaySeconds : float = 5.0

    canvasNode : NodeId
    blackoutNode : NodeId
    imageNode : NodeId
    layoutSize : float2 = float2(1920.0, 1080.0)
    timer : float = 0.0
    returningToMenu : bool = false

    def override on_initialize() : void {
        playerDeathScreenActive = true
        stop_gameplay_music(0.35)
        timer = 0.0
        returningToMenu = false
        self->create_screen()
    }

    def override on_update() : void {
        if (returningToMenu) {
            return
        }

        if (self->refresh_layout_size()) {
            self->apply_screen_layout()
        }

        timer += get_delta_time()
        if (timer >= delaySeconds) {
            self->return_to_main_menu()
        }
    }

    def override on_destroy() : void {
        playerDeathScreenActive = false
    }

    def private create_screen() : void {
        canvasNode = create_node(NodeData(name = "DeathScreenCanvas", parent = nodeId))
        add_component(canvasNode, new UIFrame(size = canvasSize, pivot = float2(0.0, 0.0)))
        add_component(canvasNode, new UICanvas(screenMode = ScreenMode.FitExtend, size = canvasSize))
        layoutSize = canvasSize
        self->refresh_layout_size()

        blackoutNode = create_node(NodeData(name = "DeathScreenBlackout", parent = canvasNode))
        add_component(blackoutNode, new UIFrame(size = layoutSize, pivot = float2(0.0, 0.0)))
        add_component(blackoutNode, new UIImage(
            color = float4(0.0, 0.0, 0.0, 1.0),
            size = layoutSize,
            pivot = float2(0.0, 0.0)
        ))
        blackoutNode?.UIFrame.localPosition2D = float2(0.0, 0.0)

        imageNode = create_node(NodeData(name = "DeathScreenImage", parent = canvasNode))
        let coverSize = self->get_cover_image_size(layoutSize)
        add_component(imageNode, new UIFrame(size = coverSize, pivot = float2(0.5, 0.5)))
        add_component(imageNode, new UIImage(
            textureId = request_texture(deathImagePath),
            color = float4(1.0, 1.0, 1.0, 1.0),
            size = coverSize,
            pivot = float2(0.5, 0.5)
        ))
        imageNode?.UIFrame.localPosition2D = layoutSize * 0.5

        self->apply_screen_layout()
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

    def private apply_screen_layout() : void {
        self->set_overlay_frame(blackoutNode, float2(0.0, 0.0), layoutSize, float2(0.0, 0.0))
        self->set_overlay_frame(imageNode, layoutSize * 0.5, self->get_cover_image_size(layoutSize), float2(0.5, 0.5))
    }

    def private get_cover_image_size(screenSize : float2) : float2 {
        var result = screenSize

        let imageAspect = imageSourceSize.x / imageSourceSize.y
        let screenAspect = screenSize.x / screenSize.y

        if (screenAspect > imageAspect) {
            result.x = screenSize.x
            result.y = screenSize.x / imageAspect
        } else {
            result.y = screenSize.y
            result.x = screenSize.y * imageAspect
        }

        return result
    }

    def private set_overlay_frame(n : NodeId, pos : float2, size : float2, pivot : float2) : void {
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

    def private return_to_main_menu() : void {
        returningToMenu = true
        playerDeathScreenActive = false

        let mainMenuPrefab = request_prefab(mainMenuPrefabPath)
        if (mainMenuPrefab == PrefabId()) {
            print("DeathScreen: main menu prefab not found: {mainMenuPrefabPath}")
            returningToMenu = false
            playerDeathScreenActive = true
            return
        }

        clear_scene()
        instantiate_prefab(mainMenuPrefab, NodeData(name = "Lvl_Main"))
    }
}


def show_player_death_screen(deathImagePath : string = "Project/Assets/UI/Refined.png", mainMenuPrefabPath : string = "Project/Levels/Lvl_Main.prefab", delaySeconds : float = 5.0) : void {
    if (playerDeathScreenActive) {
        return
    }

    let deathNode = create_node(NodeData(name = "PlayerDeathScreen"))
    add_component(deathNode, new SDeathScreen(
        deathImagePath = deathImagePath,
        mainMenuPrefabPath = mainMenuPrefabPath,
        delaySeconds = delaySeconds,
        imageSourceSize = float2(1920.0, 1080.0)
    ))
}
