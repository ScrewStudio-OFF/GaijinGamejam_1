require engine.core
require Project.Mechanics.StatsAndProgression.S_GameState

class SPlayerStats : Component {
    // Базовые статы
    @export baseHP : int = 20
    @export baseDamage : int = 5
    @export baseMoveSpeed : float = 8.0
    
    // Текущие значения
    currentHP : int = 20
    currentDamage : int = 5
    currentMoveSpeed : float = 8.0
    
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
    HP_BONUS : int = 2
    DAMAGE_BONUS : int = 2
    SPEED_BONUS_PERCENT : float = 0.20

    def override on_initialize() : void {
        HP_COSTS <- [2, 3, 4]
        DAMAGE_COSTS <- [3, 4, 5]
        SPEED_COSTS <- [2, 3, 4]

        coins = progress_get_saved_coins()
        hpUpgradeLevel = progress_get_saved_hp_upgrade_level()
        damageUpgradeLevel = progress_get_saved_damage_upgrade_level()
        speedUpgradeLevel = progress_get_saved_speed_upgrade_level()

        apply_all_upgrades()
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
        sync_progress_state()
    }

    def private sync_progress_state() : void {
        progress_save_player_progress(coins, hpUpgradeLevel, damageUpgradeLevel, speedUpgradeLevel)
    }

    def override on_destroy() : void {
        pass
    }
}