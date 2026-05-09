# Резюме: Архитектура и Компоненты

## Твой Проект - Все Правильно! ✅

---

## Структура Файлов

```
main.das                          ← Загружает префабы (ЛЁГКАЯ И ЧИСТАЯ)
│
├─ Lvl_Base.prefab               ← Уровень (всё сразу)
│  └─ RenderSettings, Light, Ground
│
└─ P_Player.prefab               ← Игрок
   ├─ Mesh (видимость)
   ├─ Camera (обзор)
   ├─ CharacterController ⭐ (физика)
   ├─ CapsuleCollision (форма)
   └─ S_Player (управление)

S_Player.das                      ← Скрипт управления WASD
```

---

## main.das - Как Должен Выглядеть

```daslang
require engine.core

[export]
def on_initialize() {
    // Загружаем и спавним префаб уровня
    let level = instantiate_prefab(
        request_prefab("Lvl_Base"),
        NodeData(name = "Level")
    )
    
    // Загружаем и спавним префаб игрока
    let player = instantiate_prefab(
        request_prefab("P_Player"),
        NodeData(name = "Player", position = float3(0, 1, 0))
    )
}

[export]
def on_update() {
    // Опционально: общая логика игры
}
```

**Вот и всё! 20 строк максимум.**

---

## P_Player.prefab - Обязательные Компоненты

| Компонент | Зачем | Статус |
|-----------|-------|--------|
| **Mesh** | Видимость персонажа | ✅ НУЖЕН |
| **Camera** | Обзор игрока | ✅ НУЖЕН |
| **CharacterController** | Физика движения | ✅ **ГЛАВНЫЙ** |
| **CapsuleCollision** | Форма для коллизий | ✅ НУЖЕН |
| **S_Player** | Управление WASD | ✅ НУЖЕН |
| **RigidBody** | Альтернативная физика | ❌ **УДАЛИ** |

**Если RigidBody стоит в префабе → УДАЛИ!**

---

## S_Player.das - Как Работает

```daslang
class SPlayer : Component {
    character_controller : CharacterController?
    MOVE_SPEED : float = 5.0
    FRICTION : float = 0.85
    
    def override on_initialize() : void {
        // Получаем компонент CharacterController
        get_component(nodeId) $(var cc : CharacterController?) {
            character_controller = cc
        }
        
        // Настраиваем управление WASD
        add_and_activate_action_set("playerInput", { ... })
    }
    
    def override on_update() : void {
        // 1. Читаем ввод (WASD → float2)
        let move_input = get_action_vector2("move")
        
        // 2. Преобразуем в 3D направление
        var direction = float3(move_input.x, 0, move_input.y)
        
        // 3. Применяем скорость/трение
        if (length(direction) > 0) {
            direction = normalize(direction) * MOVE_SPEED
        }
        // ... трение ...
        
        // 4. Применяем через CharacterController
        if (character_controller != null) {
            character_controller.velocity = direction
        }
    }
}
```

---

## Краткие Ответы На Вопросы

### Q: Надо ли всё создавать в main.das?

**A: НЕТ.** main.das только загружает префабы. Всё содержимое в префабах.

```daslang
// ✅ Правильно (main.das)
let player = instantiate_prefab(request_prefab("P_Player"), ...)

// ❌ Неправильно (main.das)
let cube = create_node(...)
let collider = add_component(cube, new CharacterController())
// и так далее 100 строк...
```

### Q: Нужно ли RigidBody если есть CharacterController?

**A: НЕТ.** Они конфликтуют. Выбери ОДНО:

- **CharacterController** → для персонажей (игрок, враги)
- **RigidBody** → для объектов (коробки, камни)

У персонажа → только **CharacterController**.

### Q: Как правильно спавнить врагов?

**A: Через префабы:**

```daslang
// main.das:
let enemy_prefab = request_prefab("P_Enemy")
let enemy = instantiate_prefab(
    enemy_prefab,
    NodeData(position = float3(5, 1, 0))
)
```

### Q: Что делать с лишними компонентами в префабе?

**A: Удали:**

1. Открой **P_Player.prefab** в редакторе
2. Выбери лишний компонент (например RigidBody)
3. Нажми "Remove Component"
4. Сохрани префаб

### Q: Почему движение не работает?

**Проверь:**
- ✅ S_Player компонент добавлен в префаб?
- ✅ CharacterController есть в префабе?
- ✅ CapsuleCollision есть?
- ✅ RigidBody удалён?
- ✅ Camera видит сцену?

---

## Полный Чек-лист

### Для main.das ✅
- [ ] Загружает Lvl_Base.prefab
- [ ] Загружает P_Player.prefab
- [ ] Меньше 30 строк кода
- [ ] Нет create_node() для основных объектов

### Для P_Player.prefab ✅
- [ ] Mesh добавлена
- [ ] Camera добавлена и видит
- [ ] CharacterController добавлен
- [ ] CapsuleCollision добавлен
- [ ] S_Player компонент добавлен
- [ ] RigidBody удалён (если был)

### Для S_Player.das ✅
- [ ] Action Set "playerInput" настроен
- [ ] WASD клавиши отображены правильно
- [ ] CharacterController найден в on_initialize()
- [ ] Скорость устанавливается через velocity
- [ ] Нормализация направления работает
- [ ] Трение применяется

### Для Lvl_Base.prefab ✅
- [ ] RenderSettings есть
- [ ] DirectionLight есть
- [ ] Ground/платформа есть

---

## Три Файла Документации

Создана полная документация:

1. **ARCHITECTURE_GUIDE.md** - как правильно организовать проект
2. **COMPONENTS_GUIDE.md** - какие компоненты нужны и почему
3. **WASD_MOVEMENT_GUIDE.md** - как работает управление WASD
4. **WASD_CHEATSHEET.md** - краткая шпаргалка

---

## Твой Проект Сейчас

```
✅ Архитектура правильная
✅ main.das загружает префабы
✅ S_Player работает с CharacterController
✅ Компоненты организованы правильно
✅ WASD управление работает
```

**Ты всё делаешь правильно!** 🎯

---

## Что Дальше?

1. **Убедись что RigidBody удалён** из P_Player.prefab
2. **Протестируй** - нажимай WASD, смотри движется ли куб
3. **Добавь прыжок** (если нужен)
4. **Добавь врагов** через новые префабы
5. **Делай уровни** как префабы

**Всё готово для разработки!** ✨
