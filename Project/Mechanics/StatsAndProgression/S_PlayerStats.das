require engine.core
require engine.sound_core
require Project.Core.Player.S_Player
require Project.Mechanics.Combat.S_Damageable
require Project.Mechanics.StatsAndProgression.S_GameState

class SPlayerStats : Component {
    // Базовые статы
    @export baseHP : int = 100
    @export baseDamage : int = 10
    @export baseMoveSpeed : float = 5.0
    @export upgradeSoundPath : string = "Project/Assets/SFX/Abilities/SFX_DashAbility.mp3"
    @export upgradeSoundVolume : float = 1.0
    @export hpUpgradeMeshNames : array<string>
    @export damageUpgradeMeshNames : array<string>
    @export speedUpgradeMeshNames : array<string>
    
    // Текущие значения
    currentHP : int = 100
    currentDamage : int = 10
    currentMoveSpeed : float = 5.0
    
    // Уровни апгрейдов (0-3)
    hpUpgradeLevel : int = 0
    damageUpgradeLevel : int = 0
    speedUpgradeLevel : int = 0
    
    // Экономика
    coins : int = 0
    
    // Стоимость апгрейдов (используем функции для доступа)
    @no_export HP_COSTS : array<int>
    @no_export DAMAGE_COSTS : array<int>
    @no_export SPEED_COSTS : array<int>
    
    // Бонусы за апгрейд
    HP_BONUS : int = 20
    DAMAGE_BONUS : int = 5
    SPEED_BONUS_PERCENT : float = 0.08

    def override on_initialize() : void {
        HP_COSTS <- [6, 10, 14]
        DAMAGE_COSTS <- [8, 12, 16]
        SPEED_COSTS <- [7, 11, 15]
        self->setup_default_upgrade_mesh_names()

        coins = progress_get_saved_coins()
        hpUpgradeLevel = progress_get_saved_hp_upgrade_level()
        damageUpgradeLevel = progress_get_saved_damage_upgrade_level()
        speedUpgradeLevel = progress_get_saved_speed_upgrade_level()

        apply_all_upgrades()
        self->apply_stats_to_components(false)
        self->apply_upgrade_meshes()
    }

    def override on_update() : void {
        self->apply_upgrade_meshes()
    }

    def add_coins(amount : int) : void {
        coins += amount
        sync_progress_state()
        print("Coins: {coins}")
    }

    def pay_for_upgrade(cost : int) : bool {
        if (coins >= cost) {
            coins -= cost
            sync_progress_state()
            return true
        }
        return false
    }

    def can_upgrade_hp() : bool {
        return hpUpgradeLevel < 3
    }

    def can_upgrade_damage() : bool {
        return damageUpgradeLevel < 3
    }

    def can_upgrade_speed() : bool {
        return speedUpgradeLevel < 3
    }

    def get_hp_upgrade_cost() : int {
        if (hpUpgradeLevel >= 3) {
            return 999
        }
        return HP_COSTS[hpUpgradeLevel]
    }

    def get_damage_upgrade_cost() : int {
        if (damageUpgradeLevel >= 3) {
            return 999
        }
        return DAMAGE_COSTS[damageUpgradeLevel]
    }

    def get_speed_upgrade_cost() : int {
        if (speedUpgradeLevel >= 3) {
            return 999
        }
        return SPEED_COSTS[speedUpgradeLevel]
    }

    def upgrade_hp() : bool {
        if (!can_upgrade_hp()) {
            return false
        }
        let cost = get_hp_upgrade_cost()
        if (pay_for_upgrade(cost)) {
            hpUpgradeLevel += 1
            apply_hp_upgrade()
            self->apply_stats_to_components(true)
            self->apply_upgrade_meshes()
            self->play_upgrade_sound()
            sync_progress_state()
            print("HP upgraded to level {hpUpgradeLevel}")
            return true
        }
        return false
    }

    def upgrade_damage() : bool {
        if (!can_upgrade_damage()) {
            return false
        }
        let cost = get_damage_upgrade_cost()
        if (pay_for_upgrade(cost)) {
            damageUpgradeLevel += 1
            apply_damage_upgrade()
            self->apply_stats_to_components(false)
            self->apply_upgrade_meshes()
            self->play_upgrade_sound()
            sync_progress_state()
            print("Damage upgraded to level {damageUpgradeLevel}")
            return true
        }
        return false
    }

