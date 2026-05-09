# EdenSpark Keyboard Input & Node Position Update Reference

Based on documentation and samples from EdenSpark, here are the exact patterns for handling WASD input and moving game objects.

---

## 1. WASD Keyboard Input Handling

### Recommended Approach: Action Set System (Best Practice)

The **Action Set system** is the recommended way to handle input in EdenSpark. It provides cross-platform support (keyboard, gamepad, mouse) automatically.

#### Step 1: Initialize Action Set with WASD Mapping

In your `on_initialize()` function, define an action set with WASD keys:

```daslang
[export]
def on_initialize() {
    // Define and activate the "playerInput" action set
    add_and_activate_action_set("playerInput", {
        "move" => Action(
            joystickActions = JoystickAction(
                keyboardDPads = [KeyboardDPadInput(
                    leftIdx = KeyCode.A,
                    rightIdx = KeyCode.D,
                    upIdx = KeyCode.W,
                    downIdx = KeyCode.S
                )],
                sticks = [GamepadStickInput(
                    xIdx = GamepadAxis.LThumbH,
                    yIdx = GamepadAxis.LThumbV
                )]
            )
        ),
        "jump" => Action(
            buttonActions = ButtonAction(
                keyboardButtons = [KeyboardButtonInput(idx = KeyCode.Space)],
                gamepadButtons = [GamepadButtonInput(idx = GamepadButton.X)]
            )
        )
    })
}
```

**KeyCode values for keyboard:**
- `KeyCode.W` - W key
- `KeyCode.A` - A key
- `KeyCode.S` - S key
- `KeyCode.D` - D key
- `KeyCode.Space` - Spacebar
- `KeyCode.Up`, `KeyCode.Down`, `KeyCode.Left`, `KeyCode.Right` - Arrow keys

#### Step 2: Read Input in Update Loop

Use these functions to check input state:

```daslang
def override on_update() {
    // Get 2D movement vector (returns float2 with range -1 to 1)
    let moveDirection = get_action_vector2("move")  // e.g. (-1, 0) if moving left
    
    // Check if button just pressed (edge trigger - once per press)
    if (is_action_just_pressed("jump")) {
        // Jump was just pressed
    }
    
    // Check if button is held down (continuous)
    if (is_action_pressed("jump")) {
        // Jump is being held
    }
    
    // Check if button just released
    if (is_action_just_released("jump")) {
        // Jump was just released
    }
}
```

**Key Action Query Functions:**
- `get_action_vector2(action_name: string) : float2` - Returns 2D vector for joystick/DPAD actions (-1 to 1 range)
- `get_action_axis(action_name: string) : float` - Returns 1D axis value (-1 to 1)
- `is_action_pressed(action_name: string) : bool` - True while button held
- `is_action_just_pressed(action_name: string) : bool` - True only on frame pressed
- `is_action_just_released(action_name: string) : bool` - True only on frame released

---

### Alternative: Direct Key Functions (Not Recommended)

If you need direct key checking without action sets, use raw input (deprecated but simpler for quick prototypes):

```daslang
// Not recommended for production
if (key_pressed(KeyCode.W)) {
    // W is pressed
}

if (key_down(KeyCode.Space)) {
    // Space is held
}
```

---

## 2. Move Component-Based Game Object (Update Node Position)

### Pattern: Update Position in on_update()

In EdenSpark, nodes have a `localPosition` property that can be directly modified from a Component or game logic.

#### From Within a Component Class:

```daslang
require engine.core

class PlayerController : Component {
    velocity : float3 = float3(0)
    moveSpeed : float = 5.0

    def override on_initialize() {
        velocity = float3(0)
    }

    def override on_update() {
        // Get input
        let moveDir = get_action_vector2("move")  // Returns (-1..1, -1..1)
        
        // Calculate velocity based on input
        velocity.x = moveDir.x * moveSpeed
        velocity.z = moveDir.y * moveSpeed
        
        // Apply delta time
        let deltaTime = get_delta_time()
        
        // Update node position
        // nodeId is the component's owning node (automatically available)
        nodeId.localPosition = nodeId.localPosition + velocity * deltaTime
        
        // OR using direct assignment
        var newPos = nodeId.localPosition
        newPos = newPos + float3(moveDir.x * moveSpeed * deltaTime, 0, moveDir.y * moveSpeed * deltaTime)
        nodeId.localPosition = newPos
    }
}
```

#### From External Game Logic:

```daslang
def move_node(node : NodeId, offset : float3) {
    node.localPosition = node.localPosition + offset
}

def set_node_position(node : NodeId, pos : float3) {
    node.localPosition = pos
}

// In your update loop:
update_scene() {
    if (player.active) {
        // Update position
        player.node.localPosition = float3(player.position, 2.1)  // float3(x, y, z)
        
        // Update scale/rotation
        player.node.localScale = float3(player.scale_x, 1.0, 1.0)
    }
}
```

### Real Example from Platformer Sample:

```daslang
def update_player(dt : float) {
    // Physics simulation - update velocity and position
    var prevPos = player.position
    var nextPos = player.position + player.velocity * dt
    
    // Collision detection...
    // (code omitted)
    
    // Update internal position variable
    player.position = nextPos
}

def update_scene() {
    // Sync the node's visual position to the game object position
    if (player.active) {
        player.node.localPosition = float3(player.position, 2.1)
        player.node.localScale = float3(player.lastMoveDirectionSign, 1.0, 1.0)
    }
}

// Call both per frame:
[export]
def on_frame() {
    update_player(get_delta_time())
    update_scene()
}
```

