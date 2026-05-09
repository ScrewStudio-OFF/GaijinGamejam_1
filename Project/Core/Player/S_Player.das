require engine.core
require engine.input.global_input_state
require engine.math.math_utils
require Project.Mechanics.Abilities.S_AbilityBase

// Класс для управления движением игрока в слешере (вид сверху)
// Абсолютное управление: WASD двигает в экранном пространстве
// Курсор определяет направление поворота
class SPlayer : Component {
    move_direction : float3 = float3(0)           // Текущее направление движения (X, 0, Z)
    vertical_velocity : float = 0.0               // Скорость падения (Y)
    MOVE_SPEED : float = 8.0                      // Скорость движения (единиц/сек)
    FRICTION : float = 0.85                       // Коэффициент трения
    GRAVITY : float = -15.0                       // Ускорение гравитации (м/сек²)
    character_controller : CharacterController?   // Ссылка на CharacterController
    camera : Camera?                              // Ссылка на камеру
    abilityComponents : array<SAbilityBase?>


    def override on_initialize() : void {
        // Вызывается один раз когда компонент создаётся на ноде
        move_direction = float3(0)
        vertical_velocity = 0.0
        
        // === ПОЛУЧАЕМ CharacterController ===
        get_component(nodeId) $(var cc : CharacterController?) {
            character_controller = cc
        }
        
        // === ИЩЕМ КАМЕРУ В СЦЕНЕ ===
        // Сначала пытаемся найти камеру на этой же ноде
        get_component(nodeId) $(var cam : Camera?) {
            camera = cam
        }
        
        // Если нет - ищем главную камеру в сцене
        if (camera == null) {
            camera = find_component(type<Camera>)
        }
        
        // === ПОКАЗЫВАЕМ КУРСОР ===
        show_mouse_cursor(true)
        
        // === НАСТРОЙКА УПРАВЛЕНИЯ ===
        add_and_activate_action_set("playerInput", {
            "move" => Action(
                joystickActions = JoystickAction(
                    keyboardDPads = [
                        KeyboardDPadInput(
                            leftIdx = KeyCode.A,     // A = влево по экрану
                            rightIdx = KeyCode.D,    // D = вправо по экрану
                            upIdx = KeyCode.W,       // W = вверх по экрану
                            downIdx = KeyCode.S      // S = вниз по экрану
                        )
                    ]
                )
            )
        })

        refresh_abilities()
    }


    def override on_update() : void {
        // Вызывается каждый кадр (~60 раз в секунду)
        let dt = get_delta_time()
        
        // === ПОЛУЧАЕМ ВВОД (АБСОЛЮТНОЕ УПРАВЛЕНИЕ) ===
        let move_input = get_action_vector2("move")
        
        // === ПРЕОБРАЗУЕМ В 3D (ЭКРАННЫЕ КООРДИНАТЫ) ===
        var screen_input = float3(move_input.x, 0.0, move_input.y)
        
        // === ПРИМЕНЯЕМ СКОРОСТЬ И ТРЕНИЕ ===
        if (length(screen_input) > 0.01) {
            screen_input = normalize(screen_input)
            move_direction = screen_input * MOVE_SPEED
        } else {
            move_direction = move_direction * FRICTION
        }
        
        // === ГРАВИТАЦИЯ ===
        vertical_velocity += GRAVITY * dt

        var facing_forward = FORWARD

        // === ПОЛУЧАЕМ НАПРАВЛЕНИЕ КУРСОРА ДЛЯ ПОВОРОТА И ДЭША ===
        if (camera != null) {
            let mouse_screen_pos = get_mouse_position()
            let ray = camera.screenToRay(mouse_screen_pos)
            let current_pos = nodeId.localPosition
            var cursor_world_pos : float3

            if (ray_intersect_plane(ray, current_pos, UP, cursor_world_pos)) {
                var direction_to_cursor = cursor_world_pos - current_pos
                direction_to_cursor.y = 0.0

                if (length(direction_to_cursor) > 0.001) {
                    direction_to_cursor = normalize(direction_to_cursor)
                    facing_forward = direction_to_cursor
                    nodeId.localRotation = quat4(FORWARD, direction_to_cursor)
                }
            }
        }

        // === СОБИРАЕМ ЭФФЕКТЫ СПОСОБНОСТЕЙ ===
        refresh_abilities()

        var ability_add_velocity = float3(0)
        var override_horizontal = false
        var highest_priority = -1000000000
        var override_velocity = float3(0)
        let is_grounded = (character_controller != null && character_controller.state == CharacterState.OnGround)
        let ability_context = AbilityContext(
            dt = dt,
            moveInput = move_input,
            facingForward = facing_forward,
            isGrounded = is_grounded
        )

        for (ability in abilityComponents) {
            if (ability != null && ability.isAbilityEnabled) {
                let motion = ability.collect_motion(ability_context)
                ability_add_velocity += motion.addVelocity

                if (motion.overrideVelocity && motion.priority >= highest_priority) {
                    highest_priority = motion.priority
                    override_velocity = motion.overrideHorizontal
                    override_horizontal = true
                }
            }
        }

        var final_horizontal_velocity = move_direction
        if (override_horizontal) {
            final_horizontal_velocity = override_velocity
        }

        final_horizontal_velocity += ability_add_velocity

        // === ПРИМЕНЯЕМ ДВИЖЕНИЕ ЧЕРЕЗ CharacterController ===
        if (character_controller != null) {
            character_controller.velocity = float3(
                final_horizontal_velocity.x,
                vertical_velocity,
                final_horizontal_velocity.z
            )
            
            // Если персонаж на земле - обнуляем гравитацию
            if (character_controller.state == CharacterState.OnGround) {
                vertical_velocity = 0.0
            }
        }
    }


    def override on_destroy() : void {
        pass
    }
    
    //Abilities
    def private refresh_abilities() : void {
        resize(abilityComponents, 0)

        let comps = get_components(nodeId)
        for (comp in comps) {
            if (comp is SAbilityBase) {
                var ability = comp as SAbilityBase
                if (ability != null) {
                    push(abilityComponents, ability)
                }
            }
        }
    }
}