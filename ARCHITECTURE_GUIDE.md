# Правильная Архитектура EdenSpark Проекта

## Твоя Структура - ПРАВИЛЬНАЯ ✅

```
main.das (точка входа)
  └─ Загружает префабы → instantiate_prefab()
     ├─ Lvl_Base.prefab (уровень)
     │  ├─ RenderSettings
     │  ├─ DirectionLight (свет)
     │  └─ Mesh (платформа/земля)
     └─ P_Player.prefab (игрок)
        ├─ Mesh (куб/модель)
        ├─ Camera (обзор)
        ├─ CharacterController (физика)
        ├─ CapsuleCollision (коллизии)
        └─ S_Player (управление)
```

---

## Префабы vs main.das

### ✅ Используй ПРЕФАБЫ для:
- **Повторяемых объектов** (враги, предметы, платформы)
- **Сложных сборок** (игрок с несколькими компонентами)
- **Уровней** (сцены с готовой геометрией и светом)
- **Переиспользования** (один префаб - много копий)

**Преимущества:**
- Модульность - изменился префаб, изменились ВСЕ его копии
- Читаемость - ясно что из чего состоит
- Масштабируемость - легко добавлять новые уровни/врагов
- Декораторское редактирование - красивый UI в редакторе

### ❌ Избегай создания в main.das:
- Не создавай всё руками через `create_node()` в main.das
- main.das должен быть **ЛЁГКИМ И ЧИСТЫМ**

**main.das должен быть примерно таким:**
```daslang
[export] def on_initialize() {
    let level = instantiate_prefab(request_prefab("Lvl_Base"), ...)
    let player = instantiate_prefab(request_prefab("P_Player"), ...)
}

[export] def on_update() {
    // Опционально: общая логика
}
```

---

## Компоненты в Префабе Игрока

Твой текущий состав в **P_Player.prefab**:

| Компонент | Назначение | Нужен? |
|-----------|-----------|--------|
| **Mesh** | Визуальная модель (куб, персонаж) | ✅ Да |
| **Camera** | Обзор от первого/третьего лица | ✅ Да |
| **CharacterController** | Физика движения персонажа | ✅ Да |
| **CapsuleCollision** | Форма столкновения | ✅ Да |
| **RigidBody** | Физика ( масса, гравитация) | ❓ Смотри ниже |
| **S_Player** | Скрипт управления WASD | ✅ Да |

### CharacterController vs RigidBody

**CharacterController:**
- Специализирован для персонажей
- Встроенная гравитация
- Встроенная поддержка прыжков/падений
- Автоматическая обработка коллизий с землёй
- **Рекомендуется использовать ВМЕСТО RigidBody**

**RigidBody:**
- Для физических объектов (коробки, мячи)
- Реалистичная физика (импульсы, вращение)
- Переусложнит управление персонажем

### Правильный состав для игрока:
```
✅ Хорошо (твой вариант):
- Mesh
- Camera
- CharacterController
- CapsuleCollision
- S_Player

❌ Если стоит RigidBody:
- Удали его! CharacterController уже управляет физикой
```

---

## Как Работает Загрузка

### 1. Запуск Игры

```daslang
[export] def on_initialize() {
    // Вызывается один раз в начале
}
```

### 2. Загрузка Префаба Уровня

```daslang
let level_prefab = request_prefab("Lvl_Base")
// 1. Ищет файл "Lvl_Base.prefab" 
// 2. Загружает его определение
// 3. Возвращает PrefabId

let level = instantiate_prefab(level_prefab, NodeData(...))
// 1. Создаёт копию префаба в сцене
// 2. Применяет все компоненты и вложенные объекты
// 3. Возвращает NodeId созданной ноды
```

### 3. Загрузка Префаба Игрока

```daslang
let player_prefab = request_prefab("P_Player")
let player = instantiate_prefab(player_prefab, NodeData(
    name = "Player",
    position = float3(0, 1, 0)
))
// Создаёт игрока с:
// - S_Player компонентом активным и ready
// - CharacterController готовым к управлению
// - Camera активной для отрисовки
```

---

## Как CharacterController Работает в S_Player

