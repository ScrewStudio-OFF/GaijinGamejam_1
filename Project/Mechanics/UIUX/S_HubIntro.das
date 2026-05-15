require engine.core
require Project.Mechanics.UIUX.IntroController
require Project.Mechanics.UIUX.S_MusicPlaylist


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
    playlistStarted : bool = false

    def override on_initialize() : void {
        if ( hubIntroWasPlayed || introStarted ) {
            self->start_gameplay_playlist()
            return
        }

        hubIntroWasPlayed = true
        introStarted = true
        stop_gameplay_music(0.2)
        self->start_intro()
    }

    def override on_update() : void {
        if ( playlistStarted ) {
            return
        }

        if ( introStarted && introController != null && introController.introFinished ) {
            self->start_gameplay_playlist()
        }
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

    def private start_gameplay_playlist() : void {
        if ( playlistStarted ) {
            return
        }

        playlistStarted = true
        ensure_gameplay_music_playlist(self.playlistFolder, self.introMusicVolume)
    }
}