---

## 3. Access Node Position from Component

### Get Node Reference in Component:

Inside a Component class, use `nodeId` to reference the owning node:

```daslang
class PlayerMovement : Component {
    def override on_update() {
        // nodeId is automatically available - it's the node this component is attached to
        
        // Read current position
        let currentPos = nodeId.localPosition
        print("Current position: {currentPos}")
        
        // Modify position
        nodeId.localPosition = nodeId.localPosition + float3(1.0, 0, 0)
        
        // Read scale
        let scale = nodeId.localScale
        
        // Read rotation
        let rotation = nodeId.localRotation
        
        // Read name
        let nodeName = nodeId.name
    }
}
```

### Node Properties Available in Component:

```daslang
// Position and Transform
nodeId.localPosition : float3      // Position relative to parent
nodeId.worldPosition : float3      // Absolute world position
nodeId.localRotation : quat4       // Rotation as quaternion
nodeId.localScale : float3         // Scale

// Hierarchy
nodeId.name : string               // Node name
nodeId.parent : NodeId             // Parent node
nodeId.isActive : bool             // Is node active
nodeId.isAlive : bool              // Is node still valid

// Children
get_child(nodeId, index) : NodeId
nodeId.get_children() : array<NodeId>
```

### Safe Component Access Pattern:

When accessing other components on a node, use the safe navigation pattern:

```daslang
// Safe optional access
if (nodeId?.Mesh) {
    nodeId?.Mesh.color = float4(1, 0, 0, 1)
}

// Block-based access (recommended)
get_component(nodeId) $(var mesh : Mesh?) {
    if (mesh != null) {
        mesh.color = float4(1, 0, 0, 1)
    }
}
```

---

## 4. Complete Working Example: Player Controller Component

```daslang
require engine.core

class PlayerController : Component {
    moveSpeed : float = 5.0
    velocity : float3 = float3(0)
    lastMoveDir : float2 = float2(0)

    def override on_initialize() {
        velocity = float3(0)
    }

    def override on_update() {
        // 1. READ INPUT
        let moveDir = get_action_vector2("move")
        lastMoveDir = moveDir
        
        // 2. UPDATE VELOCITY
        velocity.x = moveDir.x * moveSpeed
        velocity.z = moveDir.y * moveSpeed
        
        // 3. APPLY MOVEMENT TO NODE
        let deltaTime = get_delta_time()
        nodeId.localPosition = nodeId.localPosition + velocity * deltaTime
        
        // 4. OPTIONAL: Rotate to face direction
        if (length(moveDir) > 0.0) {
            let angle = atan2(moveDir.y, moveDir.x)
            nodeId.localRotation = quat4(0, angle, 0)
        }
        
        print("Position: {nodeId.localPosition}, Velocity: {velocity}")
    }

    def override on_destroy() {
        pass
    }
}
```

### In on_initialize() of main script:

```daslang
[export]
def on_initialize() {
    // Setup input
    add_and_activate_action_set("playerInput", {
        "move" => Action(
            joystickActions = JoystickAction(
                keyboardDPads = [KeyboardDPadInput(
                    leftIdx = KeyCode.A,
                    rightIdx = KeyCode.D,
                    upIdx = KeyCode.W,
                    downIdx = KeyCode.S
                )]
            )
        )
    })
    
    // Create player node and attach controller
    let playerNode = create_node(NodeData(position = float3(0)))
    add_component(playerNode, new PlayerController())
}
```

---

## Summary: Exact Function Names

### Input Functions:
- `add_and_activate_action_set(name: string, actions: ActionSet) : void`
- `get_action_vector2(action_name: string) : float2`
- `get_action_axis(action_name: string) : float`
- `is_action_pressed(action_name: string) : bool`
- `is_action_just_pressed(action_name: string) : bool`
- `is_action_just_released(action_name: string) : bool`

### Position/Node Functions:
- `nodeId.localPosition : float3` - Get/set position (property access)
- `nodeId.localScale : float3` - Get/set scale
- `nodeId.localRotation : quat4` - Get/set rotation
- `nodeId.worldPosition : float3` - Get world position
- `get_delta_time() : float` - Frame delta time in seconds
- `nodeId.name : string` - Get node name
- `nodeId.isAlive : bool` - Check if node exists

### Required Imports:
```daslang
require engine.core  // Contains all input and scene functions
```

---

## Resources

**Sample Projects Reference:**
- Platformer with full input/movement: `C:/Users/stasd/AppData/Local/EdenSpark/samples/games/platformer_sample/`
- Tanks with WASD control: `C:/Users/stasd/AppData/Local/EdenSpark/samples/games/tanks_demo/`

**Documentation:**
- Input API: `C:/Users/stasd/AppData/Local/EdenSpark/docs/source/input_index.rst`
- Action Sets: `C:/Users/stasd/AppData/Local/EdenSpark/docs/source/index/action_set_core.rst`
- Components: `C:/Users/stasd/AppData/Local/EdenSpark/docs/source/components_index.rst`
