require engine.core
require engine.input_core
require engine.sound_core
require engine.math.math_utils
require Project.Core.Player.S_Player
require Project.Core.Player.S_CameraFollow
require Project.Mechanics.UIUX.S_GameUI
require Project.Mechanics.UIUX.S_HubIntro
require Project.Mechanics.UIUX.S_MusicPlaylist


def main_menu_find_node_recursive(nodeId : NodeId, nodeName : string) : NodeId {
    if ( nodeId.name == nodeName ) {
        return nodeId
    }

    let children = get_children(nodeId)
    for ( child in children ) {
        let found = main_menu_find_node_recursive(child, nodeName)
        if ( found != NodeId() ) {
            return found
        }
    }

    return NodeId()
}


var activeMainMenuMusicHandle : SoundHandle = INVALID_SOUND_HANDLE


class SMainMenu : Component {
    @export canvasSize : float2 = float2(1920.0, 1080.0)

    @export logoTexturePath : string = "Project/Assets/UI/Logos.png"
    @export startButtonTexturePath : string = "Project/Assets/UI/StartmenuButton.png"
    @export optionsButtonTexturePath : string = "Project/Assets/UI/OptionsMenuButton.png"
    @export exitButtonTexturePath : string = "Project/Assets/UI/ExitMenuButton.png"
    @export menuMusicPath : string = "Project/Assets/Music/PlayList/cybergaijin.mp3"
    @export menuMusicVolume : float = 0.65

    @export startLevelPath : string = "Project/Levels/Lvl_Hub.prefab"
    @export playerPrefabPath : string = "Project/Core/Player/P_Player.prefab"
    @export cameraPrefabPath : string = "Project/Core/Player/P_FollowCamera.prefab"
    @export playerSpawnNodeName : string = "PlayerSpawn"
    @export playerName : string = "P_Player"
    @export cameraName : string = "P_FollowCamera"
    @export fallbackSpawnPosition : float3 = float3(0.0, 1.0, 0.0)
    @export fallbackSpawnRotation : quat4 = quat4()
    @export cameraOffset : float3 = float3(0.0, 10.0, -5.0)

    @export menuTipsOnStart : bool = false

    canvasNode : NodeId
    menuRootNode : NodeId
    startButtonNode : NodeId
    settingsButtonNode : NodeId
    exitButtonNode : NodeId
    settingsPanelNode : NodeId
    musicValueNode : NodeId
    musicMinusButtonNode : NodeId
    musicPlusButtonNode : NodeId
    musicSliderTrackNode : NodeId
    musicSliderFillNode : NodeId
    musicSliderKnobNode : NodeId
    tipsToggleButtonNode : NodeId
    tipsValueNode : NodeId

    menuMusicHandle : SoundHandle = INVALID_SOUND_HANDLE
    currentMusicVolume : float = 0.65
    tipsOnStart : bool = false
    settingsShown : bool = false
    loadingStarted : bool = false
    musicStarted : bool = false
    volumeSliderDragging : bool = false
    previousMouseDown : bool = false

    def override on_initialize() : void {
        reset_hub_intro_once_flag()
        stop_gameplay_music(0.2)
        show_mouse_cursor(true)

        currentMusicVolume = clamp(menuMusicVolume, 0.0, 1.0)
        tipsOnStart = menuTipsOnStart
        settingsShown = false
        loadingStarted = false
        musicStarted = false

        self->disable_menu_lighting()
        self->ensure_ui_camera()
        self->setup_canvas()
        self->remove_old_menu_ui()
        self->build_menu()
        self->bind_buttons()
        self->refresh_settings_text()
    }

    def override on_update() : void {
        if ( !musicStarted ) {
            musicStarted = true
            self->play_menu_music()
        }

        self->update_volume_slider_drag()
    }

    def override on_destroy() : void {
        self->stop_menu_music(0.0)
    }

