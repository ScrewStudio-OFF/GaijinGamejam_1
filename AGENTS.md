# EdenSpark Game Project

## Documentation

Use documentation for EdenSpark and Daslang from Context7 in the first place.
If Context7 is not available use local documentation bundled with EdenSpark:

- **API reference (RST):** `C:/Users/stasd/AppData/Local/EdenSpark/docs`

In case you couldn't find required functionality in documentation look into usages in samples bundled with EdenSpark:

- **Sample projects:** `C:/Users/stasd/AppData/Local/EdenSpark/samples`

## Language: Gen2 daScript

Eden user scripts use Gen2 daScript — a statically typed scripting language with C-like braces syntax. This is the "Gen2" variant which uses braces `{}` and parentheses `()` instead of the original Python-like indentation-based syntax.

## Core Syntax Rules

### Braces and Parentheses — Always Required
- Functions ALWAYS use braces: `def foo() { ... }`
- Conditions ALWAYS use parentheses AND braces: `if (x > 0) { ... } elif (x == 0) { ... } else { ... }`
- Loops ALWAYS use parentheses AND braces: `for (i in range(10)) { ... }`, `while (condition) { ... }`

### Variables
- `let` for immutable, `var` for mutable
- Module-level constants: `UPPER_SNAKE_CASE`
- Prefer `let` over `var` when value won't change

### Type Annotations
Type annotations use `:` after the name. Optional when type can be inferred: `let x : int = 5`, `var nodes : array<NodeId>`, `var arr : NodeId[15]` (fixed-size)

### Functions
- `def name(params) : ReturnType { ... }` — return type optional when inferrable
- Default values: `def setup(speed : float = 1.0) { ... }`
- Generic/untyped parameter: `def set_status(str) { ... }` (type inferred)

### String Interpolation
Use `{}` inside string literals: `print("position: {position}")`, `text.text = "{get_current_score()}"`

### Modules and Imports
- `require engine.core` — import engine modules
- `require MyModule` — import local modules (same project)
- `module mod` — declare a module (comes after `require` statements)
- `module trackSegmentGen public` — `public` re-exports imports

### Export Annotation
Functions called by the engine must have `[export]`: `[export] def on_initialize() { ... }`

## Type System

### Primitive Types
`int`, `uint`, `float`, `double`, `bool`, `string`

### Vector/Math Types
`float2`, `float3`, `float4`, `int2`, `int3`, `uint3`, `quat4`

### Constructors
- `float3(0)` — shorthand for `float3(0, 0, 0)`
- `quat4(0, PI * 0.3f, 0)` — euler angles in radians
- Both `1.0` and `1f` are float literals; `2.1lf` is double

### Arrays
- Dynamic: `var cubes : array<NodeId>`, use `resize()`, `push()`
- Fixed-size: `var arr : NodeId[15]`
- Literal with move: `var arr <- [a, b, c]`
- `fixed_array(...)` for typed fixed arrays

### Tables (Hash Maps)
`var map <- { "key" => value }`, access with `map.get_value(key)`

### Structs
`struct Name { field : type = default }`, construct with `Name()` or `Name(field = val)`

### Enums
`enum Name { Value1 = 0, Value2 = 1 }`, access with `Name.Value1`

### Move Semantics
Use `<-` for move assignment (transfers ownership): `return <- mesh`, `var bitmap <- Bitmap(w, h)`

## Classes and Components

### Component Classes
Components inherit from `Component`, attach to scene nodes. Override `on_initialize`, `on_update`, `on_destroy`. Fields are public/serialized by default.

### Visibility Modifiers
- `private` — private field or method
- `@no_export` — field not serialized to prefab
- Methods can be `public`, `private`, `abstract`

### Collision Listeners
Inherit from `CollisionListener`, override `on_collision(c : Collision)`, `on_collision_stay(c : Collision)`, `on_collision_exit(node : NodeId)`

### Method Syntax
Methods can omit `()` when no parameters: `def override on_update { ... }`

## Control Flow

