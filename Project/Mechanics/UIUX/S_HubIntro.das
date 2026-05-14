require engine.core
require Project.Mechanics.UIUX.IntroController


var hubIntroWasPlayed : bool = false


def reset_hub_intro_once_flag() : void {
    hubIntroWasPlayed = false
}


class SHubIntro : Component {
    @export canvasSize : float2 = float2(1920.0, 1080.0)
    @export introMusicPath : string = "Project/Assets/Music/1st scene.mp3"
    @export playlistFolder : string = "Project/Assets/Music/PlayList"
    @export introTrack1File : string = ""
    @export introTrack2File : string = ""
    @export introTrack3File : string = ""
    @export introMusicVolume : float = 0.65

    introControllerNode : NodeId
    introController : IntroController?
    introStarted : bool = false

    def override on_initialize() : void {
        if ( hubIntroWasPlayed || introStarted ) {
            return
        }

        hubIntroWasPlayed = true
        introStarted = true
        self->start_intro()
    }

    def override on_update() : void {
        pass
    }

    def override on_destroy() : void {
        if ( introController != null ) {
            introController->finishIntro()
        }
    }

    def private start_intro() : void {
        introControllerNode = create_node(NodeData(name = "HubIntroUI"))

        introController = add_component(introControllerNode, new IntroController(
            canvasSize = self.canvasSize,
            introMusicPath = self.introMusicPath,
            introMusicVolume = self.introMusicVolume
        ))

        if ( introController == null ) {
            hubIntroWasPlayed = false
            print("HubIntro: failed to create IntroController")
        }
    }
}
