# Swarm Defense — Full Development Roadmap

> **Working title:** Swarm Defense  
> **Engine:** Godot 4.7 (GDScript, optional C# hot paths)  
> **Platform:** macOS (Apple Silicon) → Cross-platform (Mac/Win/Linux)  
> **Target:** Cooperative multiplayer (2–16) sci-fi survival/builder

---

## 1. Game Identity & Vision

**Core Loop:**  
Expand automated mining & comms network → Manage light-speed delays → Defend bases from Swarm → Harvest resources → Tech up → Expand outward.

**Design Pillars:**
- **Strategic Delay** — Reinforcements take real time to arrive (simulated lightspeed). Every decision has weight.
- **Modular Building** — Snap-together stations/defenses on planetary surfaces & orbit.
- **Cooperative Automation** — Like Factorio in space: build logistics, not grind.
- **Escalating Threat** — Swarm adapts, targets weak points in your network.

**Player Roles (emergent, not enforced):**
- Builder / Base architect
- Miner / Logistics
- Defender / Pilot
- Explorer / Relay planner

---

## 2. Project Setup & Core Architecture

### 2.1 Folder Structure

```
swarndefense/
├── .godot/
├── assets/
│   ├── audio/
│   ├── fonts/
│   ├── meshes/          # .glb/.blend exports
│   ├── textures/
│   └── ui/
├── addons/              # Third-party plugins
├── docs/
├── scenes/
│   ├── core/            # Main.tscn, World.tscn, GameManager.tscn
│   ├── celestial/       # Sun, planets, asteroids
│   ├── buildings/       # Station modules, turrets, relays
│   ├── ui/              # HUD, menus, minimap
│   ├── ships/           # Player ship, drones, Swarm units
│   └── effects/         # Particles, explosions, trails
├── scripts/
│   ├── globals/         # Autoloads (singletons)
│   ├── systems/         # Economy, tech, wave manager
│   ├── networking/      # Lobby, sync, authority
│   ├── ai/              # Swarm behavior, pathfinding
│   └── utils/           # Helpers, math, noise
├── resources/           # .tres files (items, techs, stats)
├── tests/
└── project.godot
```

### 2.2 Autoloads (Singletons)

| Autoload | Purpose |
|---|---|
| `GameManager` | Game state, phase transitions, pause, win/loss |
| `NetworkManager` | Peer/server management, RPC routing, lobby |
| `EconomyManager` | Resource pools, income, transaction validation |
| `TechManager` | Tech tree state, unlocks, research queue |
| `WaveManager` | Swarm wave config, escalation, spawn control |
| `TimeManager` | Simulated time, lightspeed delay calculations |
| `InputHandler` | Action mapping, rebinding, controller support |
| `AudioManager` | SFX bus, spatial audio, music crossfade |

### 2.3 Input Map

Actions to define in Project Settings → Input Map:

```
move_forward, move_back, move_left, move_right, move_up, move_down
rotate_left, rotate_right
boost, brake
primary_fire, secondary_fire
interact, build_menu, build_rotate
map_view, zoom_in, zoom_out
slot_1..slot_4
chat, pause, debug
```

### 2.4 Coding Standards

- **Files:** `snake_case.tscn`, `snake_case.gd` (matches Godot convention)
- **Classes:** `PascalCase` — extends `Node`, `RigidBody3D`, etc.
- **Variables:** `snake_case` (private: `_snake_case`)
- **Signals:** `snake_case` with `_emitted` suffix in docs
- **Constants:** `UPPER_CASE`
- **Resources:** `pascal_case.tres`
- Commits: Conventional Commits (`feat:`, `fix:`, `perf:`, `refactor:`)

### 2.5 Main Scene Tree (Conceptual)

```
World (Node3D)
├── CelestialSystem (Node3D)
│   ├── Sun (DirectionalLight3D + GPUParticles3D + Area3D)
│   ├── Mercury (RigidBody3D / custom orbital)
│   ├── Venus (...)
│   ├── Earth (...)
│   │   └── Moon (...)
│   └── Mars (...)
├── AsteroidField (MultiMeshInstance3D + Node for spawning)
├── PlayerShip* (CharacterBody3D, * = spawned per player)
├── SwarmUnits (Node3D container)
├── Buildings (Node3D container, server-authoritative)
├── UILayer (CanvasLayer)
│   ├── HUD
│   ├── Minimap
│   ├── BuildMenu
│   └── CommsOverlay
└── GameManager (Node — autoloads handle cross-cutting concerns)
```

---

## 3. Phased Development Plan (10 Phases)

**Effort scale for solo dev:** 1 phase unit ≈ 1–2 weeks part-time (evenings/weekends).  
**Key:** Phase 1–3 = vertical slice (single-player core). Phase 4+ adds multiplayer & depth.

### Phase 0: Scaffold & Tooling (Week 1)

| Step | Description | Godot Key |
|---|---|---|
| 0.1 | Init project, set renderer (Forward+), 3D scene template | Project Settings |
| 0.2 | Create folder structure, `.gitignore`, `AGENTS.md` | FileSystem |
| 0.3 | Set up autoloads (empty stubs) | Project → Autoload |
| 0.4 | Set up C# if desired: install .NET SDK, enable `dotnet` module | Mono |
| 0.5 | Define Input Map actions | Input Map |
| 0.6 | Create `Main.tscn` (menu) → `World.tscn` (game) flow | SceneTree |
| 0.7 | Write `DebugConsole.gd` autoload for quick testing | Console |
| 0.8 | Create base `CameraManager.gd` — orbital camera, zoom levels | Camera3D |
| ✅ | **Milestone:** Scene transitions work, camera moves, input responsive | |

### Phase 1: Solar System Simulation (Weeks 2–3)

| Step | Description | Godot Key |
|---|---|---|
| 1.1 | Create `CelestialBody.gd` (Node3D) with orbital params: `semi_major_axis`, `eccentricity`, `inclination`, `period`, `rotation_period` | Custom |
| 1.2 | Implement simplified Keplerian orbit: `position = orbit_at_time(t)` using parametric ellipse | Math |
| 1.3 | Scale: 1 AU = 1000 units; planet sizes exaggerated 10× for visibility | Tuning |
| 1.4 | Sun: `OmniLight3D` + `GPUParticles3D` (corona) + `Area3D` for proximity detection | Particles |
| 1.5 | Planet surfaces: `SphereMesh` with `NoiseTexture2D` for procedural color; optional low-poly shader | Shaders |
| 1.6 | Orbit lines (debug): `ImmediateMesh` or `Line2D` in 3D space | Mesh |
| 1.7 | `CameraManager` zoom levels: system view (whole orbit) → planet view (close) → surface (future) | Camera3D |
| 1.8 | Time scaling: `TimeManager` offers `simulation_speed` (0.1× – 100×) | Engine |
| ✅ | **Milestone:** Sun + 4 planets orbit, camera zooms, time accelerates | |

**Key snippet — simplified orbital position:**

```gdscript
# CelestialBody.gd (excerpt)
func _get_orbital_position(t: float) -> Vector3:
    var angle = 2.0 * PI * t / orbital_period + initial_angle
    var x = semi_major_axis * cos(angle)
    var z = semi_major_axis * sin(angle) * sqrt(1.0 - eccentricity * eccentricity)
    return Vector3(x, sin(angle) * inclination * 10.0, z)
```

### Phase 2: Player Ship & Controls (Weeks 3–4)

| Step | Description | Godot Key |
|---|---|---|
| 2.1 | `PlayerShip.gd` — `CharacterBody3D` with 6-DOF movement | CharacterBody3D |
| 2.2 | Thrust: Newtonian physics (force-based, no drag in space) | `apply_force()` |
| 2.3 | Mouse look + keyboard/controller bindings | Input |
| 2.4 | Camera: 3rd-person spring arm with collision avoidance | SpringArm3D |
| 2.5 | Ship mesh: placeholder (low-poly triangle shape) | MeshInstance3D |
| 2.6 | Boost (limited duration), brake, drift toggle | State machine |
| 2.7 | Simple HUD: speed, position indicator, crosshair | Control |
| 2.8 | Ship enters planet orbit zone: gravity well affects movement | Area3D |
| ✅ | **Milestone:** Player flies through solar system, orbits work | |

### Phase 3: Resource System & Mining (Weeks 4–6)

| Step | Description | Godot Key |
|---|---|---|
| 3.1 | `ResourceType.tres` enum-resource: `Name`, `Icon`, `Color`, `BaseValue` | Resource |
| 3.2 | `EconomyManager` — dict of `resource_type → amount`, `income_rate`, `capacity` | Autoload |
| 3.3 | Mining nodes: place `Asteroid.gd` / `RegolithDeposit.gd` with `ResourceType`, `remaining`, `depletion_rate` | StaticBody3D |
| 3.4 | Mining beam: player ship laser / mining drone projectile, raycast to node, `tick()` extraction | RayCast3D |
| 3.5 | Resource transfer: ship cargo → base storage via proximity | Area3D |
| 3.6 | Solar power: `SolarArray.gd` — power output = `base * sun_distance_factor * sun_exposure_angle` | Math |
| 3.7 | Power as resource type: buildings consume power, deficit = slowdown | Economy |
| 3.8 | UI: resource bar with income/capacity display | HUD |
| ✅ | **Milestone:** Mine asteroid, deposit at base, power works | |

**Key snippet — solar power calculation:**

```gdscript
func calculate_power_output(sun_pos: Vector3, global_pos: Vector3) -> float:
    var dist = global_pos.distance_to(sun_pos)  # clamped min distance
    var base = max_power * (1.0 - dist / max_efficient_distance)
    var dir_to_sun = (sun_pos - global_pos).normalized()
    var exposure = dir_to_sun.dot(global_transform.basis.z)  # panel normal
    return base * max(exposure, 0.0)
```

### Phase 4: Building System (Weeks 6–8)

| Step | Description | Godot Key |
|---|---|---|
| 4.1 | `Building.gd` base class: `resource_costs`, `power_consumption`, `health`, `snap_points` | Node3D |
| 4.2 | `BuildingManager.gd` autoload: grid-free snap placement with `SnapPoint3D` children | Spatial |
| 4.3 | Placement validation: overlap check (`PhysicsShapeQuery3D`), terrain angle, resource cost | Physics |
| 4.4 | Ghost preview: semi-transparent duplicate follows mouse, green/red for valid/invalid | Geometry |
| 4.5 | Building types: `Extractor`, `SolarPanel`, `Battery`, `Relay`, `Turret`, `RepairBay`, `Habitat` | Inheritance |
| 4.6 | Snap-together: buildings have `SnapPoint` children; proximity snaps cursor to nearest | Area3D |
| 4.7 | Upgrades: building has `upgrade_level` → stats multiplier, visual change, cost | Resource |
| 4.8 | Radial build menu: pie menu triggered by `build_menu` action | Control / Custom |
| ✅ | **Milestone:** Place buildings on surfaces, snap works, upgrades functional | |

### Phase 5: Comms, Relays & Light-Speed Delay (Weeks 8–9)

| Step | Description | Godot Key |
|---|---|---|
| 5.1 | `RelayTower.gd` — boosts network range; each relay has comms radius | Area3D |
| 5.2 | `NetworkGraph.gd` — graph of all relays + bases; pathfind shortest comms chain | AStar3D |
| 5.3 | Delay = `distance / speed_of_light` (configurable, e.g. 1 AU ≈ 500ms for fun) | Math |
| 5.4 | Command queue: orders to out-of-range units are `DelayedCommand` with `arrival_time` | Timer |
| 5.5 | UI overlay: network map showing relays, connections, latency values | Control / Line2D |
| 5.6 | Visual pulse: animated pulse along comms line (shader or tween) | Tween / Shader |
| ✅ | **Milestone:** Relay chains extend range, commands arrive delayed, UI shows latency | |

**Key snippet — delayed command:**

```gdscript
# DelayedCommand.gd (resource or lightweight object)
class_name DelayedCommand
var target_unit: NodePath
var command_type: String  # "move", "attack", "build"
var params: Dictionary
var arrival_time: float   # TimeManager global time
var issued_at: float
var origin: Vector3

func is_pending(current_time: float) -> bool:
    return current_time < arrival_time
```

### Phase 6: Swarm AI & Defense (Weeks 9–12)

| Step | Description | Godot Key |
|---|---|---|
| 6.1 | `SwarmUnit.gd` — `RigidBody3D` or `CharacterBody3D`, modular parts | Base class |
| 6.2 | Unit types: `Scout` (fast, weak), `Fighter` (balanced), `Tank` (slow, armored), `Carrier` (spawns drones) | Enum |
| 6.3 | Swarm AI: travel to nearest building → attack; if none, pathfind along relay chain | Navigation / custom |
| 6.4 | `WaveManager.gd` — wave configs: `spawn_count`, `mix`, `spawn_location`, `escalation_curve` | Resource |
| 6.5 | Spawn at solar edge / asteroid field → approach player network | Timer |
| 6.6 | Targeting AI: prioritize relays (disconnect network), then power, then defenses | Decision |
| 6.7 | Turrets: `Turret.gd` — `rotation` toward nearest enemy in range, fire projectile | RayCast3D |
| 6.8 | Drones: deployable `DroneSwarm.gd` — flies to defend designated area | PathFollow3D |
| 6.9 | Damage system: `HealthComponent.gd` — `take_damage(amount, type)` → death, explosion | Signals |
| ✅ | **Milestone:** Swarm waves attack, turrets shoot, base can be destroyed | |

### Phase 7: Multiplayer Core (Weeks 12–16) *Longest Phase*

| Step | Description | Godot Key |
|---|---|---|
| 7.1 | `NetworkManager.gd` — ENet peer, lobby with `SceneMultiplayer` | ENet |
| 7.2 | Lobby UI: host/join IP, player list, ready toggle | Control |
| 7.3 | Server authority: server owns `CelestialBody`, `WaveManager`, `EconomyManager` | Authoritative |
| 7.4 | Player spawn: server spawns `PlayerShip` for each connected peer | RPC |
| 7.5 | Client prediction: ship movement predicted locally, server reconciles | `NetworkedController` |
| 7.6 | State sync: `_on_state_sync()` for building placement, resources, health | RPC `sync` |
| 7.7 | Building placement: client requests → server validates → server spawns → sync to all | RPC |
| 7.8 | Swarm sync: server spawns and controls Swarm; clients see interpolated positions | Sync |
| 7.9 | Delayed commands: delay calculated server-side; command appears after travel time | `Timer` |
| 7.10 | Reconnection handling (optional for demo): state resend | State |
| ✅ | **Milestone:** 2+ players fly, build, fight together | |

**Architecture note:**

```
[Client A] ──RPC──> [Server (authoritative)] ──RPC/sync──> [Client B]
   ▲                        │
   └───── client prediction / reconciliation
```

### Phase 8: Tech Tree & Progression (Weeks 16–18)

| Step | Description | Godot Key |
|---|---|---|
| 8.1 | `Tech.gd` resource: `name`, `description`, `costs`, `prerequisites`, `unlocks` | Resource |
| 8.2 | `TechManager.gd` — linear + branching tree, research queue | Autoload |
| 8.3 | Tech categories: Mining, Power, Defense, Logistics, Swarm Biology | Tree |
| 8.4 | Unlocks: tech completion fires signal: `building_unlocked`, `unit_upgraded`, `stat_multiplier` | Signals |
| 8.5 | UI: `TechTreeScreen.gd` — graph-like view, click to research | GraphNode / Custom |
| 8.6 | Progression loop: Mine → Build → Defend → Research → Expand → (harder waves) | Loop |
| ✅ | **Milestone:** Tech tree functional, 10+ techs, progression loop solid | |

### Phase 9: Demo Polish & Packaging (Weeks 18–20)

| Step | Description | Godot Key |
|---|---|---|
| 9.1 | Audio: placeholders → final SFX (spatial mining, turret fire, explosion, UI clicks) | AudioStreamPlayer3D |
| 9.2 | VFX: mining beam particles, explosion, thruster trails, shield hit | GPUParticles3D |
| 9.3 | Music: ambient layers + combat intensity crossfade | Audio |
| 9.4 | Save/Load: `ConfigFile` or `ResourceSaver` for local; server save for MP | Serialize |
| 9.5 | Main menu: host/join, settings, credits | Control |
| 9.6 | Settings: graphics quality, audio, controls rebinding | Control |
| 9.7 | Loading screen + progress bar for world init | Control |
| 9.8 | Minimap: top-down render of system with icons | SubViewport / TextureRect |
| 9.9 | Accessibility: colorblind mode, scalable UI, text-to-speech (optional) | Theme |
| 9.10 | Cross-platform export templates: Mac, Win, Linux | Export |
| ✅ | **Milestone:** Demo-ready build! | |

### Phase 10: Testing, Balancing & Release (Weeks 20–24)

| Step | Description |
|---|---|
| 10.1 | Playtest with 2–4 players (local network) — find bugs |
| 10.2 | Balance resource rates, wave difficulty, tech costs |
| 10.3 | Performance profiling with Godot profiler, optimize hotspots |
| 10.4 | Add `--server` headless mode for dedicated server |
| 10.5 | Write README, itch.io page, gameplay trailer |
| 10.6 | Package demo release (itch.io / Steam internal) |

---

## 4. Demo Scope Definition

**"Playable Demo" includes:**

| Feature | In Scope? | Detail |
|---|---|---|
| Solar System | ✅ | Sun, Mercury, Venus, Earth+Moon, Mars, Asteroid Belt |
| Player Ship | ✅ | Full 6-DOF flight, boost, brake, mouse/controller |
| Mining | ✅ | Laser-mine asteroids and regolith deposits |
| Solar Power | ✅ | Place solar arrays, output scales with Sun proximity |
| Building | ✅ | 6+ building types, snap-together on surfaces |
| Tech Tree | ✅ | 8–12 techs, 3 categories |
| Swarm Waves | ✅ | 3 escalating waves, 3 unit types |
| Turrets/Drones | ✅ | Place defenses, basic AI targeting |
| Comms Delay | ✅ | Relay chain latency, delayed commands |
| Multiplayer | ✅ | 2–4 players co-op, client-server |
| Win/Lose | ✅ | Survive all waves = win; base destroyed = lose |
| Save/Load | ➖ | Local session save (nice-to-have) |
| Audio | ✅ | Core SFX, ambient music |
| Polish | ➖ | Basic particles, no cinematics |
| UI | ✅ | HUD, build menu, network map, minimap, tech tree |

---

## 5. Key Systems — Detailed Godot Implementation Notes

### 5.1 Celestial System

```
CelestialSystem (Node3D)
├── CelestialBody (Node3D) * per planet
│   ├── MeshInstance3D (visual)
│   ├── CollisionShape3D / Area3D (gravity trigger)
│   └── GPUParticles3D (atmosphere/rings, optional)
└── CelestialPath (ImmediateMesh / Line2D) * orbit trail
```

- Use `Rid` for physics body if simulation gets heavy; else keep `Node3D` with manual `position` update
- Multi-thread: orbital calculations in a `Thread` or use `PhysicsServer3D` directly if >1000 bodies
- Scale cheat: 1 AU = 1000–2000 units; planet radius = 5–50 units (exaggerated for gameplay)

### 5.2 Building Placement

1. Fire `RayCast3D` from camera → terrain surface
2. Get `collision_point` + `normal`
3. Validate: slope angle < max, no overlap (`PhysicsShapeQuery3D`), in player territory
4. Ghost follows valid position
5. On click: deduct resources → `BuildingManager.request_build(building_type, pos, rot)`
6. MP: client → server RPC → server `spawn_building()` → sync

### 5.3 Networking Architecture

**Client-Server (recommended over P2P for authoritative design):**

- Headless server binary (`--server` flag) or in-game host
- Use `SceneMultiplayer` (built-in) + `ENetMultiplayerPeer`
- RPC modes: `@rpc("authoritative", "call_local")` for player input
- State sync: `@rpc("unreliable")` for position; `@rpc("reliable")` for building placement
- No `MultiplayerSpawner` for custom entities; manual spawn via RPC gives better control over delayed spawns

**Delay simulation:**

```
Player (Earth) orders drone attack (Mars):
  1. Client sends RPC to server
  2. Server calculates lightspeed delay = distance( Earth, Mars ) / speed_of_light
  3. Server schedules command for future execution
  4. Server sends "order_received" back with ETA
  5. Client shows "Reinforcements arriving in 12s" in UI
  6. Timer fires → drone spawns and attacks
```

### 5.4 Swarm AI

```
WaveManager
└── per wave:
    ├── timer → spawn units at edge
    └── units move toward network
        ├── if relay chain exists: pathfind along nearest relay
        └── else: random drift + nearest building detection
```

- Navigation: `NavigationRegion3D` on planetary surfaces; in space, use direct vectors + obstacle avoidance
- Optimization: collapse far-away Swarm into singular "threat level" (off-screen simplification)

### 5.5 Economy

- All resources are `int`; no fractional (keeps sync simple)
- Income tick: every 1s real-time → `EconomyManager._on_income_tick()` sums all extractors, solar arrays
- Storage buildings: each has `capacity`; excess = wasted
- Transactions: all cost/income flows through `EconomyManager.add_resource(type, amount, source)` for audit

---

## 6. Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Multiplayer sync bugs | High | High | Start single-player; MP in Phase 7; extensive local net testing |
| Performance with 100s of entities | Medium | High | MultiMeshInstance, pooling, LOD, culling, off-screen simplification |
| Orbital physics drift over time | Medium | Medium | Fixed timestep for simulation; deterministic clock |
| Building system feels clunky | Medium | Medium | Prototype placement early (Phase 4); iterate on feel |
| Scope creep | High | High | Strict demo scope definition; feature freeze 1 month before release |
| Solo dev burnout | Medium | Medium | Prioritize quick wins; celebrate milestones; realistic timeline |

**Performance Optimization Checklist:**
- [ ] Use `MultiMeshInstance3D` for asteroid fields and Swarm swarms
- [ ] `VisibilityEnabler3D` / `VisibleOnScreenNotifier3D` to pause off-screen
- [ ] `PhysicsServer3D` directly for thousands of simple bodies
- [ ] LOD: switch mesh detail by distance
- [ ] Networking: delta-compressed state updates, not full state every tick
- [ ] GDScript → C# migration only for proven hot paths (profiler first!)

---

## 7. Resource List

### Godot Docs (Priority)
- [Multiplayer API](https://docs.godotengine.org/en/stable/tutorials/networking/)
- [High-level multiplayer](https://docs.godotengine.org/en/stable/tutorials/networking/high_level_multiplayer.html)
- [Physics queries](https://docs.godotengine.org/en/stable/classes/class_physicsdirectspacestate3d.html)
- [GPUParticles3D](https://docs.godotengine.org/en/stable/classes/class_gpuparticles3d.html)
- [MultiMeshInstance3D](https://docs.godotengine.org/en/stable/classes/class_multimeshinstance3d.html)
- [Navigation](https://docs.godotengine.org/en/stable/tutorials/navigation/)
- [Resource system](https://docs.godotengine.org/en/stable/tutorials/scripting/resources.html)
- [Exporting](https://docs.godotengine.org/en/stable/tutorials/export/)

### Tutorials
- [Solar System in Godot (ivoyager style)](https://www.youtube.com/watch?v=example) — search "Godot solar system simulation"
- [Multiplayer FPS in Godot 4](https://www.youtube.com/watch?v=example) — search "Godot 4 multiplayer fps tutorial"
- [Building placement system](https://www.youtube.com/watch?v=example) — search "Godot 4 building placement"
- [Factorio-like belt system Godot](https://www.youtube.com/watch?v=example) — search "Godot factorio tutorial"
- [Tower Defense Godot 4](https://www.youtube.com/watch?v=example) — search "Godot 4 tower defense"

### Assets (Free)
- [Kenney Space Kit](https://kenney.nl/assets/space-kit) — CC0 3D models
- [Kenney UI Pack](https://kenney.nl/assets/ui-pack) — CC0 UI elements
- [NASA SDL Textures](https://www.solarsystemscope.com/textures/) — Public domain planet textures
- [Soniss GDC Audio Bundle](https://soniss.com/gdc-bundles/) — Free SFX packs
- [Incompetech Music](https://incompetech.com/) — Royalty-free music

### Addons
| Addon | Purpose | URL |
|---|---|---|
| `godot-netfox` | Enhanced multiplayer (lobby, lag compensation) | GitHub |
| `Godot-Trail-System` | Ship trails, projectile trails | Godot Assets |
| `godot-procedural-generation` | Asteroid/terrain noise generation | GitHub |
| `Godot-Terrain-Plugin` | Planetary terrain (if going surface-level) | GitHub |
| `Mouse and Keyboard Button Icons` | UI controller hints | Godot Assets |

### Tools
- **Blender** — 3D models (low-poly spaceships, buildings, Swarm units)
- **Aseprite** / **Krita** — 2D icons, textures, UI art
- **Audacity** — SFX editing
- **Chiptone** / **rFXGen** — Quick SFX generation
- **Itch.io** — Demo distribution

---

## 8. Timeline Summary

```
Phase 0: Scaffold       │ Week 1
Phase 1: Solar System   │ Weeks 2–3
Phase 2: Player Ship    │ Weeks 3–4
Phase 3: Resources      │ Weeks 4–6
Phase 4: Building       │ Weeks 6–8
Phase 5: Comms/Delay    │ Weeks 8–9
Phase 6: Swarm/Defense  │ Weeks 9–12
Phase 7: Multiplayer    │ Weeks 12–16
Phase 8: Tech/Prog      │ Weeks 16–18
Phase 9: Polish/Package │ Weeks 18–20
Phase 10: Test/Release  │ Weeks 20–24
```

**Total: ~24 weeks (6 months) part-time solo.**  
Cut Phase 7 (multiplayer) to ship SP demo in 3–4 months, then add MP post-launch.

---

## 9. Immediate Next Actions

After reading this roadmap, do these steps **today**:

1. **Open Godot 4.7, create a new project** in `/Users/seandolbec/Projects/swarndefense`
2. **Create folder structure** as defined in §2.1
3. **Set up version control** if not already: `git init && git add . && git commit -m "init: scaffold project"`
4. **Create stub autoloads** — one script per singleton from §2.2 with just `extends Node` and `pass`
5. **Build `MainMenu.tscn`** — "Host Game" / "Join Game" / "Settings" / "Quit" buttons (functional or placeholder)
6. **Build `World.tscn`** — empty 3D scene with a `Camera3D` + `DirectionalLight3D`
7. **Wire the scene transition** in `GameManager.gd`: `get_tree().change_scene_to_file("res://scenes/core/World.tscn")`
8. **Create a `_debug.gd` autoload** with `@tool` for quick dev commands
9. **Commit: `feat: scaffold project with autoloads and main menu`**
10. **Start Phase 1** — `CelestialBody.gd` with orbital math and one orbiting sphere

**First-code snippet for your `CelestialBody.gd`:**

```gdscript
extends Node3D

@export var orbital_period: float = 60.0    # seconds for one orbit
@export var semi_major_axis: float = 100.0  # distance from sun
@export var eccentricity: float = 0.05
@export var inclination: float = 0.0
@export var initial_angle: float = 0.0

var _time: float = 0.0

func _process(delta: float) -> void:
    _time += delta * TimeManager.simulation_speed
    position = _get_orbital_position(_time)

func _get_orbital_position(t: float) -> Vector3:
    var angle = 2.0 * PI * t / orbital_period + initial_angle
    var x = semi_major_axis * cos(angle)
    var z = semi_major_axis * sin(angle) * sqrt(1.0 - eccentricity * eccentricity)
    return Vector3(x, sin(angle) * inclination * 10.0, z)
```

**Remember:** Ship something playable every phase. Even if it's just "fly around the sun" — that's momentum. The full vision is 6+ months out; the first milestone is 1 week away.

---

*Last updated: 2026-06-23*
