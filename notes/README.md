# Bonfire — Modular Godot 4 Prototype

A **self-contained example project** containing the updated, commented files for the current playable Bonfire prototype. It does **not** include the future inventory system or multiplayer.

## Contents

```text
Bonfire_Prototype_0_1_Modular/
├── project.godot
├── scenes/
│   └── main.tscn
└── scripts/
    ├── player.gd
    ├── terrain.gd
    ├── world_generator.gd
    ├── resource_node.gd
    ├── campfire.gd
    ├── hud.gd
    ├── factories/
    │   ├── tree_factory.gd
    │   ├── rock_factory.gd
    │   └── material_factory.gd
    └── world/
        └── spawn_validator.gd
```

Each function has a brief description. Inline comments explain intentional behavior, unusual Godot details, or temporary prototype decisions.

## Run as a new standalone Godot project

1. Extract the ZIP.
2. In **Godot 4**, import `Bonfire_Prototype_0_1_Modular/project.godot`.
3. Open the project, allow the editor to scan/import scripts, then run with **F6/F5** (F5 runs the main scene).
4. Controls:

| Input | Action |
| --- | --- |
| W/A/S/D | Move |
| Mouse | Look |
| Space | Jump |
| E | Collect tree wood, or confirm placement |
| B | Start/cancel campfire preview (requires 3 wood) |
| Left click | Confirm placement |
| Right click | Cancel placement |
| Esc | Quit running game |

The world generates from fixed seeds, with tree and rock variations. Collect three trees, press B, aim at the ground, and place a campfire. A green preview is valid; red is invalid.

## Merge into your existing project

**Back up your current project first.** This ZIP also includes a sample `project.godot` and `main.tscn` so it can run standalone; **do not overwrite your customized versions** unless you intend to replace them.

1. Copy the `scripts/` directory into your existing `res://scripts/`, preserving the folder layout and existing paths.
2. Keep your existing `main.tscn` and attach these scripts to the corresponding nodes if needed:
   - `World/Ground` → `res://scripts/terrain.gd`
   - `World/WorldGenerator` → `res://scripts/world_generator.gd`
   - `Player` → `res://scripts/player.gd`
   - `HUD` → `res://scripts/hud.gd`
3. Required scene paths are `World/Ground`, `World/GeneratedObjects`, `World/WorldGenerator`, `Player/Camera3D/InteractionRay`, and `HUD/WoodLabel`.
4. Keep or add the input actions in the table above in **Project → Project Settings → Input Map**. `ui_cancel` is Godot's default Esc action. The standalone `project.godot` already declares the custom actions.
5. Remove any old visible flat BoxMesh ground objects from the scene. The terrain script creates its own mesh and collision children at runtime.
6. The included `spawn_validator.gd` and `material_factory.gd` are now integrated, not unused templates.

## Technical notes

- `terrain.gd` generates both `ArrayMesh` triangles and `HeightMapShape3D` collision from the same sampled height grid.
- For reliable shape alignment, keep `Ground` at position `(0, 0, 0)`, rotation `(0, 0, 0)`, scale `(1, 1, 1)`.
- Default terrain is 96 × 96 units (`grid_resolution=96`, `cell_size=1.0`), while objects spawn within the central 80 × 80 region.
- The collision heightmap's X/Z grid scale is set from `cell_size`. Staying at `1.0` is simplest for the initial prototype.
- World object positions sample continuous noise, while the mesh and physics surface interpolate a discrete grid; a small visual gap can occur on steep terrain. This will be refined later.
- `BonfireResourceNode`, `BonfireCampfire`, and `BonfireTerrain` are registered script classes so the factories and player can construct typed instances.
- Trees remain the only collectible resource; rock collection and an inventory system are **not implemented** yet.
- Placement targets terrain only. It validates range, slope, and wood cost; **object-overlap/clearance validation is not implemented** yet.
- Godot 4 uses `CylinderMesh` with `top_radius = 0` for the placeholder cone-shaped flame. There is no `ConeMesh` here.
- Log meshes use the local variable `wood_log` to avoid shadowing Godot's built-in `log()` function.

## Suggested next steps

1. Introduce a separate inventory component and support stone.
2. Move placement state and validation out of `player.gd` as more placeables are added.
3. Add build clearance checks and more precise object-to-terrain alignment.

## Verification

File paths, declared script dependencies, scene references, and package contents were checked when the archive was built. **This environment does not have the Godot executable installed**, so the package has not been run in the engine. If the editor reports a parser or runtime error, provide the exact error and affected file.