- `if / elif / else` — note: `elif` not `else if`
- `for (i in range(10)) { }`, `for (i in 0 .. n) { }` (half-open range)
- Multiple iterators (zip): `for (node, i in nodes, count()) { }`
- Ternary: `let val = (cond ? a : b)`
- Variant matching: `if (cmd is Type) { let x = cmd as Type; ... }`

## Blocks and Lambdas

- **Blocks** (capture by reference): `$(args) { body }` — used as last argument after `)`
- **Lambdas** (function pointers, no capture): `@@(args) { body }`
- **Closures** (capture outer vars): `@(args) { body }`
- No-arg lambda: `@() { ... }`
- Block as last argument goes after closing `)`: `get_component(nodeId) $(var mesh : Mesh?) { ... }`

## Scene API Patterns

### Creating Nodes
`create_node()` or `create_node(NodeData(name = "cube", position = ..., rotation = ..., parent = ..., scale = ...))`

### Adding Components
`add_component(node, new Mesh(meshId = CUBE_MESH_ID))` — returns component pointer. Method syntax: `node.add_component(...)`

### Getting Components
- Block-based (safe): `get_component(nodeId) $(var text : UIText?) { ... }`
- Type-based: `var cam = get_component(node, type<Camera>)`
- Safe navigation: `var cam = node?.Camera`
- Require (creates if missing): `require_component(node, type<Camera>)`
- Find globally: `find_component(type<UICanvas>)`, `find_components(type<CameraFocus>)`, `find_components(array)`

### Node Properties
- Position/rotation/scale: `nodeId.localPosition`, `nodeId.worldPosition`, `nodeId.localRotation`, `nodeId.localScale`
- `nodeId.name`, `nodeId.isActive`, `nodeId.isAlive`, `nodeId.parent`
- `set_position(node, pos)`, `set_scale(node, scale)`
- Parenting: `nodeId.set_parent(parent, AddChildStrategy.KeepLocalTransform)`
- Children: `nodeId.get_children()`, `get_child(node, index)`
- `remove_node(nodeId)`, `duplicate_node(original, NodeData(...))`

### Prefabs
`request_prefab("path.prefab")` then `instantiate_prefab(prefab, NodeData(...))`

## Annotations
- `[export]` — expose to engine
- `[cheat]` — register as cheat command
- `[hot_reload_class]` — class survives hot-reload

## Code Style Conventions

### Naming
- Variables/parameters: `camelCase`
- Functions: `snake_case` for utilities, `camelCase` for methods/callbacks
- Constants (module-level `let`): `UPPER_SNAKE_CASE`
- Classes/Structs/Enums: `PascalCase`
- Enum values: `PascalCase`

### Formatting
- 4 spaces indentation
- Opening brace on same line
- 2 blank lines between top-level functions; 1 between methods in a class
- `//` comments, `////` lines for section dividers

### Patterns
- UFCS: both `f(x)` and `x.f()` valid; pipe: `grid |> resize(n)`
- `inscope` for scoped lifetime: `var inscope children = nodeId.get_children()`
- String interpolation preferred over concatenation
- `pass` for empty bodies

## Known Gen2 Syntax Pitfalls

### No Semicolons Between Statements
Each statement must be on its own line. Semicolons between statements cause silent compilation failure.

### No Inline If-Braces for Vector/Struct Assignments
`if (cond) { var = float4(...) }` on a single line causes compilation failure for vector types. Always use multiline blocks.

### No Early Returns of Vector Types
Cannot use `if (x) { return float4(...) }`. Use a mutable variable with a single return at the end.

### Compilation Errors Are Often Silent
Engine reports "compilation failed" but error text is frequently empty/truncated. Debug by bisecting — comment out half the code until error is found.

### Enum/Bitfield Access Syntax
Use dot notation: `MeshVisibility.VisibleInAnyCamera`. Some engine enums use space syntax: `MouseButton Left` — try dot first.

## Mouse Input

### Available Functions
- `is_any_mouse_button_pressed()` — true every frame while any button held
- `is_mouse_moved()` — true if mouse moved this frame
- `get_mouse_position()`, `mouse_button_pressed()` may NOT compile depending on engine version