    def private ensure_ui_camera() : void {
        var hasActiveCamera = false

        for ( cam in find_components(type<Camera>) ) {
            if ( !hasActiveCamera ) {
                cam.nodeId.isActive = true
                hasActiveCamera = true
            } else {
                cam.nodeId.isActive = false
                print("MainMenu: disabled extra camera {cam.nodeId.hierarchyName}")
            }
        }

        if ( hasActiveCamera ) {
            return
        }

        let cameraNode = create_node(NodeData(name = "MainMenuCamera", parent = nodeId, position = float3(0.0, 0.0, -10.0)))
        add_component(cameraNode, new Camera())
    }

    def private disable_menu_lighting() : void {
        for ( light in find_components(type<DirectionLight>) ) {
            light.nodeId.isActive = false
            print("MainMenu: disabled directional light {light.nodeId.hierarchyName}")
        }

        for ( light in find_components(type<SpotLight>) ) {
            light.nodeId.isActive = false
            print("MainMenu: disabled spot light {light.nodeId.hierarchyName}")
        }
    }

    def private setup_canvas() : void {
        canvasNode = main_menu_find_node_recursive(nodeId, "canvas")
        if ( canvasNode == NodeId() ) {
            canvasNode = nodeId
        }

        var hasFrame = false
        get_component(canvasNode) $(var frame : UIFrame?) {
            if ( frame != null ) {
                hasFrame = true
                frame.size = canvasSize
                frame.pivot = float2(0.0, 0.0)
            }
        }
        if ( !hasFrame ) {
            add_component(canvasNode, new UIFrame(size = canvasSize, pivot = float2(0.0, 0.0)))
        }

        var hasCanvas = false
        get_component(canvasNode) $(var c : UICanvas?) {
            if ( c != null ) {
                hasCanvas = true
                c.screenMode = ScreenMode.FitExtend
                c.size = canvasSize
            }
        }
        if ( !hasCanvas ) {
            add_component(canvasNode, new UICanvas(screenMode = ScreenMode.FitExtend, size = canvasSize))
        }
    }

    def private remove_old_menu_ui() : void {
        let oldRoot = main_menu_find_node_recursive(canvasNode, "MainMenuRoot")
        if ( oldRoot != NodeId() ) {
            remove_node(oldRoot)
        }

        let oldBlackout = main_menu_find_node_recursive(canvasNode, "MainMenuBlackout")
        if ( oldBlackout != NodeId() ) {
            remove_node(oldBlackout)
        }
    }

    def private build_menu() : void {
        let center = float2(canvasSize.x * 0.5, canvasSize.y * 0.5)
        let blackoutSize = float2(canvasSize.x + 900.0, canvasSize.y + 700.0)

        let blackoutNode = create_node(NodeData(name = "MainMenuBlackout", parent = canvasNode))
        add_component(blackoutNode, new UIFrame(size = blackoutSize, pivot = float2(0.5, 0.5)))
        blackoutNode?.UIFrame.localPosition2D = center
        add_component(blackoutNode, new UIImage(
            color = float4(0.0, 0.0, 0.0, 1.0),
            size = blackoutSize,
            pivot = float2(0.5, 0.5)
        ))

        menuRootNode = create_node(NodeData(name = "MainMenuRoot", parent = canvasNode))
        add_component(menuRootNode, new UIFrame(size = canvasSize, pivot = float2(0.0, 0.0)))
        menuRootNode?.UIFrame.localPosition2D = float2(0.0, 0.0)

        add_component(menuRootNode, new UIImage(
            textureId = request_texture(logoTexturePath),
            color = float4(1.0, 1.0, 1.0, 1.0),
            size = canvasSize,
            pivot = float2(0.0, 0.0)
        ))

        startButtonNode = self->create_image_button_node("StartButton", startButtonTexturePath, menuRootNode, float2(1680.0, 390.0), float2(410.0, 155.0))
        settingsButtonNode = self->create_image_button_node("SettingsButton", optionsButtonTexturePath, menuRootNode, float2(1680.0, 555.0), float2(410.0, 155.0))
        exitButtonNode = self->create_image_button_node("ExitButton", exitButtonTexturePath, menuRootNode, float2(1680.0, 720.0), float2(410.0, 155.0))

        self->create_settings_panel()
    }

