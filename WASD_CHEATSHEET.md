# КРАТКАЯ ШПАРГАЛКА - WASD Управление

## ЧТО СДЕЛАНО

✅ Настроено WASD управление для игрока без прыжка  
✅ Полная система с нормализацией, трением и независимостью от FPS  
✅ Все файлы скомпилированы и игра работает  

---

## БЫСТРЫЙ СТАРТ - КОПИРУЙ-ПАСТИ

### 1. Скопируй этот компонент (S_Player.das):

```daslang
require engine.core

class SPlayer : Component {
    velocity : float3 = float3(0)
    MOVE_SPEED : float = 5.0
    FRICTION : float = 0.85

    def override on_initialize() : void {
        add_and_activate_action_set("playerInput", {
            "move" => Action(
                joystickActions = JoystickAction(
                    keyboardDPads = [
                        KeyboardDPadInput(
                            leftIdx = KeyCode.A,
                            rightIdx = KeyCode.D,
                            upIdx = KeyCode.W,
                            downIdx = KeyCode.S
                        )
                    ]
                )
            )
        })
    }

    def override on_update() : void {
        let move_input = get_action_vector2("move")
        var move_direction = float3(move_input.x, 0.0, move_input.y)
        
        if (length(move_direction) > 0.0) {
            move_direction = normalize(move_direction)
            velocity = move_direction * MOVE_SPEED
        } else {
            velocity = velocity * FRICTION
        }
        
        let current_pos = nodeId.localPosition
        nodeId.localPosition = current_pos + velocity * get_delta_time()
    }

    def override on_destroy() : void {
        pass
    }
}
```

### 2. Добавь этот компонент к ноде игрока в main.das:

```daslang
let player = create_node(NodeData(name = "Player", position = float3(0, 0.5, 0)))
add_component(player, new Mesh(meshId = CUBE_MESH_ID))
add_component(player, new SPlayer())  // ← ВОТ ЭТА СТРОКА
```

---

## ЗНАЧЕНИЯ ПАРАМЕТРОВ

```daslang
MOVE_SPEED : float = 5.0   // Скорость в единицах/сек
FRICTION : float = 0.85    // Множитель трения каждый кадр
```

### Варианты:

**Быстро двигается:**
```daslang
MOVE_SPEED : float = 10.0
FRICTION : float = 0.9    // Долгое скольжение
```

**Медленно, резко:**
```daslang
MOVE_SPEED : float = 2.0
FRICTION : float = 0.5    // Быстрая остановка
```

---

## ОСНОВНЫЕ КОНЦЕПЦИИ

### 1. Action Set (система управления)
```daslang
add_and_activate_action_set("playerInput", { ... })
// Создаёт именованную систему управления "playerInput"
```

### 2. Получение ввода
```daslang
let move_input = get_action_vector2("move")
// Возвращает: float2(-1..1, -1..1)
// x: -1 (A) ... 0 ... +1 (D)
// y: -1 (S) ... 0 ... +1 (W)
```

### 3. Нормализация
```daslang
move_direction = normalize(move_direction)
// Диагональное движение = прямое движение по скорости
```

### 4. Применение скорости
```daslang
nodeId.localPosition += velocity * get_delta_time()
// FPS-независимое движение
```

---

## ТЕСТИРОВАНИЕ

1. Сохрани файл
2. Нажми F5 в редакторе (или запусти игру)
3. Нажимай W, A, S, D
4. Куб должен двигаться по белой плоскости

---

## ВОЗМОЖНЫЕ ПРОБЛЕМЫ И РЕШЕНИЯ

### Проблема: "Куб не двигается"
**Решение:**
- Проверь что компонент добавлен: `add_component(player, new SPlayer())`
- Проверь что камера видит сцену
- Проверь консоль на ошибки компиляции

### Проблема: "Слишком быстро движется"
**Решение:**
```daslang
MOVE_SPEED : float = 2.0  // Уменьши вместо 5.0
```

### Проблема: "Движение не гладкое"
**Решение:**
```daslang
FRICTION : float = 0.7    // Уменьши трение для большего скольжения
```

---

## СТРУКТУРА ПАПОК

```
Project/
└─ Core/
   └─ Player/
      └─ S_Player.das         ← Компонент ЗДЕСЬ
main.das                      ← Инициализация сцены
WASD_MOVEMENT_GUIDE.md        ← Полная документация
```

---

## ДОПОЛНИТЕЛЬНО

### Как модифицировать:

**Изменить скорость:** 
- найди `MOVE_SPEED = 5.0` и измени число

**Изменить чувствительность торможения:**
- найди `FRICTION = 0.85` и измени число
- больше = медленнее тормозит (0.95)
- меньше = быстрее тормозит (0.7)

**Добавить вертикальное движение (нужно осторожно):**
```daslang
var move_direction = float3(move_input.x, некое_значение, move_input.y)
```

---

## ДОПОЛНИТЕЛЬНЫЕ КОМАНДЫ

```daslang
// Получить текущую скорость
let current_speed = length(velocity)

// Получить текущую позицию
let pos = nodeId.localPosition

// Проверить если движется (примерно)
if (length(velocity) > 0.1) { /* движется */ }

// Установить позицию прямо
nodeId.localPosition = float3(0, 0, 0)
```

---

## ГОТОВО!

Твоя система WASD управления полностью настроена с объяснениями.  
Используй [WASD_MOVEMENT_GUIDE.md](WASD_MOVEMENT_GUIDE.md) для полной документации.