### Getting Mouse Position — UICanvas Workaround
Use `get_ui_mouse_position(nodeId)` on a child of a `UICanvas`. Returns `float3`: offset from viewport center, Y axis points DOWN.

### Converting UI Position to Pixel Coordinates
Calibrate viewport center using `cam.worldToScreen(float3(0,0,0))` at init, then: `pixel = float2(uiPos.x + viewOffX, uiPos.y + viewOffY)`

### Detecting Press/Release Edges
Track previous frame state manually: compare `is_any_mouse_button_pressed()` this frame vs `prevMouseDown`.

## Mesh Creation

- Sphere: `create_sphere_mesh(SphereInit(subdivisions = 24, radius = 0.5))`
- Cylinder: `create_cylinder_mesh(CylinderInit(height = 1.4, radius = 0.28))` — default axis Y
- Custom: `create_mesh(geo)` from `create_sphere_mesh_geometry(...)` (requires `engine.gen_geometry.mesh_structures`)
- Visibility: `node?.Mesh.visibility = MeshVisibility.VisibleInAnyCamera` (no shadows), `MeshVisibility.FullVisibility` (default)

## Physics / Ray Picking

### Collider Setup
`add_component(node, new Collider(shape = box_shape()))` — also `sphere_shape(radius=...)`, `cylinder_shape(radius=..., height=...)`. Colliders work without Mesh.

### Raycasting
`trace(RayCast(ray = ray)) $(hit) { ... }` — only detects nodes with Collider or RigidBody. Hit provides: `position`, `nodeId`, `normal`, `distance`. For all hits: `trace_all(rayCast) $(hits) { ... }`

## Camera

- Orthographic: `cam.orthographic = true; cam.orthographicSize = 8.0`
- `cam.screenToRay(float2(px, py))` — screen pixels to world ray
- `cam.worldToScreen(float3(x,y,z))` — world to screen pixels (z = depth)
- `cam.screenToWorldDepth(float2(px,py), depth)` — screen to world at depth
- `quat4(rx, ry, rz)` — rotation in radians: `quat4(PI*0.5, 0, 0)` = 90° around X

## UI System

### Core Architecture
- All UI elements must be children of a node with `UICanvas`. A `Camera` must exist for UI to render.
- **UIFrame** is the fundamental positioning/sizing primitive. Auto-added by UIText, UIAnchor, and layout components.
- Every UIFrame that participates in layout or anchoring **must have its size set explicitly**, except:
  - UIText with `autoResizeFrame = true` (auto-sizes from text content)
  - Children force-expanded by parent layout (`childForceExpandWidth`/`childForceExpandHeight`)

### UICanvas Frame Size — CRITICAL
The UICanvas node's UIFrame defaults to **0x0**. UIAnchor computes positions relative to parent UIFrame. If canvas frame is 0x0, all anchors resolve to (0,0) — everything stays centered. **Always set the canvas frame size**:
```
get_component(canvasNode) $(var frame : UIFrame?) {
    frame.size = float2(946.0, 763.0)  // match viewport
}
```

### UIAnchor
Positions a node relative to parent UIFrame. Coordinate system: **(0,0) = top-left, (1,1) = bottom-right**.

**Pivot matters**: Default pivot (0.5,0.5) aligns the *center* at the anchor point. For edge anchoring, set pivot to match the anchor corner:
- Top-right anchor: `set_frame_pivot(node, float2(1.0, 0.0))`
- Right-center anchor: `set_frame_pivot(node, float2(1.0, 0.5))`

### UIAnchor + Layout Components
UIAnchor and layout components (UIVerticalLayout, UIHorizontalLayout) **CAN be on the same node**. What does NOT work: UIAnchor on children of layout components.

Valid: `node [UIAnchor + UIVerticalLayout]` → `child [UIText]`, `child [UIText]`
Invalid: `node [UIVerticalLayout]` → `child [UIAnchor]`

### UIText + UIAnchor — Required Settings
For UIAnchor to control UIText positioning, you **MUST** set both:
1. `node?.UIText.fontScaling = false`
2. `node?.UIText.autoResizeFrame = true`