    def private create_image_button_node(name : string, texturePath : string, parentNode : NodeId, pos : float2, size : float2) : NodeId {
        let n = create_node(NodeData(name = name, parent = parentNode))
        add_component(n, new UIFrame(size = size, pivot = float2(0.5, 0.5)))

        add_component(n, new UIImage(
            textureId = request_texture(texturePath),
            color = float4(1.0, 1.0, 1.0, 1.0),
            size = size,
            pivot = float2(0.5, 0.5)
        ))
        add_component(n, new UIButton())
        n?.UIFrame.size = size
        n?.UIFrame.pivot = float2(0.5, 0.5)
        n?.UIFrame.localPosition2D = pos

        return n
    }

    def private create_button_node(name : string, buttonText : string, parentNode : NodeId, pos : float2, size : float2) : NodeId {
        let n = create_node(NodeData(name = name, parent = parentNode))
        add_component(n, new UIFrame(size = size, pivot = float2(0.5, 0.5)))

        add_component(n, new UIImage(
            color = float4(0.03, 0.08, 0.11, 0.92),
            size = size,
            pivot = float2(0.5, 0.5)
        ))
        add_component(n, new UIButton())
        add_component(n, new UIText(
            text = buttonText,
            color = float4(0.95, 0.98, 1.0, 1.0),
            fontSize = 28.0,
            wordWrapping = false,
            pivot = float2(0.5, 0.5),
            horAlignment = TextHorAlignment.Center,
            vertAlignment = TextVertAlignment.Middle
        ))
        n?.UIFrame.size = size
        n?.UIFrame.pivot = float2(0.5, 0.5)
        n?.UIFrame.localPosition2D = pos

        return n
    }

    def private create_text_node(name : string, textValue : string, parentNode : NodeId, pos : float2, size : float2, fontSize : float, color : float4) : NodeId {
        let n = create_node(NodeData(name = name, parent = parentNode))
        add_component(n, new UIFrame(size = size, pivot = float2(0.5, 0.5)))
        add_component(n, new UIText(
            text = textValue,
            color = color,
            fontSize = fontSize,
            fontScaling = false,
            autoResizeFrame = false,
            wordWrapping = false,
            pivot = float2(0.5, 0.5),
            horAlignment = TextHorAlignment.Center,
            vertAlignment = TextVertAlignment.Middle
        ))
        n?.UIFrame.size = size
        n?.UIFrame.pivot = float2(0.5, 0.5)
        n?.UIFrame.localPosition2D = pos
        return n
    }

    def private create_solid_node(name : string, parentNode : NodeId, pos : float2, size : float2, pivot : float2, color : float4) : NodeId {
        let n = create_node(NodeData(name = name, parent = parentNode))
        add_component(n, new UIFrame(size = size, pivot = pivot))
        add_component(n, new UIImage(
            color = color,
            size = size,
            pivot = pivot
        ))
        n?.UIFrame.size = size
        n?.UIFrame.pivot = pivot
        n?.UIFrame.localPosition2D = pos
        return n
    }

    def private bind_buttons() : void {
        get_component(startButtonNode) $(var btn : UIButton?) {
            if ( btn != null ) {
                btn.onClick = @() {
                    self->on_start_clicked()
                }
            }
        }

        get_component(exitButtonNode) $(var btn : UIButton?) {
            if ( btn != null ) {
                btn.onClick = @() {
                    self->on_exit_clicked()
                }
            }
        }

        get_component(settingsButtonNode) $(var btn : UIButton?) {
            if ( btn != null ) {
                btn.onClick = @() {
                    self->toggle_settings()
                }
            }
        }

        get_component(musicMinusButtonNode) $(var btn : UIButton?) {
            if ( btn != null ) {
                btn.onClick = @() {
                    self->change_music_volume(-0.1)
                }
            }
        }

        get_component(musicPlusButtonNode) $(var btn : UIButton?) {
            if ( btn != null ) {
                btn.onClick = @() {
                    self->change_music_volume(0.1)
                }
            }
        }

        get_component(tipsToggleButtonNode) $(var btn : UIButton?) {
            if ( btn != null ) {
                btn.onClick = @() {
                    self->toggle_tips_on_start()
                }
            }
        }
    }

