require engine.core
require engine.input_core


class IntroController : Component {
    logoNode : NodeId
    skipNode : NodeId
    textNode : NodeId
    backdropNode : NodeId

    introMusicPath : string = "Project/Assets/Music/1st scene.mp3"
    introMusicVolume : float = 0.55
    introMusicHandle : SoundHandle = INVALID_SOUND_HANDLE

    canvasSize : float2 = float2(1920.0, 1080.0)
    time : float = 0.0
    introFinished : bool = false

    def override on_initialize() : void {
        print("=== IntroController START ===")

        self->initInput()
        self->setupCanvas()
        self->hideExistingChildren()
        self->createIntroLayout()
        self->playIntroMusic()

        self.time = 0.0
        self.introFinished = false
        self->setFrame(0)
    }

    def override on_update() : void {
        if ( self.introFinished ) {
            return
        }

        self.time = self.time + get_delta_time()

        if ( is_action_just_pressed("skipIntro") ) {
            self->finishIntro()
            return
        }

        if ( self.time < 9.0 ) {
            self->setFrame(0)
        } elif ( self.time < 14.0 ) {
            self->setFrame(1)
        } elif ( self.time < 19.0 ) {
            self->setFrame(2)
        } elif ( self.time < 25.0 ) {
            self->setFrame(3)
        } elif ( self.time < 29.0 ) {
            self->setFrame(4)
        } elif ( self.time < 34.0 ) {
            self->setFrame(5)
        } else {
            self->finishIntro()
        }
    }

    def override on_destroy() : void {
        if ( introMusicHandle != INVALID_SOUND_HANDLE && is_playing(introMusicHandle) ) {
            stop(introMusicHandle, 0.2)
        }
    }

    def initInput() : void {
        if ( has_action_set("introInput") ) {
            activate_action_set("introInput", true)
            return
        }

        add_and_activate_action_set("introInput", {
            "skipIntro" => Action(
                buttonActions = ButtonAction(
                    keyboardButtons = [KeyboardButtonInput(idx = KeyCode.Space)]
                )
            )
        })
    }

    def setupCanvas() : void {
        var hasFrame = false
        get_component(nodeId) $(var frame : UIFrame?) {
            if ( frame != null ) {
                hasFrame = true
                frame.size = canvasSize
                frame.pivot = float2(0.0, 0.0)
            }
        }

        if ( !hasFrame ) {
            add_component(nodeId, new UIFrame(size = canvasSize, pivot = float2(0.0, 0.0)))
        }

        var hasCanvas = false
        get_component(nodeId) $(var canvas : UICanvas?) {
            if ( canvas != null ) {
                hasCanvas = true
                canvas.screenMode = ScreenMode.FitExtend
                canvas.size = canvasSize
            }
        }

        if ( !hasCanvas ) {
            add_component(nodeId, new UICanvas(screenMode = ScreenMode.FitExtend, size = canvasSize))
        }
    }

    def hideExistingChildren() : void {
        // Only hide if this intro is part of a UI canvas, not the entire scene
        // Don't hide scene objects - only hide UI elements
        pass
    }

    def createIntroLayout() : void {
        let center = float2(canvasSize.x * 0.5, canvasSize.y * 0.5)
        let fullBleedSize = float2(canvasSize.x + 360.0, canvasSize.y + 240.0)

        backdropNode = create_node(NodeData(name = "IntroBackdrop", parent = nodeId))
        add_component(backdropNode, new UIImage(
            color = float4(0.0, 0.0, 0.0, 0.94),
            size = fullBleedSize,
            pivot = float2(0.5, 0.5)
        ))
        backdropNode?.UIFrame.localPosition2D = center

        textNode = create_node(NodeData(name = "IntroStoryText", parent = nodeId))
        add_component(textNode, new UIText(
            text = "",
            color = float4(0.90, 0.95, 1.0, 1.0),
            fontSize = 34.0,
            wordWrapping = true,
            pivot = float2(0.5, 0.5),
            horAlignment = TextHorAlignment.Center,
            vertAlignment = TextVertAlignment.Middle
        ))
        textNode?.UIFrame.localPosition2D = float2(960.0, 510.0)
        textNode?.UIFrame.size = float2(1320.0, 360.0)

        skipNode = create_node(NodeData(name = "IntroSkipText", parent = nodeId))
        add_component(skipNode, new UIText(
            text = "Space - skip",
            color = float4(0.74, 0.84, 0.92, 0.9),
            fontSize = 24.0,
            wordWrapping = false,
            pivot = float2(1.0, 1.0),
            horAlignment = TextHorAlignment.Right,
            vertAlignment = TextVertAlignment.Bottom
        ))
        skipNode?.UIFrame.localPosition2D = float2(1880.0, 1038.0)
        skipNode?.UIFrame.size = float2(260.0, 42.0)
    }

    def playIntroMusic() : void {
        if ( length(introMusicPath) == 0 ) {
            return
        }

        let music = request_sound(introMusicPath)
        introMusicHandle = play_sound(music)
        set_volume(introMusicHandle, introMusicVolume)
    }

    def setFrame(idx : int) : void {
        self->setNodeActive(backdropNode, true)
        self->setNodeActive(skipNode, true)
        self->setNodeActive(textNode, true)
        self->setText(self->getStoryText(idx))
    }

    def getStoryText(idx : int) : string {
        if ( idx == 0 ) {
            return "Once upon a time. A cloned person spawned.He was a mess reminded by a corporation"
        } elif ( idx == 1 ) {
            return "Every corner of that facility, where he woke up had been threatening him for a while."
        } elif ( idx == 2 ) {
            return "For a while, before he realized that his body became a grid for implants."
        } elif ( idx == 3 ) {
            return "The implants that made a hope for him..."
        } elif ( idx == 4 ) {
            return "The hope of transformation..."
        } elif ( idx == 5 ) {
            return "Move. To the Door. Good luck!"
        }

        return ""
    }

    def setText(value : string) : void {
        if ( self.textNode == NodeId() ) {
            return
        }

        get_component(self.textNode) $(var t : UIText?) {
            if ( t != null ) {
                t.text = value
            }
        }
    }

    def setNodeActive(n : NodeId, value : bool) : void {
        if ( n != NodeId() ) {
            n.isActive = value
        }
    }

    def finishIntro() : void {
        if ( self.introFinished ) {
            return
        }

        self.introFinished = true

        self->setNodeActive(backdropNode, false)
        self->setNodeActive(skipNode, false)
        self->setNodeActive(textNode, false)

        if ( introMusicHandle != INVALID_SOUND_HANDLE && is_playing(introMusicHandle) ) {
            stop(introMusicHandle, 0.5)
        }

        print("=== INTRO FINISHED ===")
    }
}
