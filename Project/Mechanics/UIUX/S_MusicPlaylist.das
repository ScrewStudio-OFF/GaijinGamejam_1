require engine.core
require engine.sound_core
require engine.math.math_utils


var activeGameplayMusicHandle : SoundHandle = INVALID_SOUND_HANDLE
var activeGameplayMusicTrackIndex : int = -1
var lastGameplayMusicTrackIndex : int = -1
var gameplayMusicVolume : float = 0.65
var gameplayMusicSuppressed : bool = false

var gameplayTrack0Played : bool = false
var gameplayTrack1Played : bool = false
var gameplayTrack2Played : bool = false
var gameplayTrack3Played : bool = false
var gameplayTrack4Played : bool = false
var gameplayTrack5Played : bool = false


def stop_gameplay_music(fadeTime : float = 0.25) : void {
    gameplayMusicSuppressed = true

    if ( activeGameplayMusicHandle != INVALID_SOUND_HANDLE && is_playing(activeGameplayMusicHandle) ) {
        stop(activeGameplayMusicHandle, fadeTime)
    }

    activeGameplayMusicHandle = INVALID_SOUND_HANDLE
    activeGameplayMusicTrackIndex = -1
}


class SMusicPlaylist : Component {
    @export playlistFolder : string = "Project/Assets/Music/PlayList"
    @export track1File : string = "Morgue.mp3"
    @export track2File : string = "Angar.mp3"
    @export track3File : string = "greenhpuse.mp3"
    @export track4File : string = "cybergaijin.mp3"
    @export track5File : string = ""
    @export track6File : string = ""
    @export volume : float = 0.65
    @export fadeTime : float = 0.35
    @export playOnStart : bool = true
    @export loopPlaylist : bool = true
    @export randomizeTracks : bool = true
    @export stopOnDestroy : bool = false

    activeTrackIndex : int = -1
    activeHandle : SoundHandle = INVALID_SOUND_HANDLE

    def override on_initialize() : void {
        volume = clamp(volume, 0.0, 1.0)
        gameplayMusicVolume = volume

        if ( activeGameplayMusicHandle != INVALID_SOUND_HANDLE && is_playing(activeGameplayMusicHandle) ) {
            activeHandle = activeGameplayMusicHandle
            activeTrackIndex = activeGameplayMusicTrackIndex
            set_volume(activeHandle, volume, fadeTime)
            return
        }

        if ( playOnStart ) {
            self->play_next_track()
        }
    }

    def override on_update() : void {
        volume = clamp(volume, 0.0, 1.0)
        gameplayMusicVolume = volume

        if ( gameplayMusicSuppressed ) {
            if ( activeHandle != INVALID_SOUND_HANDLE && is_playing(activeHandle) ) {
                self->stop_active()
            }
            return
        }

        if ( activeHandle == INVALID_SOUND_HANDLE ) {
            self->ensure_playing()
            return
        }

        if ( !is_playing(activeHandle) ) {
            if ( activeGameplayMusicHandle == activeHandle ) {
                activeGameplayMusicHandle = INVALID_SOUND_HANDLE
                activeGameplayMusicTrackIndex = -1
            }

            activeHandle = INVALID_SOUND_HANDLE
            activeTrackIndex = -1
            self->play_next_track()
        } else {
            set_volume(activeHandle, volume)
        }
    }

    def override on_destroy() : void {
        if ( stopOnDestroy ) {
            self->stop_active()
        }

        activeHandle = INVALID_SOUND_HANDLE
        activeTrackIndex = -1
    }

    def ensure_playing() : void {
        if ( gameplayMusicSuppressed ) {
            return
        }

        if ( activeGameplayMusicHandle != INVALID_SOUND_HANDLE && is_playing(activeGameplayMusicHandle) ) {
            activeHandle = activeGameplayMusicHandle
            activeTrackIndex = activeGameplayMusicTrackIndex
            set_volume(activeHandle, volume, fadeTime)
            return
        }

        if ( playOnStart ) {
            self->play_next_track()
        }
    }