    def private create_settings_panel() : void {
        settingsPanelNode = create_node(NodeData(name = "SettingsPanel", parent = menuRootNode))
        add_component(settingsPanelNode, new UIFrame(size = float2(500.0, 260.0), pivot = float2(0.5, 0.0)))
        settingsPanelNode?.UIFrame.localPosition2D = float2(1680.0, 800.0)

        add_component(settingsPanelNode, new UIImage(
            color = float4(0.04, 0.06, 0.075, 0.92),
            size = float2(500.0, 260.0),
            pivot = float2(0.5, 0.0)
        ))

        self->create_text_node("MusicLabel", "MUSIC VOLUME", settingsPanelNode, float2(0.0, 34.0), float2(360.0, 34.0), 23.0, float4(0.9, 0.96, 1.0, 1.0))

        musicMinusButtonNode = self->create_button_node("MusicMinusButton", "-", settingsPanelNode, float2(-205.0, 88.0), float2(48.0, 48.0))
        musicPlusButtonNode = self->create_button_node("MusicPlusButton", "+", settingsPanelNode, float2(205.0, 88.0), float2(48.0, 48.0))

        musicSliderTrackNode = self->create_solid_node("MusicSliderTrack", settingsPanelNode, float2(0.0, 88.0), float2(300.0, 12.0), float2(0.5, 0.5), float4(0.22, 0.26, 0.29, 1.0))
        musicSliderFillNode = self->create_solid_node("MusicSliderFill", settingsPanelNode, float2(-150.0, 88.0), float2(195.0, 12.0), float2(0.0, 0.5), float4(0.47, 0.74, 0.80, 1.0))
        musicSliderKnobNode = self->create_solid_node("MusicSliderKnob", settingsPanelNode, float2(45.0, 88.0), float2(22.0, 38.0), float2(0.5, 0.5), float4(0.94, 0.98, 1.0, 1.0))

        musicValueNode = self->create_text_node("MusicValueText", "", settingsPanelNode, float2(0.0, 128.0), float2(160.0, 36.0), 24.0, float4(0.95, 0.98, 1.0, 1.0))

        self->create_text_node("TipsLabel", "SHOW TIPS", settingsPanelNode, float2(-70.0, 185.0), float2(190.0, 38.0), 22.0, float4(0.9, 0.96, 1.0, 1.0))
        tipsToggleButtonNode = self->create_button_node("TipsToggleButton", "", settingsPanelNode, float2(150.0, 185.0), float2(150.0, 50.0))
        tipsValueNode = self->create_text_node("TipsToggleText", "", tipsToggleButtonNode, float2(0.0, 0.0), float2(130.0, 34.0), 22.0, float4(0.95, 0.98, 1.0, 1.0))

        settingsPanelNode.isActive = false
    }

    def private play_menu_music() : void {
        self->stop_menu_music(0.0)

        if ( length(menuMusicPath) == 0 ) {
            return
        }

        let sid = request_sound(menuMusicPath)
        menuMusicHandle = play_sound_loop(sid)
        activeMainMenuMusicHandle = menuMusicHandle
        set_volume(menuMusicHandle, currentMusicVolume)
    }

    def private stop_menu_music(fadeTime : float) : void {
        if ( menuMusicHandle != INVALID_SOUND_HANDLE && is_playing(menuMusicHandle) ) {
            stop(menuMusicHandle, fadeTime)
        }

        if ( activeMainMenuMusicHandle != INVALID_SOUND_HANDLE && activeMainMenuMusicHandle != menuMusicHandle && is_playing(activeMainMenuMusicHandle) ) {
            stop(activeMainMenuMusicHandle, fadeTime)
        }

        menuMusicHandle = INVALID_SOUND_HANDLE
        activeMainMenuMusicHandle = INVALID_SOUND_HANDLE
    }

