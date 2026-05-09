# Быстрая Инструкция: Что Сейчас Делать

## Текущее Состояние ✅

```
✅ main.das - загружает префабы
✅ S_Player.das - работает с CharacterController
✅ Игра компилируется и запускается
```

---

## Шаг 1: Очистить P_Player.prefab (ВАЖНО!)

### Если в префабе RigidBody:

1. Открой **P_Player.prefab** в редакторе EdenSpark
2. Выбери компонент **RigidBody** на ноде Player
3. Нажми **"Remove Component"** или удали его
4. **Сохрани** префаб
5. Перезагрузи игру (F5)

### Проверка:

Должны остаться **ровно эти компоненты:**
- ✅ Mesh
- ✅ Camera
- ✅ CharacterController
- ✅ CapsuleCollision
- ✅ S_Player

---

## Шаг 2: Протестировать Управление

1. Запусти игру (F5)
2. Нажимай **W, A, S, D**
3. Смотри движется ли куб (Player)

### Если не движется:

**Возможная причина:** RigidBody ещё стоит в префабе

**Решение:** Повтори Шаг 1

---

## Шаг 3: Разобраться в Коде

Три главных файла для изучения:

### 1. **main.das** - Точка Входа

```daslang
[export] def on_initialize() {
    // Загружаем уровень
    let level = instantiate_prefab(
        request_prefab("Lvl_Base"),
        NodeData(name = "Level")
    )
    
    // Загружаем игрока
    let player = instantiate_prefab(
        request_prefab("P_Player"),
        NodeData(name = "Player", position = float3(0, 1, 0))
    )
}
```

**Что тут происходит:**
- `request_prefab("Lvl_Base")` - ищет файл Lvl_Base.prefab
- `instantiate_prefab()` - создаёт копию в сцене
- Всё. Остальное в компонентах.

### 2. **S_Player.das** - Управление

```daslang
// on_initialize():
// 1. Ищем CharacterController на этой же ноде
get_component(nodeId) $(var cc : CharacterController?) {
    character_controller = cc
}

// 2. Настраиваем WASD
add_and_activate_action_set("playerInput", { ... })

// on_update():
// 1. Читаем ввод
let move_input = get_action_vector2("move")

// 2. Применяем в CharacterController
character_controller.velocity = direction
```

**Ключевой момент:** Используем `character_controller.velocity`, а не `localPosition`

### 3. **P_Player.prefab** - Компоненты

Это визуальное объединение всех компонентов:
- Mesh = видимость
- Camera = обзор
- CharacterController = физика ⭐
- CapsuleCollision = форма столкновения
- S_Player = скрипт (его код из S_Player.das)

---

## Шаг 4: Добавить Прыжок (Опционально)

Если хочешь прыжок, раскомментируй в S_Player.das:

```daslang
// В on_initialize():
add_and_activate_action_set("playerInput", {
    "move" => Action(...),
    "jump" => Action(
        joystickActions = JoystickAction(
            keyboardKeys = [KeyboardKeyInput(keyIdx = KeyCode.Space)]
        )
    )
})

// В on_update():
// Добавить после получения move_input:
if (is_action_just_pressed("jump") && character_controller.isGrounded) {
    // Прыгаем
    character_controller.velocity.y = JUMP_FORCE
}
```

---

## Шаг 5: Изучи Документацию

Создана полная документация:

1. **README_ARCHITECTURE.md** ← **НАЧНИ ОТСЮДА**
2. **ARCHITECTURE_GUIDE.md** - глубокий разбор архитектуры
3. **COMPONENTS_GUIDE.md** - компоненты и их роли
4. **WASD_MOVEMENT_GUIDE.md** - подробно про движение
5. **WASD_CHEATSHEET.md** - быстрая шпаргалка

---

## Шаг 6: Что Дальше в Проекте

### Вариант А: Расширить Движение
- Добавить камеру от третьего лица
- Добавить прыжок
- Добавить спринт (Shift)
- Добавить анимации

### Вариант Б: Добавить Врагов
1. Создать **P_Enemy.prefab** (копируй P_Player, убрать Camera)
2. Создать **S_Enemy.das** (поведение врага)
3. Спавнить в main.das

### Вариант В: Создать Уровень
1. Открой **Lvl_Base.prefab**
2. Добавь платформы, препятствия
3. Сохрани как **Lvl_Tutorial.prefab**
4. Загружай в main.das

---

## Как Это Работает На Практике

```
Запуск Игры:
    ↓
main.das on_initialize()
    ↓
Загружает request_prefab("Lvl_Base")
    ↓
Создаёт уровень instantiate_prefab()
    ↓
Загружает request_prefab("P_Player")
    ↓
Создаёт игрока с компонентами:
    - Mesh (видимо)
    - Camera (видит)
    - CharacterController (движется)
    - CapsuleCollision (коллизии)
    - S_Player (слушает WASD)
    ↓
on_update() каждый кадр:
    - S_Player читает WASD
    - Устанавливает character_controller.velocity
    - CharacterController сам двигает персонажа
    ↓
Персонаж движется! ✅
```

---

## Быстрая Проверка Ошибок

### Ошибка: Чёрный экран
- Проверь Camera в P_Player.prefab
- Проверь RenderSettings в Lvl_Base.prefab

### Ошибка: Не движется
- RigidBody стоит? → Удали!
- CharacterController найдена? → Check on_initialize()

### Ошибка: Странное движение
- RigidBody + CharacterController вместе? → Удали RigidBody!

### Ошибка: Компиляция не проходит
- Проверь синтаксис (скобки, точки с запятой)
- Проверь имена функций (get_component, add_component и т.д.)

---

## Рекомендуемый Порядок Действий

```
1️⃣  СЕЙЧАС: Удали RigidBody из P_Player.prefab
2️⃣  СЕЙЧАС: Протестируй WASD управление
3️⃣  СЕГОДНЯ: Раскомментируй код прыжка (если нужен)
4️⃣  ЭТОЙ НЕДЕЛЕ: Добавь анимации и звуки
5️⃣  ПОТОМ: Враги, уровни, геймплей
```

---

## Полезные Ссылки (Локальные Файлы)

В папке проекта теперь есть:
- [WASD_CHEATSHEET.md](WASD_CHEATSHEET.md) - копипаста код
- [README_ARCHITECTURE.md](README_ARCHITECTURE.md) - начни отсюда
- [ARCHITECTURE_GUIDE.md](ARCHITECTURE_GUIDE.md) - глубокий разбор
- [COMPONENTS_GUIDE.md](COMPONENTS_GUIDE.md) - про компоненты

---

## Твоя Задача На Завтра

✅ **Минимум:** Убедиться что WASD работает (RigidBody удалён)
✅ **Хорошо:** Разобраться в коде, прочитать документацию
✅ **Отлично:** Добавить прыжок и спринт

---

## Готово? ✨

Теперь ты знаешь:
- Как правильно организовать проект
- Как работают префабы
- Как работает CharacterController
- Как работает управление WASD
- Что стоит удалить (RigidBody)

**Ты готов разрабатывать игру!** 🎮

**Следующий шаг:** [Удали RigidBody и протестируй!]