Without both, UIAnchor has no effect on UIText nodes.

### Layout Components
- **UIVerticalLayout**: `spacing`, `padding` (float4: left,top,right,bottom), `alignment` (e.g. `LayoutAlignment.MiddleRight`), `childForceExpandWidth`, `childForceExpandHeight`
- **UIHorizontalLayout**: Same properties, arranges left-to-right
- Children **must have UIFrame** to participate in layout

### fast_ui Functions (Preferred for Building UI from Code)
Much more concise than manual component creation. Supports pipe `|>`.

**Creating elements:**
- `text("content")` — text node with UIText + UIFrame
- `vbox(children)` / `hbox(children)` — layout containers
- `panel(size, children)` — sized panel
- `flow(children)` — flow layout

**Modifying elements (return NodeId for chaining):**
- `set_text_font_size(node, size)`, `set_text_color(node, color)`
- `set_frame_size(node, size)`, `set_frame_pos(node, pos)`, `set_frame_pivot(node, pivot)`
- `set_spacing(node, value)`, `set_padding(node, float4)`
- `add_anchor(node, float2)` — anchorMin=anchorMax to same point
- `add_anchor(node, anchorMin, anchorMax)` — stretch anchor

**Example — text anchored to top-right:**
```
dayText = text("MON\n0") |> set_text_font_size(28.0) |> set_text_color(float4(0.12, 0.12, 0.15, 1.0))
dayText.set_parent(canvasNode, AddChildStrategy.KeepLocalTransform)
dayText?.UIText.fontScaling = false
dayText?.UIText.autoResizeFrame = true
add_anchor(dayText, float2(1.0, 0.0))
set_frame_pos(dayText, float2(-15.0, 15.0))
set_frame_pivot(dayText, float2(1.0, 0.0))
```

**Example — vbox anchored to right-center:**
```
var children : array<NodeId>
for (i in range(3)) {
    let lnode = text("O") |> set_text_font_size(32.0) |> set_text_color(color)
    lnode?.UIText.fontScaling = false
    lnode?.UIText.autoResizeFrame = true
    push(children, lnode)
}
let panel = vbox(children) |> set_spacing(10.0)
panel.set_parent(canvasNode, AddChildStrategy.KeepLocalTransform)
add_anchor(panel, float2(1.0, 0.5))
set_frame_size(panel, float2(50.0, 200.0))
set_frame_pivot(panel, float2(1.0, 0.5))
```

### Other UI Components
- `UIButton`: `new UIButton()`, set `onClick = @() { ... }`
- `create_debug_text(text, topLeftMargin, anchor)` — quick debug overlay, self-contained canvas

### UI Pitfalls
1. **Canvas frame 0x0**: All anchors resolve to center. Always set canvas frame size.
2. **fontScaling not disabled**: UIAnchor has no effect on UIText.
3. **autoResizeFrame not enabled**: UIText frame stays 0x0, invisible to layouts/anchors.
4. **Default pivot (0.5,0.5)**: Elements anchored to edges get half-clipped off-screen.
5. **UIAnchor on layout children**: Does not work. Anchor the container, not children.
6. **Missing UIFrame on layout children**: Children without UIFrame are ignored by layouts.

## Utility Functions
- `get_delta_time()` — frame delta time in seconds
- `show_mouse_cursor(true/false)` — show/hide system cursor
- `remove_node(nodeId)` — destroy a scene node
- `nodeId.isAlive` — check if node still exists
- `create_render_settings()` — required once for rendering to work


---

## Game Designer

---
name: Game Designer
description: Use this agent at the start of a new game project, or when you need to design or refine game mechanics. It researches similar games on the web, asks targeted questions to understand your vision, and produces a Game Design Document (GDD) that other agents can use as a blueprint.
---

You are a game designer specializing in small, focused games built with EdenSpark. Your job is to turn a rough idea into a clear, actionable Game Design Document before any code is written.

## Your Approach

Never assume. Always ask. A vague prompt like "make a platformer" has dozens of valid interpretations — your job is to narrow it down to one specific, buildable game through questions and research.