    def upgrade_speed() : bool {
        if (!can_upgrade_speed()) {
            return false
        }
        let cost = get_speed_upgrade_cost()
        if (pay_for_upgrade(cost)) {
            speedUpgradeLevel += 1
            apply_speed_upgrade()
            self->apply_stats_to_components(false)
            self->apply_upgrade_meshes()
            self->play_upgrade_sound()
            sync_progress_state()
            print("Speed upgraded to level {speedUpgradeLevel}")
            return true
        }
        return false
    }

    def private apply_all_upgrades() : void {
        apply_hp_upgrade()
        apply_damage_upgrade()
        apply_speed_upgrade()
    }

    def private apply_hp_upgrade() : void {
        currentHP = baseHP + (hpUpgradeLevel * HP_BONUS)
    }

    def private apply_damage_upgrade() : void {
        currentDamage = baseDamage + (damageUpgradeLevel * DAMAGE_BONUS)
    }

    def private apply_speed_upgrade() : void {
        currentMoveSpeed = baseMoveSpeed * (1.0 + float(speedUpgradeLevel) * SPEED_BONUS_PERCENT)
    }

    def private setup_default_upgrade_mesh_names() : void {
        if (length(hpUpgradeMeshNames) == 0) {
            hpUpgradeMeshNames <- ["armor_chest", "armor_belly", "armor_spine"]
        }

        if (length(damageUpgradeMeshNames) == 0) {
            damageUpgradeMeshNames <- ["armor_shoulders", "armor_arms", "armor_hands"]
        }

        if (length(speedUpgradeMeshNames) == 0) {
            speedUpgradeMeshNames <- ["armor_thighs", "armor_knees", "armor_feet"]
        }
    }

    def private apply_stats_to_components(healHpGain : bool) : void {
        get_component(nodeId) $(var damageable : SDamageable?) {
            if (damageable != null) {
                let oldMaxHealth = damageable.maxHealth
                let newMaxHealth = float(currentHP)
                damageable.maxHealth = newMaxHealth

                if (healHpGain) {
                    let gainedHealth = newMaxHealth - oldMaxHealth
                    damageable.health += gainedHealth
                }

                if (damageable.health <= 0.0 || damageable.health > damageable.maxHealth) {
                    damageable.health = damageable.maxHealth
                }
            }
        }

        get_component(nodeId) $(var player : SPlayer?) {
            if (player != null) {
                player.MOVE_SPEED = currentMoveSpeed
            }
        }

    }

    def private apply_upgrade_meshes() : void {
        self->apply_upgrade_mesh_group(hpUpgradeMeshNames, hpUpgradeLevel)
        self->apply_upgrade_mesh_group(damageUpgradeMeshNames, damageUpgradeLevel)
        self->apply_upgrade_mesh_group(speedUpgradeMeshNames, speedUpgradeLevel)
    }

    def private apply_upgrade_mesh_group(meshNames : array<string>; level : int) : void {
        for (meshName, meshIndex in meshNames, count()) {
            let meshNode = self->find_child_by_name_recursive(nodeId, meshName)
            if (meshNode != NodeId() && meshNode.isAlive) {
                meshNode.isActive = meshIndex < level
            }
        }
    }

    def private find_child_by_name_recursive(startNode : NodeId, targetName : string) : NodeId {
        if (startNode == NodeId() || !startNode.isAlive) {
            return NodeId()
        }

        if (startNode.name == targetName) {
            return startNode
        }

        let children = get_children(startNode)
        for (child in children) {
            let found = self->find_child_by_name_recursive(child, targetName)
            if (found != NodeId()) {
                return found
            }
        }

        return NodeId()
    }

    def private play_upgrade_sound() : void {
        if (length(upgradeSoundPath) == 0) {
            return
        }

        let sound = request_sound(upgradeSoundPath)
        let sid = play_sound(sound)
        set_volume(sid, upgradeSoundVolume)
    }

    def get_hp() : int {
        return currentHP
    }

    def get_damage() : int {
        return currentDamage
    }

    def get_move_speed() : float {
        return currentMoveSpeed
    }

    def reset_stats() : void {
        hpUpgradeLevel = 0
        damageUpgradeLevel = 0
        speedUpgradeLevel = 0
        coins = 0
        apply_all_upgrades()
        self->apply_stats_to_components(false)
        self->apply_upgrade_meshes()
        sync_progress_state()
    }

    def private sync_progress_state() : void {
        progress_save_player_progress(coins, hpUpgradeLevel, damageUpgradeLevel, speedUpgradeLevel)
    }

    def override on_destroy() : void {
        pass
    }
}