    def private toggle_settings() : void {
        settingsShown = !settingsShown
        if ( settingsPanelNode != NodeId() ) {
            settingsPanelNode.isActive = settingsShown
        }
    }

    def private change_music_volume(delta : float) : void {
        self->set_music_volume(currentMusicVolume + delta)
    }

    def private set_music_volume(value : float) : void {
        currentMusicVolume = clamp(value, 0.0, 1.0)
        menuMusicVolume = currentMusicVolume

        if ( menuMusicHandle != INVALID_SOUND_HANDLE && is_playing(menuMusicHandle) ) {
            set_volume(menuMusicHandle, currentMusicVolume)
        }

        self->refresh_settings_text()
    }

    def private toggle_tips_on_start() : void {
        tipsOnStart = !tipsOnStart
        menuTipsOnStart = tipsOnStart
        self->refresh_settings_text()
    }

    def private refresh_settings_text() : void {
        let volPercent = int(currentMusicVolume * 100.0 + 0.5)
        self->set_text(musicValueNode, "{volPercent}%")
        self->set_text(tipsValueNode, (tipsOnStart ? "ON" : "OFF"))

        let trackWidth = 300.0
        let fillWidth = trackWidth * currentMusicVolume

        self->set_node_size(musicSliderFillNode, float2(fillWidth, 12.0))
        self->set_node_pos(musicSliderKnobNode, float2(-150.0 + fillWidth, 88.0))
    }

    def private set_text(textNode : NodeId, value : string) : void {
        if ( textNode == NodeId() ) {
            return
        }

        get_component(textNode) $(var text : UIText?) {
            if ( text != null ) {
                text.text = value
            }
        }
    }

    def private set_node_pos(n : NodeId, pos : float2) : void {
        if ( n == NodeId() ) {
            return
        }

        get_component(n) $(var frame : UIFrame?) {
            if ( frame != null ) {
                frame.localPosition2D = pos
            }
        }
    }

    def private set_node_size(n : NodeId, size : float2) : void {
        if ( n == NodeId() ) {
            return
        }

        get_component(n) $(var frame : UIFrame?) {
            if ( frame != null ) {
                frame.size = size
            }
        }

        get_component(n) $(var image : UIImage?) {
            if ( image != null ) {
                image.size = size
            }
        }
    }

    def private get_frame_pos(n : NodeId) : float2 {
        var result = float2(0.0, 0.0)

        get_component(n) $(var frame : UIFrame?) {
            if ( frame != null ) {
                result = frame.localPosition2D
            }
        }

        return result
    }

    def private update_volume_slider_drag() : void {
        if ( !settingsShown || musicSliderTrackNode == NodeId() ) {
            volumeSliderDragging = false
            previousMouseDown = false
            return
        }

        let mouseDown = is_any_mouse_button_pressed()
        if ( !mouseDown ) {
            volumeSliderDragging = false
            previousMouseDown = false
            return
        }

        let uiMouse = get_ui_mouse_position(musicSliderTrackNode)
        let mouseCanvas = float2(uiMouse.x + canvasSize.x * 0.5, uiMouse.y + canvasSize.y * 0.5)
        let panelPos = self->get_frame_pos(settingsPanelNode)
        let trackLocalPos = self->get_frame_pos(musicSliderTrackNode)
        let trackCenter = float2(panelPos.x + trackLocalPos.x, panelPos.y + trackLocalPos.y)
        let trackWidth = 300.0
        let halfWidth = trackWidth * 0.5
        let halfHeight = 28.0

        let inside = mouseCanvas.x >= trackCenter.x - halfWidth && mouseCanvas.x <= trackCenter.x + halfWidth && mouseCanvas.y >= trackCenter.y - halfHeight && mouseCanvas.y <= trackCenter.y + halfHeight

        if ( !previousMouseDown ) {
            volumeSliderDragging = inside
        }

        if ( volumeSliderDragging ) {
            let volume = clamp((mouseCanvas.x - (trackCenter.x - halfWidth)) / trackWidth, 0.0, 1.0)
            self->set_music_volume(volume)
        }

        previousMouseDown = mouseDown
    }

