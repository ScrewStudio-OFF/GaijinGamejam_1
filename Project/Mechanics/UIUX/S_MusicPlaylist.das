require engine.core
require engine.sound_core


class SMusicPlaylist : Component {
    @export playlistFolder : string = "Project/Assets/Music/PlayList"
    @export track1File : string = "cybergaijin.mp3"
    @export track2File : string = ""
    @export track3File : string = ""
    @export volume : float = 0.65
    @export fadeTime : float = 0.25
    @export playOnStart : bool = true
    @export loopPlaylist : bool = true

    activeTrackIndex : int = -1
    activeHandle : SoundHandle = INVALID_SOUND_HANDLE

    def override on_initialize() : void {
        if ( playOnStart ) {
            self->play_track(0)
        }
    }

    def override on_update() : void {
        if ( activeHandle == INVALID_SOUND_HANDLE ) {
            return
        }

        if ( !is_playing(activeHandle) ) {
            self->play_next_track()
        } else {
            set_volume(activeHandle, volume)
        }
    }

    def override on_destroy() : void {
        self->stop_active()
    }

    def play_next_track() : void {
        var nextIndex = activeTrackIndex + 1
        if ( nextIndex >= self->track_count() ) {
            if ( !loopPlaylist ) {
                self->stop_active()
                return
            }
            nextIndex = 0
        }

        self->play_track(nextIndex)
    }

    def play_track(idx : int) : void {
        let path = self->track_path(idx)
        if ( length(path) == 0 ) {
            return
        }

        self->stop_active()

        let sid = request_sound(path)
        activeHandle = play_sound(sid)
        set_volume(activeHandle, volume)
        activeTrackIndex = idx
    }

    def stop_active() : void {
        if ( activeHandle != INVALID_SOUND_HANDLE && is_playing(activeHandle) ) {
            stop(activeHandle, fadeTime)
        }

        activeHandle = INVALID_SOUND_HANDLE
        activeTrackIndex = -1
    }

    def private track_count() : int {
        var count = 0
        if ( length(track1File) > 0 ) {
            count = 1
        }
        if ( length(track2File) > 0 ) {
            count = 2
        }
        if ( length(track3File) > 0 ) {
            count = 3
        }

        return count
    }

    def private track_path(idx : int) : string {
        if ( idx == 0 && length(track1File) > 0 ) {
            return "{playlistFolder}/{track1File}"
        } elif ( idx == 1 && length(track2File) > 0 ) {
            return "{playlistFolder}/{track2File}"
        } elif ( idx == 2 && length(track3File) > 0 ) {
            return "{playlistFolder}/{track3File}"
        }

        return ""
    }
}
