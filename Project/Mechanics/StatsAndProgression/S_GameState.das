require engine.core

var SAVED_COINS : int = 0
var SAVED_HP_UPGRADE_LEVEL : int = 0
var SAVED_DAMAGE_UPGRADE_LEVEL : int = 0
var SAVED_SPEED_UPGRADE_LEVEL : int = 0

var CURRENT_ARENA_LEVEL : int = 2
var CURRENT_WAVE : int = 1
var ARENA_CLEARED : bool = false


def progress_get_arena_level_path(level : int) : string {
    var sequenceIndex = level - 2
    while (sequenceIndex >= 5) {
        sequenceIndex -= 5
    }
    while (sequenceIndex < 0) {
        sequenceIndex += 5
    }

    var result = "Project/Levels/Lvl_Morgue.prefab"

    if (sequenceIndex == 1) {
        result = "Project/Levels/Lvl_Greenhouse.prefab"
    } elif (sequenceIndex == 2) {
        result = "Project/Levels/Lvl_Angar.prefab"
    } elif (sequenceIndex == 3) {
        result = "Project/Levels/Lvl_Polygon.prefab"
    } elif (sequenceIndex == 4) {
        result = "Project/Levels/Lvl_Laboratory.prefab"
    }

    return result
}


def progress_save_player_progress(coins : int, hpLevel : int, damageLevel : int, speedLevel : int) : void {
    SAVED_COINS = coins
    SAVED_HP_UPGRADE_LEVEL = hpLevel
    SAVED_DAMAGE_UPGRADE_LEVEL = damageLevel
    SAVED_SPEED_UPGRADE_LEVEL = speedLevel
}

def progress_get_saved_coins() : int {
    return SAVED_COINS
}

def progress_get_saved_hp_upgrade_level() : int {
    return SAVED_HP_UPGRADE_LEVEL
}

def progress_get_saved_damage_upgrade_level() : int {
    return SAVED_DAMAGE_UPGRADE_LEVEL
}

def progress_get_saved_speed_upgrade_level() : int {
    return SAVED_SPEED_UPGRADE_LEVEL
}

def progress_set_saved_coins(value : int) : void {
    SAVED_COINS = value
}

def progress_add_saved_coins(amount : int) : void {
    SAVED_COINS += amount
}

def progress_spend_saved_coins(cost : int) : bool {
    if (SAVED_COINS >= cost) {
        SAVED_COINS -= cost
        return true
    }

    return false
}

def progress_set_arena_level(level : int) : void {
    CURRENT_ARENA_LEVEL = level
    CURRENT_WAVE = 1
    ARENA_CLEARED = false
}

def progress_advance_arena_level() : void {
    CURRENT_ARENA_LEVEL += 1
    CURRENT_WAVE = 1
    ARENA_CLEARED = false
}

def progress_advance_wave() : void {
    CURRENT_WAVE += 1
}

def progress_get_current_arena_level() : int {
    return CURRENT_ARENA_LEVEL
}

def progress_get_current_wave() : int {
    return CURRENT_WAVE
}

def progress_set_arena_cleared(value : bool) : void {
    ARENA_CLEARED = value
}

def progress_is_arena_cleared() : bool {
    return ARENA_CLEARED
}


class SGameState : Component {
    def override on_initialize() : void {
        pass
    }

    def static get_instance() : SGameState? {
        return find_component(type<SGameState>)
    }

    def save_player_progress(coins : int, hpLevel : int, damageLevel : int, speedLevel : int) : void {
        progress_save_player_progress(coins, hpLevel, damageLevel, speedLevel)
    }

    def get_saved_coins() : int {
        return progress_get_saved_coins()
    }

    def set_saved_coins(value : int) : void {
        progress_set_saved_coins(value)
    }

    def add_saved_coins(amount : int) : void {
        progress_add_saved_coins(amount)
    }

    def spend_saved_coins(cost : int) : bool {
        return progress_spend_saved_coins(cost)
    }

    def set_arena_level(level : int) : void {
        progress_set_arena_level(level)
    }

    def advance_arena_level() : void {
        progress_advance_arena_level()
    }

    def get_arena_level_path(level : int) : string {
        return progress_get_arena_level_path(level)
    }

    def advance_wave() : void {
        progress_advance_wave()
    }

    def get_current_arena_level() : int {
        return progress_get_current_arena_level()
    }

    def get_current_wave() : int {
        return progress_get_current_wave()
    }

    def set_arena_cleared(value : bool) : void {
        progress_set_arena_cleared(value)
    }

    def is_arena_cleared() : bool {
        return progress_is_arena_cleared()
    }

    def override on_destroy() : void {
        pass
    }
}