    def private on_exit_clicked() : void {
        terminate()
    }

    def private on_start_clicked() : void {
        if ( loadingStarted ) {
            return
        }

        loadingStarted = true
        self->stop_menu_music(0.0)
        self->start_game_scene()
    }

    def private start_game_scene() : void {
        let levelPrefab = request_prefab(startLevelPath)
        let playerPrefab = request_prefab(playerPrefabPath)
        let cameraPrefab = request_prefab(cameraPrefabPath)

        if ( levelPrefab == PrefabId() || playerPrefab == PrefabId() || cameraPrefab == PrefabId() ) {
            print("MainMenu: one or more prefabs were not found")
            loadingStarted = false
            return
        }

        var spawnPosition = fallbackSpawnPosition
        var spawnRotation = fallbackSpawnRotation

        clear_scene()

        let levelNode = instantiate_prefab(levelPrefab, NodeData(name = "Lvl_Hub"))
        if ( levelNode != NodeId() && length(playerSpawnNodeName) > 0 ) {
            let spawnNode = main_menu_find_node_recursive(levelNode, playerSpawnNodeName)
            if ( spawnNode != NodeId() ) {
                spawnPosition = spawnNode.worldPosition
                spawnRotation = spawnNode.worldRotation
                print("MainMenu: player spawn node found: {spawnNode.hierarchyName}")
            } else {
                print("MainMenu: spawn node not found: {playerSpawnNodeName}, using fallback")
            }
        }

        if ( levelNode != NodeId() ) {
            var hasHubIntro = false
            get_component(levelNode) $(var hubIntro : SHubIntro?) {
                if ( hubIntro != null ) {
                    hasHubIntro = true
                    hubIntro.introMusicVolume = currentMusicVolume
                }
            }

            if ( !hasHubIntro ) {
                add_component(levelNode, new SHubIntro(introMusicVolume = currentMusicVolume))
            }
        }

        let newCamera = instantiate_prefab(cameraPrefab, NodeData(
            name = cameraName,
            position = spawnPosition + cameraOffset
        ))

        let newPlayer = instantiate_prefab(playerPrefab, NodeData(
            name = playerName,
            position = spawnPosition,
            rotation = spawnRotation
        ))

        get_component(newCamera) $(var follow : SCameraFollow?) {
            if ( follow != null ) {
                follow.target = newPlayer
                follow.offset = cameraOffset
                follow.offset.y = clamp(follow.offset.y, follow.minCameraHeight, follow.maxCameraHeight)
                follow.yaw = 0.0
                follow.targetYaw = 0.0
            }
        }

        self->assign_camera_to_player(newPlayer, newCamera)

        let uiNode = create_node(NodeData(name = "GameUI"))
        add_component(uiNode, new SGameUI(playerNode = newPlayer, showTipsOnStart = tipsOnStart))
    }

    def private assign_camera_to_player(playerNode : NodeId, cameraRoot : NodeId) : void {
        var cameraComponent : Camera?

        get_component(cameraRoot) $(var cam : Camera?) {
            if ( cam != null ) {
                cameraComponent = cam
            }
        }

        if ( cameraComponent == null ) {
            let children = get_children(cameraRoot)
            for ( child in children ) {
                get_component(child) $(var cam : Camera?) {
                    if ( cam != null ) {
                        cameraComponent = cam
                    }
                }
            }
        }

        if ( cameraComponent != null ) {
            get_component(playerNode) $(var player : SPlayer?) {
                if ( player != null ) {
                    player.camera = cameraComponent
                }
            }
        }
    }

}