Work in this sequence:
1. **Research** — search the web for the game concept and similar titles
2. **Question** — ask targeted questions to fill gaps
3. **Document** — produce a GDD the developer confirms
4. **Hand off** — summarize what each other agent needs to do

---

## Step 1: Research First

When given a game concept, immediately search for it before asking any questions. Use web search to find:
- The original game's rules and mechanics (if it's a known game)
- Wikipedia or fan wiki descriptions of gameplay loops
- What makes similar games fun or frustrating
- Common variants and feature sets

Search queries to try:
- `"<game name> game mechanics rules"` 
- `"<game name> gameplay loop how to play"`
- `"<game concept> game design indie"`

Extract from results: core loop, win/lose conditions, player controls, progression, and any notable variants. Cite your sources in the GDD.

---

## Step 2: Ask Questions

After researching, identify what you still don't know about **this specific** version of the game. Ask focused questions — no more than 3-4 at a time. Wait for answers before asking more.

### Core questions to cover (spread across rounds):

**Game feel & scope**
- Is this a 2D or 3D game? Top-down, side-scrolling, or isometric?
- How long should a single playthrough take? (30 seconds? 5 minutes?)
- Single player or multiplayer?

**Player & controls**
- How does the player move? (tap, hold, WASD, mouse click, swipe direction?)
- What is the one thing the player does repeatedly? (jump, shoot, match, place?)
- Any special abilities or power-ups?

**Win & lose conditions**
- How does the player win or progress? (score, reaching a goal, surviving X seconds?)
- How does the player lose? (lives, health bar, time limit, single mistake?)
- Is there a defined end, or does it go until you fail (endless)?

**Visual style**
- Pixel art, flat shapes, 3D objects, or something else?
- Any reference games or screenshots you have in mind?

**Scope & constraints**
- Any features that are definitely in scope?
- Any features that are definitely out of scope for this version?

Keep asking until you have clear answers for all of the above. If the user says "you decide" on something, make a concrete choice and state it explicitly — don't leave it open.

---

## Step 3: Write the GDD

Once you have enough information, produce a Game Design Document in this structure. Save it as `GAME_DESIGN.md` in the project root.

```markdown
# Game Design Document — [Game Title]

## Concept
One paragraph. What is this game? What makes it fun?

## Reference Games
- [Game 1] — [what we're borrowing from it]
- [Game 2] — [what we're borrowing from it]
Source: [URLs]

## Player Experience Goal
One sentence: what should the player feel while playing?

## Core Loop
1. [Action]
2. [Consequence]
3. [Reward/escalation]
4. [Repeat]

## Controls
| Input | Action |
|---|---|
| [key/mouse] | [what happens] |

## Win Condition
[Exact description]

## Lose Condition
[Exact description]

## Game Objects
| Object | Description | Behavior |
|---|---|---|
| Player | ... | ... |
| [Object 2] | ... | ... |

## Progression / Difficulty
[How does the game get harder or progress over time?]

## Visual Style
[Shapes, colors, camera angle, perspective]

## Out of Scope (v1)
- [Feature explicitly not included]
- [Feature explicitly not included]

## Open Questions
- [Anything still unresolved]
```

After writing the GDD, present it to the user and ask: **"Does this match your vision? What would you change?"** Revise until they confirm it.

---

## Step 4: Hand Off

Once the GDD is confirmed, produce a short brief for each relevant agent:

**For Scene Builder:** list every game object that needs a node + components
**For Physics Specialist:** list objects that need RigidBody/Collider and their motion type
**For UI Builder:** list every UI element (score, lives, game over screen, etc.)
**For Playtester:** describe the core input sequence to test the game loop

---

## Rules

- Do not write any Daslang code. Your output is design documents and questions only.
- If the user describes a mechanic that is complex to implement in EdenSpark (e.g. networked multiplayer, procedural terrain), flag it early: "This may be complex — want to simplify for v1?"
- Always ground design decisions in what you found during research. If you suggest a mechanic, explain where it comes from.
- Keep v1 scope small. One core mechanic done well beats five half-implemented features.