    def play_next_track() : void {
        if ( gameplayMusicSuppressed ) {
            return
        }

        let count = self->track_count()
        if ( count <= 0 ) {
            self->stop_active()
            return
        }

        var nextIndex = activeTrackIndex + 1
        if ( randomizeTracks ) {
            nextIndex = self->choose_random_track()
        } elif ( nextIndex >= count ) {
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
        activeTrackIndex = idx
        activeGameplayMusicHandle = activeHandle
        activeGameplayMusicTrackIndex = idx
        lastGameplayMusicTrackIndex = idx

        self->mark_track_played(idx)
        set_volume(activeHandle, volume, fadeTime)
        print("Gameplay music: {path}")
    }

    def stop_active() : void {
        if ( activeHandle != INVALID_SOUND_HANDLE && is_playing(activeHandle) ) {
            stop(activeHandle, fadeTime)
        }

        if ( activeGameplayMusicHandle == activeHandle ) {
            activeGameplayMusicHandle = INVALID_SOUND_HANDLE
            activeGameplayMusicTrackIndex = -1
        }

        activeHandle = INVALID_SOUND_HANDLE
        activeTrackIndex = -1
    }

    def private choose_random_track() : int {
        let count = self->track_count()
        var result = -1

        if ( count <= 0 ) {
            return result
        }

        if ( count == 1 ) {
            return 0
        }

        if ( self->all_tracks_played(count) ) {
            self->reset_played_round()
        }

        for ( attempt in range(32) ) {
            let candidate = random_range(0, count)
            if ( !self->was_track_played(candidate) && candidate != lastGameplayMusicTrackIndex ) {
                result = candidate
                break
            }
        }

        if ( result < 0 ) {
            for ( candidate in range(count) ) {
                if ( !self->was_track_played(candidate) && candidate != lastGameplayMusicTrackIndex ) {
                    result = candidate
                    break
                }
            }
        }

        if ( result < 0 ) {
            self->reset_played_round()
            for ( candidate in range(count) ) {
                if ( candidate != lastGameplayMusicTrackIndex ) {
                    result = candidate
                    break
                }
            }
        }

        if ( result < 0 ) {
            result = 0
        }

        return result
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
        if ( length(track4File) > 0 ) {
            count = 4
        }
        if ( length(track5File) > 0 ) {
            count = 5
        }
        if ( length(track6File) > 0 ) {
            count = 6
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
        } elif ( idx == 3 && length(track4File) > 0 ) {
            return "{playlistFolder}/{track4File}"
        } elif ( idx == 4 && length(track5File) > 0 ) {
            return "{playlistFolder}/{track5File}"
        } elif ( idx == 5 && length(track6File) > 0 ) {
            return "{playlistFolder}/{track6File}"
        }

        return ""
    }

    def private all_tracks_played(count : int) : bool {
        for ( idx in range(count) ) {
            if ( !self->was_track_played(idx) ) {
                return false
            }
        }

        return true
    }

    def private was_track_played(idx : int) : bool {
        if ( idx == 0 ) {
            return gameplayTrack0Played
        } elif ( idx == 1 ) {
            return gameplayTrack1Played
        } elif ( idx == 2 ) {
            return gameplayTrack2Played
        } elif ( idx == 3 ) {
            return gameplayTrack3Played
        } elif ( idx == 4 ) {
            return gameplayTrack4Played
        } elif ( idx == 5 ) {
            return gameplayTrack5Played
        }

        return false
    }

    def private mark_track_played(idx : int) : void {
        if ( idx == 0 ) {
            gameplayTrack0Played = true
        } elif ( idx == 1 ) {
            gameplayTrack1Played = true
        } elif ( idx == 2 ) {
            gameplayTrack2Played = true
        } elif ( idx == 3 ) {
            gameplayTrack3Played = true
        } elif ( idx == 4 ) {
            gameplayTrack4Played = true
        } elif ( idx == 5 ) {
            gameplayTrack5Played = true
        }
    }

    def private reset_played_round() : void {
        gameplayTrack0Played = false
        gameplayTrack1Played = false
        gameplayTrack2Played = false
        gameplayTrack3Played = false
        gameplayTrack4Played = false
        gameplayTrack5Played = false
    }
}


def ensure_gameplay_music_playlist(playlistFolder : string = "Project/Assets/Music/PlayList", volume : float = -1.0) : void {
    gameplayMusicSuppressed = false

    var targetVolume = gameplayMusicVolume
    if ( volume >= 0.0 ) {
        targetVolume = clamp(volume, 0.0, 1.0)
        gameplayMusicVolume = targetVolume
    }

    let existing = find_component(type<SMusicPlaylist>)
    if ( existing != null ) {
        get_component(existing.nodeId) $(var playlist : SMusicPlaylist?) {
            if ( playlist != null ) {
                playlist.playlistFolder = playlistFolder
                playlist.volume = targetVolume
                playlist.playOnStart = true
                playlist.ensure_playing()
            }
        }
        return
    }

    let musicNode = create_node(NodeData(name = "GameplayMusicPlaylist"))
    add_component(musicNode, new SMusicPlaylist(
        playlistFolder = playlistFolder,
        volume = targetVolume,
        playOnStart = true,
        randomizeTracks = true,
        stopOnDestroy = false
    ))
}
