require engine.core
require Project.Mechanics.UIUX.IntroController
require Project.Mechanics.UIUX.S_IntroMusicPlaylist


class SLevelIntroController : Component {
    @export canvasSize : float2 = float2(1920.0, 1080.0)
    @export introTrack1 : string = "Project/Assets/Music/1st scene.mp3"
    @export introTrack2 : string = ""
    @export introTrack3 : string = ""
    @export introMusicVolume : float = 0.65
    @export showIntroButton : bool = true

    canvasNode : NodeId
    introButtonNode : NodeId
    introControllerNode : NodeId
    introController : IntroController?
    introActive : bool = false

    def override on_initialize() : void {
        self->setup_ui()
    }

    def override on_update() : void {
        pass
    }

    def override on_destroy() : void {
        if ( introController != null ) {
            introController->finishIntro()
        }
    }

    def private setup_ui() : void {
        // Find or create canvas
        canvasNode = find_component(type<UICanvas>)?.nodeId ?? NodeId()
        if ( canvasNode == NodeId() ) {
            canvasNode = create_node(NodeData(name = "LevelUICanvas"))
            add_component(canvasNode, new UIFrame(size = canvasSize, pivot = float2(0.0, 0.0)))
            add_component(canvasNode, new UICanvas(screenMode = ScreenMode.FitExtend, size = canvasSize))
        }

        if ( showIntroButton ) {
            introButtonNode = self->create_intro_button()
        }
    }

    def private create_intro_button() : NodeId {
        let btn = create_node(NodeData(name = "IntroButton", parent = canvasNode))
        add_component(btn, new UIFrame(size = float2(200.0, 60.0), pivot = float2(0.5, 0.5)))
        btn?.UIFrame.localPosition2D = float2(1800.0, 100.0)

        add_component(btn, new UIImage(
            color = float4(0.2, 0.4, 0.8, 0.9),
            size = float2(200.0, 60.0),
            pivot = float2(0.5, 0.5)
        ))

        add_component(btn, new UIButton())
        
        add_component(btn, new UIText(
            text = "Story",
            color = float4(1.0, 1.0, 1.0, 1.0),
            fontSize = 24.0,
            wordWrapping = false,
            pivot = float2(0.5, 0.5),
            horAlignment = TextHorAlignment.Center,
            vertAlignment = TextVertAlignment.Middle
        ))

        get_component(btn) $(var uiBtn : UIButton?) {
            if ( uiBtn != null ) {
                uiBtn.onClick = @() {
                    self->on_intro_button_clicked()
                }
            }
        }

        return btn
    }

    def private on_intro_button_clicked() : void {
        if ( introActive || introController != null ) {
            return
        }

        introActive = true

        // Hide intro button
        if ( introButtonNode != NodeId() ) {
            introButtonNode.isActive = false
        }

        // Create intro
        introControllerNode = create_node(NodeData(name = "LevelIntroUI"))
        introController = add_component(introControllerNode, new IntroController())

        add_component(introControllerNode, new SIntroMusicPlaylist(
            introNode = introControllerNode,
            track1 = introTrack1,
            track2 = introTrack2,
            track3 = introTrack3,
            volume = introMusicVolume
        ))

        if ( introController == null ) {
            print("LevelIntroController: failed to create IntroController")
            introActive = false
        }
    }
}
