require engine.core
require engine.input_core

class IntroController : Component {

    logoNode : NodeId
    skipNode : NodeId
    textNode : NodeId

    time : float = 0.0
    introFinished : bool = false

    def override on_initialize() : void {
        print("=== Manual IntroController START ===")

        self->initInput()

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

        if ( self.time < 1.5 ) {
            self->setFrame(0)
        } elif ( self.time < 3.0 ) {
            self->setFrame(1)
        } elif ( self.time < 4.5 ) {
            self->setFrame(2)
        } elif ( self.time < 6.0 ) {
            self->setFrame(3)
        } elif ( self.time < 7.5 ) {
            self->setFrame(4)
        } elif ( self.time < 9.0 ) {
            self->setFrame(5)
        } else {
            self->finishIntro()
        }
    }

    def override on_destroy() : void {
        pass
    }

    def initInput() : void {
        if ( has_action_set("introInput") ) {
            activate_action_set("introInput", true)
            return
        }

        add_and_activate_action_set("introInput", {
            "skipIntro" => Action(
                buttonActions = ButtonAction(
                    keyboardButtons = [KeyboardButtonInput(idx=KeyCode.Space)]
                )
            )
        })
    }

    def setFrame(idx : int) : void {
        if ( idx == 0 ) {
            self->setNodeActive(self.logoNode, true)
            self->setNodeActive(self.skipNode, false)
            self->setNodeActive(self.textNode, false)
            self->setText("")
        } else {
            self->setNodeActive(self.logoNode, false)
            self->setNodeActive(self.skipNode, true)
            self->setNodeActive(self.textNode, true)
            self->setText(self->getStoryText(idx))
        }
    }

    def getStoryText(idx : int) : string {
        if ( idx == 1 ) {
            return "Once upon a time, a cloned person was created.\nHe was nothing more than a mess assembled by a corporation."
        } elif ( idx == 2 ) {
            return "Every corner of the facility where he woke up\nhad been threatening him for a while."
        } elif ( idx == 3 ) {
            return "For a while, before he realized\nthat his body had become a grid for implants."
        } elif ( idx == 4 ) {
            return "The implants that gave him hope..."
        } elif ( idx == 5 ) {
            return "The hope of transformation..."
        }

        return ""
    }

    def setText(value : string) : void {
        if ( self.textNode == NodeId() ) {
            return
        }

        get_component(self.textNode) $(var t : UIText?) {
            t.text = value
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

        self->setNodeActive(self.logoNode, false)
        self->setNodeActive(self.skipNode, false)
        self->setNodeActive(self.textNode, false)

        print("=== INTRO FINISHED ===")
    }
}