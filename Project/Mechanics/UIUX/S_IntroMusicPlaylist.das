require engine.core
require engine.sound_core
require Project.Mechanics.UIUX.IntroController


var activeIntroPlaylistHandle : SoundHandle = INVALID_SOUND_HANDLE


class SIntroMusicPlaylist : Component {
    @export introNode : NodeId = NodeId()
    @export playlistFolder : string = "Project/Assets/Music/PlayList"
    @export track1File : string = "cybergaijin.mp3"
    @export track2File : string = ""
    @export track3File : string = ""
    @export track1 : string = ""
    @export track2 : string = ""
    @export track3 : string = ""
    @export volume : float = 0.55
    @export fadeTime : float = 0.35
    @export syncWithStoryFrames : bool = true

    intro : IntroController?
    activeTrackIndex : int = -1
    activeHandle : SoundHandle = INVALID_SOUND_HANDLE

    def override on_initialize() : void {
        self->resolve_intro()
        self->ensure_track(0)
    }

    def override on_update() : void {
        if ( intro == null ) {
            self->resolve_intro()
            self->ensure_track(0)
            return
        }

        if ( intro.introFinished ) {
            self->stop_active_track()
            return
        }

        if ( syncWithStoryFrames ) {
            let frame = self->get_story_frame(intro.time)
            let nextTrack = self->track_for_frame(frame)
            self->ensure_track(nextTrack)
        } elif ( activeHandle == INVALID_SOUND_HANDLE || !is_playing(activeHandle) ) {
            self->ensure_track(0)
        }
    }

    def override on_destroy() : void {
        self->stop_active_track()
    }

    def private resolve_intro() : void {
        if ( introNode != NodeId() && introNode.isAlive ) {
            get_component(introNode) $(var c : IntroController?) {
                intro = c
            }
            return
        }

        intro = find_component(type<IntroController>)
    }

    def private get_story_frame(t : float) : int {
        if ( t < 9.0 ) {
            return 0
        } elif ( t < 14.0 ) {
            return 1
        } elif ( t < 19.0 ) {
            return 2
        } elif ( t < 25.0 ) {
            return 3
        } elif ( t < 29.0 ) {
            return 4
        }

        return 5
    }

    def private track_for_frame(frame : int) : int {
        if ( frame <= 1 ) {
            return 0
        }

        if ( frame <= 3 ) {
            if ( length(track2) > 0 ) {
                return 1
            }
            return 0
        }

        if ( length(track3) > 0 ) {
            return 2
        }
        if ( length(track2) > 0 ) {
            return 1
        }
        return 0
    }

    def private get_track_path(idx : int) : string {
        if ( idx == 0 ) {
            return self->resolve_track_path(track1, track1File)
        } elif ( idx == 1 ) {
            return self->resolve_track_path(track2, track2File)
        } elif ( idx == 2 ) {
            return self->resolve_track_path(track3, track3File)
        }

        return ""
    }

    def private resolve_track_path(path : string, fileName : string) : string {
        if ( length(path) > 0 ) {
            return path
        }

        if ( length(fileName) > 0 ) {
            return "{playlistFolder}/{fileName}"
        }

        return ""
    }

    def private stop_active_track() : void {
        if ( activeHandle != INVALID_SOUND_HANDLE && is_playing(activeHandle) ) {
            stop(activeHandle, fadeTime)
        }

        if ( activeIntroPlaylistHandle == activeHandle ) {
            activeIntroPlaylistHandle = INVALID_SOUND_HANDLE
        }

        activeHandle = INVALID_SOUND_HANDLE
        activeTrackIndex = -1
    }

    def private ensure_track(idx : int) : void {
        if ( idx == activeTrackIndex && activeHandle != INVALID_SOUND_HANDLE && is_playing(activeHandle) ) {
            set_volume(activeHandle, volume)
            return
        }

        let path = self->get_track_path(idx)
        if ( length(path) == 0 ) {
            return
        }

        self->stop_active_track()

        if ( activeIntroPlaylistHandle != INVALID_SOUND_HANDLE && is_playing(activeIntroPlaylistHandle) ) {
            stop(activeIntroPlaylistHandle, fadeTime)
        }

        let sid = request_sound(path)
        activeHandle = play_sound_loop(sid)
        activeIntroPlaylistHandle = activeHandle
        set_volume(activeHandle, volume)
        activeTrackIndex = idx
    }
}