```daslang
class SPlayer : Component {
    character_controller : CharacterController?
    
    def override on_initialize() : void {
        // Получаем компонент CharacterController той же ноды
        get_component(nodeId) $(var cc : CharacterController?) {
            character_controller = cc
        }
    }
    
    def override on_update() : void {
        // Получаем ввод
        let move_input = get_action_vector2("move")
        var move_direction = float3(move_input.x, 0, move_input.y)
        
        // Обновляем скорость
        // ...
        
        // ГЛАВНОЕ: Используем CharacterController
        if (character_controller != null) {
            character_controller.velocity = move_direction
            // CharacterController сам обрабатывает:
            // - Коллизии с землёй
            // - Гравитацию
            // - Ограничение скорости
        }
    }
}
```

---

## Правильный Файловый Layout

```
Project/
├─ Levels/
│  ├─ Lvl_Base.prefab          ← Уровень (всё сразу)
│  ├─ Lvl_Base.prefab.meta
│  ├─ Lvl_Tutorial.prefab      ← Второй уровень (копируй Lvl_Base)
│  └─ Lvl_Tutorial.prefab.meta
│
├─ Core/
│  └─ Player/
│     ├─ P_Player.prefab       ← Префаб игрока
│     ├─ P_Player.prefab.meta
│     └─ S_Player.das          ← Скрипт управления
│
├─ Entities/
│  ├─ Enemy/
│  │  ├─ P_Enemy.prefab
│  │  └─ S_Enemy.das
│  └─ Item/
│     ├─ P_Coin.prefab
│     └─ P_Weapon.prefab
│
├─ main.das                    ← Точка входа (мин. 20 строк)
└─ manifest.blk
```

---

## Когда Использовать main.das для Создания

Только для **быстрого прототипирования**:

```daslang
[export] def on_initialize() {
    // ТЕСТ: создаём куб руками
    let cube = create_node(NodeData(name = "TestCube", position = float3(0, 1, 0)))
    add_component(cube, new Mesh(meshId = CUBE_MESH_ID))
    
    // Потом ПЕРЕНОСИМ это в префаб!
}
```

Но как только проект растёт → всё в префабы.

---

## Твой Текущий Setup

| Файл | Назначение | Статус |
|------|-----------|--------|
| main.das | Загрузка префабов | ✅ Правильно |
| P_Player.prefab | Префаб игрока | ✅ Используется |
| S_Player.das | Управление WASD | ✅ Работает |
| Lvl_Base.prefab | Уровень/сцена | ✅ Используется |

**Всё правильно организовано!**

---

## Что Дальше?

### Добавить Прыжок (Y-ось в CharacterController)

```daslang
class SPlayer : Component {
    character_controller : CharacterController?
    velocity_y : float = 0.0
    GRAVITY : float = -9.8
    JUMP_FORCE : float = 5.0
    
    def override on_update() : void {
        let move_input = get_action_vector2("move")
        var move_dir = float3(move_input.x, 0, move_input.y) * MOVE_SPEED
        
        // Гравитация
        velocity_y += GRAVITY * get_delta_time()
        
        // Прыжок (если на земле)
        if (is_action_pressed("jump") && character_controller.isGrounded) {
            velocity_y = JUMP_FORCE
        }
        
        // Применяем движение с прыжком
        character_controller.velocity = float3(move_dir.x, velocity_y, move_dir.z)
    }
}
```

### Добавить Врагов

```
Entities/Enemy/
├─ P_Enemy.prefab
└─ S_Enemy.das

// main.das:
let enemy_prefab = request_prefab("P_Enemy")
let enemy = instantiate_prefab(enemy_prefab, NodeData(position = float3(5, 1, 0)))
```

### Добавить Более Сложный Уровень

Создай в редакторе визуально, сохрани как prefab → загружай в main.das

---

## Резюме: Правильная Архитектура

✅ **Делай:**
- Используй префабы для переиспользуемых объектов
- Держи main.das чистым и коротким (только загрузка)
- Компоненты в префабе - для специфичной логики
- CharacterController для персонажей

❌ **Не делай:**
- Не создавай всё в main.das
- Не смешивай RigidBody + CharacterController
- Не игнорируй структуру папок

**Твой проект организован ПРАВИЛЬНО!** 🎯
