require engine.core
require Project.Mechanics.StatsAndProgression.S_UpgradeShop
require Project.Mechanics.StatsAndProgression.S_GameState
require Project.Core.Player.S_Player

def upgrade_trigger_find_node_recursive(nodeId : NodeId, nodeName : string) : NodeId {
    if ( nodeId.name == nodeName ) {
        return nodeId
    }

    let children = get_children(nodeId)

    for ( child in children ) {
        let found = upgrade_trigger_find_node_recursive(child, nodeName)

        if ( found != NodeId() ) {
            return found
        }
    }

    return NodeId()
}

class SUpgradeTrigger : Component {
    @export playerNode : NodeId = NodeId()
    @export playerName : string = "P_Player"
    @export triggerNode : NodeId = NodeId()
    @export triggerNodeName : string = ""
    @export triggerRadius : float = 3.0
    @export upgradeMenuPrefabPath : string = "Project/Mechanics/StatsAndProgression/Prefabs/P_UpgradeMenu.prefab"

    triggered : bool = false

    def override on_initialize() : void {
        if ( self.playerNode == NodeId() ) {
            self->find_player()
        }

        if ( self.triggerNode == NodeId() ) {
            if ( length(self.triggerNodeName) > 0 ) {
                self->find_trigger_node()
            } else {
                self.triggerNode = nodeId
            }
        }

        self.triggered = false
    }

    def override on_update() : void {
        if ( self.triggered ) {
            return
        }

        if ( self.playerNode == NodeId() || !self.playerNode.isAlive ) {
            self->find_player()
        }

        if ( self.playerNode == NodeId() || !self.playerNode.isAlive ) {
            return
        }

        if ( self.triggerNode == NodeId() || !self.triggerNode.isAlive ) {
            return
        }

        let d = length(self.playerNode.worldPosition - self.triggerNode.worldPosition)

        if ( d <= self.triggerRadius ) {
            self.triggered = true
            self->open_upgrade_menu()
        }
    }

    def private open_upgrade_menu() : void {
        // Try to find existing shop component
        var shopComp = find_component(type<SUpgradeShop>)

        if ( shopComp != null ) {
            shopComp.open_shop()
            return
        }

        // Instantiate prefab if not present
        let prefab = request_prefab(self.upgradeMenuPrefabPath)

        if ( prefab == PrefabId() ) {
            print("WARNING: upgrade menu prefab not found: {self.upgradeMenuPrefabPath}")
            return
        }

        let menuNode = instantiate_prefab(prefab, NodeData(name = "UpgradeMenu"))

        if ( menuNode == NodeId() ) {
            print("Failed to instantiate upgrade menu prefab")
            return
        }

        // Find SUpgradeShop on the instantiated node and open it
        get_component(menuNode) $(var shop : SUpgradeShop?) {
            if ( shop != null ) {
                shop.open_shop()
                return
            }
        }

        // fallback: search children
        let children = get_children(menuNode)
        for ( child in children ) {
            get_component(child) $(var shop2 : SUpgradeShop?) {
                if ( shop2 != null ) {
                    shop2.open_shop()
                    return
                }
            }
        }
    }

    def private find_player() : void {
        let roots = get_scene_roots()

        for ( root in roots ) {
            let found = self->find_player_recursive(root)
            if ( found != NodeId() ) {
                self.playerNode = found
                return
            }
        }
    }

    def private find_player_recursive(n : NodeId) : NodeId {
        let player = get_component(n, type<SPlayer>)

        if ( player != null ) {
            return n
        }

        if ( n.name == self.playerName ) {
            return n
        }

        let children = get_children(n)
        for ( child in children ) {
            let found = self->find_player_recursive(child)
            if ( found != NodeId() ) {
                return found
            }
        }

        return NodeId()
    }

    def private find_trigger_node() : void {
        if ( length(self.triggerNodeName) <= 0 ) {
            return
        }

        // search local first
        let local = upgrade_trigger_find_node_recursive(nodeId, self.triggerNodeName)
        if ( local != NodeId() ) {
            self.triggerNode = local
            return
        }

        let roots = get_scene_roots()
        for ( r in roots ) {
            let found = upgrade_trigger_find_node_recursive(r, self.triggerNodeName)
            if ( found != NodeId() ) {
                self.triggerNode = found
                return
            }
        }
    }
}
