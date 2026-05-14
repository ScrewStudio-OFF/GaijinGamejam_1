require engine.core
require Project.Mechanics.UIUX.S_MainMenu
require Project.Mechanics.UIUX.S_HubIntro
require Project.Mechanics.UIUX.S_GameUI
require Project.Mechanics.UIUX.S_MusicPlaylist
require Project.Mechanics.Levelmanager.LevelTrigger
require Project.Core.Player.S_Player
require Project.Core.Player.S_CameraFollow


[export]
def on_initialize() {
    clear_scene()

    let mainMenuPrefab = request_prefab("Project/Levels/Lvl_Main.prefab")
    if ( mainMenuPrefab == PrefabId() ) {
        print("Main menu prefab not found: Project/Levels/Lvl_Main.prefab")
        return
    }

    instantiate_prefab(mainMenuPrefab, NodeData(name = "Lvl_Main"))
}
