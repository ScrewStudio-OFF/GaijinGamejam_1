require engine.core
require Project.Mechanics.UIUX.S_MainMenu
require Project.Mechanics.UIUX.S_HubIntro
require Project.Mechanics.UIUX.S_GameUI
require Project.Mechanics.UIUX.S_MusicPlaylist
require Project.Mechanics.UIUX.S_DeathScreen
require Project.Mechanics.Levelmanager.LevelTrigger
require Project.Mechanics.Levelmanager.S_LevelManager
require Project.Mechanics.Enemy.S_EnemyAI
require Project.Mechanics.Enemy.S_EnemyLoot
require Project.Mechanics.Enemy.S_EnemySpawner
require Project.Mechanics.StatsAndProgression.S_GameState
require Project.Mechanics.StatsAndProgression.S_PlayerStats
require Project.Mechanics.StatsAndProgression.S_UpgradeShop
require Project.Mechanics.StatsAndProgression.S_UpgradeTrigger
require Project.Mechanics.Combat.S_Damageable
require Project.Mechanics.Combat.S_AttackHitbox
require Project.Mechanics.Combat.S_PlayerCombat
require Project.Mechanics.Abilities.S_AbilityDash
require Project.Mechanics.VFX.S_DashAfterImage
require Project.Mechanics.VFX.S_AutoDestroy
require Project.Core.Player.S_Player
require Project.Core.Player.S_CameraFollow
require Project.Core.Player.S_PlayerAnimController
require Project.Assets.Test.InstancePrefabs
require Project.Assets.Lvl_Greenhouse.S_GreenHouseInstancePrefabs


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
