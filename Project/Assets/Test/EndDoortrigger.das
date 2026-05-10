require engine.core

class EndDoorTrigger : Component {

    popupCanvas  : NodeId
    popupImage   : NodeId
    playerNode   : NodeId

    popupTexture : string = "Project/Assets/UI/Refined.png"

    playerName   : string = "Player"

    // Радиус зоны вокруг TheEnd
    triggerRadius : float = 2.0

    isShown : bool = false

    def override on_initialize() : void {
        print("=== EndDoorTrigger initialized ===")
        print("Self node name: {self.nodeId.name}")
        print("Self hierarchy: {self.nodeId.hierarchyName}")

        self->findPlayer()
        self->createPopup()
        self->hidePopup()
    }

    def override on_update() : void {
        if ( self.playerNode == NodeId() ) {
            self->findPlayer()
            return
        }

        let a = self.nodeId.worldPosition
        let b = self.playerNode.worldPosition

        let d = length(a - b)

        if ( d <= self.triggerRadius ) {
            if ( !self.isShown ) {
                print("PLAYER ENTERED THE END ZONE")
                self->showPopup()
            }
        } else {
            if ( self.isShown ) {
                print("PLAYER EXITED THE END ZONE")
                self->hidePopup()
            }
        }
    }

    def override on_destroy() : void {
        pass
    }

    def findPlayer() : void {
        let roots = get_scene_roots()

        for ( root in roots ) {
            let found = self->findPlayerRecursive(root)

            if ( found != NodeId() ) {
                self.playerNode = found
                print("Player found: {self.playerNode.hierarchyName}")
                return
            }
        }

        print("WARNING: Player not found")
    }

    def findPlayerRecursive(n : NodeId) : NodeId {
        if ( n.name == self.playerName ) {
            return n
        }

        if ( find(n.hierarchyName, self.playerName) >= 0 ) {
            return n
        }

        let children = get_children(n)

        for ( child in children ) {
            let found = self->findPlayerRecursive(child)

            if ( found != NodeId() ) {
                return found
            }
        }

        return NodeId()
    }

    def createPopup() : void {
        self.popupCanvas = create_node(NodeData(
            name = "RefinedPopupCanvas",
            position = float3(0.0, 0.0, 0.0),
            scale = float3(5.0, 5.0, 5.0)
        ))

        add_component(self.popupCanvas, new UICanvas())

        self.popupImage = create_node(NodeData(
            name = "RefinedPopupImage",
            parent = self.popupCanvas,

            // Положение всей картинки на экране
            // X: влево/вправо, Y: вверх/вниз
            position = float3(0.0, 0.0, 0.0)
        ))

        add_component(self.popupImage, new UIImage(
            textureId = request_texture(self.popupTexture),

            // Размер самой картинки до масштабирования canvas
            // При canvas scale = 5 это будет выглядеть крупно
            size = float2(220.0, 90.0)
        ))
    }

    def showPopup() : void {
        self.isShown = true

        if ( self.popupCanvas != NodeId() ) {
            self.popupCanvas.isActive = true
        }
    }

    def hidePopup() : void {
        self.isShown = false

        if ( self.popupCanvas != NodeId() ) {
            self.popupCanvas.isActive = false
        }
    }
}