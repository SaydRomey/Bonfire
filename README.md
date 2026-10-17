# Bonfire 🔥
> Cozy game test to try out 3d in godot and procedural stuff...

## Project Concept

The game is a small multiplayer sandbox centered around exploration,
campsite building, and spending time with friends.

Players create a character and enter a procedurally generated forest
containing terrain features such as:

-   Trees
-   Rivers
-   Rocks
-   Clearings
-   Hills
-   Other natural features

Players explore the environment looking for a suitable place to
establish a campsite. Natural materials can be gathered and used to
create simple tools and structures.

The game is intentionally not heavily goal-oriented or story-driven. The
primary experience is:

**Explore → Gather → Build → Rest → Socialize**

The campfire acts as the social center of the game. Friends can join the
same persistent world, explore together, build a campsite, and
eventually sit around the fire and talk.

Additional gameplay systems can be added later without changing the
basic concept.

------------------------------------------------------------------------

## Development Goals

This is primarily a learning project rather than a commercial product.

Important constraints:

-   No publishing deadline.
-   Intended primarily for playing privately with friends.
-   Prefer open-source software and libraries.
-   Most important systems should be written in C/C++.
-   JSON can be used extensively for configuration and data.
-   Python can be used for development tools and asset-generation
    utilities.
-   Building engine-level systems is acceptable because learning is one
    of the project's purposes.
-   The game should run on relatively inexpensive computers.
-   Photorealistic graphics are unnecessary.
-   Systems should remain modular so additional gameplay can be added
    later.

Because there is no commercial deadline, the project can prioritize
understanding how systems work rather than relying on a large commercial
engine.

------------------------------------------------------------------------

## Technical Direction

A custom lightweight C++ game framework is a good fit.

Instead of writing absolutely everything from scratch, the project can
combine small open-source libraries while retaining control over the
architecture.

### Proposed Technology Stack

  System                  Library / Approach
  ----------------------- --------------------------------
  Language                C++
  Build system            CMake
  Window/Input            SDL
  Rendering               bgfx
  Mathematics             GLM
  ECS                     EnTT (optional)
  Physics                 Jolt Physics
  Networking              ENet
  Procedural Noise        FastNoise2
  Images                  stb_image
  Model Loading           tinygltf / Assimp if necessary
  JSON                    nlohmann/json
  Debug UI                Dear ImGui
  Audio                   miniaudio
  Development utilities   Python

The intention is not to create a completely general-purpose game engine.
It is to create a **thin engine specifically suited to this game**.

------------------------------------------------------------------------

# Core Design Pillars

## 1. Atmosphere Over Objectives

The game should not require a traditional win condition.

The focus should be on:

-   Exploration
-   Relaxed pacing
-   Finding interesting locations
-   Building a campsite
-   Environmental atmosphere
-   Spending time with friends

Sound, lighting, weather, terrain, and the campfire should therefore
receive significant attention.

------------------------------------------------------------------------

## 2. Procedural but Readable Environments

The world should feel naturally varied without becoming random visual
noise.

Useful landmarks include:

-   River bends
-   Clearings
-   Rock formations
-   Hills
-   Dense forest areas
-   Sparse woodland
-   Shorelines

These features also help players navigate without requiring complicated
map systems.

------------------------------------------------------------------------

## 3. Social-First Multiplayer

The campsite and especially the campfire should function as the central
social space.

Players should be able to:

-   Explore together
-   Gather materials together
-   Construct a shared campsite
-   Sit on logs or rocks
-   Gather around the fire
-   Talk using an external voice service initially

Voice chat can eventually become an in-game proximity voice system.

------------------------------------------------------------------------

## 4. Scalable Complexity

The initial game should contain relatively few mechanics.

Systems should be designed so they can later support things such as:

-   Weather
-   Wildlife
-   Cooking
-   Fishing
-   More complex crafting
-   Seasonal changes
-   Instruments
-   Decorations
-   Additional biomes
-   Larger structures

These should not be required for the initial prototype.

------------------------------------------------------------------------

# Core Gameplay Loop

The basic loop is:

## Explore

Walk through the generated environment and search for interesting
locations.

## Gather

Initially, only a few resources are necessary:

-   Sticks
-   Logs
-   Stone

Possible later materials:

-   Bark
-   Fiber
-   Moss
-   Plants
-   Cloth

## Build

Initial structures could include:

1.  Campfire
2.  Log seat
3.  Stone seat
4.  Lean-to shelter

Later structures can expand from this system.

## Rest

Players should be able to interact with their campsite instead of
treating it only as decoration.

Examples:

-   Sit on logs
-   Sit near the fire
-   Light or extinguish the fire
-   Watch the environment transition into night

## Socialize

The campsite becomes the natural place where players stop exploring and
spend time together.

------------------------------------------------------------------------

# Procedural World Architecture

## Deterministic Generation

The world should be generated from a shared seed.

For example:

``` cpp
uint64_t worldSeed;
```

Given the same:

-   World seed
-   Generator version
-   Generation parameters
-   Chunk coordinates

every client should generate the same natural environment.

This avoids transmitting the entire world over the network.

------------------------------------------------------------------------

## Chunked World

The world should be divided into chunks.

A chunk can be addressed using:

``` cpp
struct ChunkCoord
{
    int32_t x;
    int32_t z;
};
```

A reasonable initial chunk size would be approximately:

``` text
64m × 64m
```

or:

``` text
128m × 128m
```

Each chunk can contain:

-   Terrain mesh
-   Tree instances
-   Rock instances
-   Plants
-   Resource nodes
-   Water information
-   Player-created objects

Chunking allows the game to load only the area around players.

------------------------------------------------------------------------

# Terrain

A heightmap-based terrain system is recommended instead of voxels.

Advantages:

-   Simple generation
-   Low memory usage
-   Cheap rendering
-   Easy collision
-   Easy procedural generation
-   Appropriate for forests and campsites

Terrain height can initially be generated using layered noise.

Conceptually:

``` text
large-scale noise → hills and valleys
medium-scale noise → terrain variation
small-scale noise → subtle surface variation
```

The terrain should generally remain walkable because exploration is the
primary activity.

------------------------------------------------------------------------

# Rivers

Rivers should ideally influence the rest of generation.

A useful generation order is:

``` text
Terrain
   ↓
River paths
   ↓
River terrain modification
   ↓
Clearings / biome masks
   ↓
Trees
   ↓
Rocks
   ↓
Smaller vegetation
```

Trees should therefore know where rivers exist rather than rivers being
placed through an already generated forest.

------------------------------------------------------------------------

# Forest Generation

Pure random placement should be avoided.

Instead, procedural rules should control vegetation.

Examples:

-   Trees avoid steep terrain.
-   Trees avoid river centers.
-   Tree density changes gradually using noise.
-   Some areas intentionally become clearings.
-   Rocks can cluster around steep terrain.
-   Vegetation density changes near water.
-   Different tree species can prefer different environmental
    conditions.

This produces environments that appear more intentional while remaining
procedural.

------------------------------------------------------------------------

# Stable Procedural Objects

Procedural objects should have deterministic identifiers.

For example, a tree could effectively be identified by:

``` text
world seed
+ chunk coordinate
+ local generation index
```

This means a tree does not need to be permanently stored.

If a player cuts down tree `418` in chunk `(3, -1)`, persistence only
needs to record:

``` json
{
  "type": "remove_resource",
  "chunk": [3, -1],
  "local_id": 418
}
```

The tree will then be skipped when that chunk is generated again.

------------------------------------------------------------------------

# Persistence

Use the following rule:

> Natural world state is generated. Player modifications are stored.

The save system therefore does not need to contain every tree, rock, or
terrain vertex.

A basic world definition might be:

``` json
{
  "seed": 123456789,
  "generator_version": 1
}
```

Player changes can be stored separately.

Example:

``` json
{
  "type": "place_structure",
  "prefab": "campfire",
  "position": [10.2, 0.0, 55.7],
  "rotation_y": 1.57
}
```

Another example:

``` json
{
  "type": "remove_resource",
  "chunk": [3, -1],
  "local_id": 418
}
```

An append-only JSON Lines file (`.jsonl`) could initially be used for
world modifications.

Later, the state can be compacted into a more efficient save format if
necessary.

------------------------------------------------------------------------

# Multiplayer Architecture

## Listen Server

For a private game played with friends, a listen-server model is
appropriate.

One player's computer acts as:

``` text
Server + Local Client
```

Other players connect as clients.

This avoids needing dedicated server infrastructure.

------------------------------------------------------------------------

## Server Authority

The host should be authoritative for important shared state.

Examples:

-   Player interactions
-   Structure placement
-   Resource gathering
-   Chopped trees
-   Campfire state
-   Time of day
-   Persistent world changes

Clients can still predict their own movement to keep controls
responsive.

------------------------------------------------------------------------

## Do Not Network the Procedural World

Terrain, trees, rocks, and similar deterministic content should not
normally be transmitted.

Every client receives the same world seed and generates those features
locally.

The network primarily needs to synchronize:

-   Player transforms
-   Player animation state
-   Structure placement
-   Structure removal
-   Resource interactions
-   World modifications
-   Fire state
-   Time of day

This dramatically reduces bandwidth requirements.

------------------------------------------------------------------------

# Rendering Strategy

The game should target modest hardware, potentially including integrated
graphics.

The art direction should support this requirement rather than fighting
it.

## Stylized Low-Poly Graphics

A suitable visual style could use:

-   Simplified geometry
-   Flat or lightly shaded surfaces
-   Small textures
-   Vertex colors
-   Exaggerated silhouettes
-   Atmospheric fog
-   Simple lighting

Photorealistic assets are unnecessary.

------------------------------------------------------------------------

# GPU Instancing

Forests contain many repeated objects.

Rendering every tree individually would create excessive draw calls.

Trees and rocks should therefore use GPU instancing.

Conceptually:

``` text
Tree Mesh A
    Instance 1 transform
    Instance 2 transform
    Instance 3 transform
    ...
```

One mesh can then represent many trees.

Instances can be grouped by:

``` text
mesh + material + visible region
```

This is one of the most important optimizations for the project.

------------------------------------------------------------------------

# Culling

Culling should occur in stages.

First:

``` text
Is the chunk potentially visible?
```

If not, ignore everything inside it.

Only visible chunks need additional processing.

Later optimizations could include:

-   Frustum culling
-   Distance culling
-   Per-instance culling
-   Occlusion culling

Chunk-level culling should be sufficient initially.

------------------------------------------------------------------------

# Level of Detail

Distant objects should become progressively cheaper.

For example:

``` text
Near tree
    ↓
Full low-poly mesh

Medium tree
    ↓
Simpler mesh

Far tree
    ↓
Billboard / extremely simple representation

Beyond view distance
    ↓
Not rendered
```

Fog can conceal these transitions.

------------------------------------------------------------------------

# Lighting

Keep the lighting model inexpensive.

Initially:

-   One directional light for the sun/moon
-   Cheap ambient lighting
-   Limited dynamic lights
-   Optional simple shadows

The campfire can use:

-   Small dynamic point light
-   Emissive fire geometry
-   Low-count particles
-   Sprite glow
-   Fire audio

The campfire can receive disproportionately more visual attention
because it is the central feature of the game.

------------------------------------------------------------------------

# Physics

Avoid simulating everything.

Use simple collision primitives.

Examples:

``` text
Player → capsule
Tree → cylinder/capsule
Rock → simple convex shape
Structure → simple box/convex shapes
```

Grass and decorative vegetation generally do not need physics.

Cutting down a tree can initially be an interaction/state transition
rather than a physically simulated falling tree.

------------------------------------------------------------------------

# Performance Targets

Initial performance budgets can be conservative.

Possible starting targets:

  System                Initial Target
  --------------------- --------------------------------
  Players               2--8
  Chunk size            64--128 m
  Active chunk region   \~7 × 7
  Trees per chunk       50--200
  Rocks per chunk       10--40
  View distance         200--500 m
  Simulation            30--60 Hz
  Network snapshots     10--20 Hz
  Dynamic entities      Hundreds rather than thousands

These are starting points rather than permanent limits.

Profiling should determine the final values.

------------------------------------------------------------------------

# Building System

The first building system should remain simple.

Players gather materials and place predefined structures.

Initial structures:

### Campfire

Required materials might include:

``` text
Sticks
Stone
Logs
```

Possible states:

``` text
Unlit
Lighting
Burning
Dying
Extinguished
```

### Log Seat

A simple placeable log that provides a sitting interaction.

### Stone Seat

A basic alternative seat.

### Lean-To

A simple shelter constructed from logs and branches.

More sophisticated building can be introduced after the core interaction
works.

------------------------------------------------------------------------

# Character System

Character creation should initially remain lightweight.

Possible customization:

-   Body presets
-   Hair
-   Clothing
-   Clothing colors
-   Skin tone
-   Simple accessories

Character silhouettes and animations are more important than highly
detailed models.

Characters should remain readable around the campfire and in low-light
conditions.

------------------------------------------------------------------------

# Audio

Audio will be particularly important because the game intentionally has
periods with little gameplay activity.

Useful environmental layers include:

-   Wind
-   Trees moving
-   Birds
-   Insects
-   River flow
-   Footsteps
-   Rain
-   Fire crackling

Sounds should use positional audio where appropriate.

A river should gradually become audible as a player approaches it.

------------------------------------------------------------------------

# Voice Chat

Voice communication is central to the final concept, but implementing
VOIP does not need to be an early milestone.

Initially, friends can use an external voice service.

Later, an in-game proximity voice system could use:

``` text
Microphone
    ↓
Audio capture
    ↓
Opus encoding
    ↓
Network transport
    ↓
Opus decoding
    ↓
3D positional playback
```

This would make voices naturally originate from nearby players around
the campfire.

------------------------------------------------------------------------

# Debugging and Development Tools

Do not build a full editor initially.

Use Dear ImGui for runtime development controls.

Useful panels could include:

``` text
World Generator
---------------
Seed
Terrain frequency
Terrain amplitude
Tree density
Rock density
River settings
Regenerate Chunks
```

Another:

``` text
Networking
----------
Ping
Connected players
Packets/sec
Bytes/sec
Server tick
Client tick
```

Another:

``` text
Rendering
---------
FPS
Frame time
Draw calls
Triangles
Visible chunks
Visible tree instances
```

JSON configuration files can provide persistent tuning values.

Python can be used for offline utilities and asset processing.

------------------------------------------------------------------------

# Suggested Architecture

A possible high-level architecture is:

``` text
Game
│
├── Platform
│   ├── Window
│   ├── Input
│   └── File System
│
├── Rendering
│   ├── Renderer
│   ├── Materials
│   ├── Meshes
│   ├── Instancing
│   ├── Camera
│   └── Lighting
│
├── World
│   ├── World
│   ├── Chunk
│   ├── Terrain Generator
│   ├── River Generator
│   ├── Forest Generator
│   └── World Streaming
│
├── Gameplay
│   ├── Player
│   ├── Inventory
│   ├── Interaction
│   ├── Gathering
│   ├── Building
│   └── Campfire
│
├── Networking
│   ├── Server
│   ├── Client
│   ├── Packets
│   └── Replication
│
├── Persistence
│   ├── World Save
│   └── Delta Log
│
├── Audio
│   ├── Audio Engine
│   └── Environment Audio
│
└── Debug
    ├── ImGui
    ├── Profiler
    └── Debug Rendering
```

Subsystems should communicate through clean interfaces rather than
directly depending on each other's internal implementation.

------------------------------------------------------------------------

# Development Milestones

There is no deadline, so milestones should represent complete learning
stages rather than calendar dates.

## Milestone 1 --- Engine Skeleton

Goal:

> Open a window and establish the basic application architecture.

Implement:

-   CMake project
-   SDL window
-   Main game loop
-   Input handling
-   Logging
-   Basic timing
-   Dear ImGui integration

------------------------------------------------------------------------

## Milestone 2 --- Basic Rendering

Goal:

> Render and move around a simple 3D environment.

Implement:

-   bgfx initialization
-   Camera
-   Perspective projection
-   Mesh rendering
-   Basic shader
-   Directional lighting
-   Simple debug geometry

------------------------------------------------------------------------

## Milestone 3 --- Player Controller

Goal:

> Walk around the environment.

Implement:

-   First- or third-person camera
-   Player capsule
-   Movement
-   Terrain collision
-   Interaction ray

------------------------------------------------------------------------

## Milestone 4 --- Procedural Terrain

Goal:

> Generate an explorable world.

Implement:

-   World seed
-   Chunk coordinates
-   Noise-based terrain
-   Terrain mesh generation
-   Chunk loading/unloading
-   Deterministic generation

------------------------------------------------------------------------

## Milestone 5 --- Procedural Forest

Goal:

> Turn the terrain into a recognizable forest.

Implement:

-   Tree generation
-   Rock generation
-   Clearings
-   Placement rules
-   GPU instancing
-   Chunk culling

------------------------------------------------------------------------

## Milestone 6 --- Multiplayer Foundation

Goal:

> Two players can walk through the same generated forest.

Implement:

-   ENet server
-   ENet client
-   Connect/disconnect
-   Player IDs
-   Transform replication
-   Shared world seed

This is an important milestone:

> Two computers generate the same forest from the same seed and can see
> each other's players.

------------------------------------------------------------------------

## Milestone 7 --- Campfire

Goal:

> Two players can build and sit around a campfire.

Implement:

-   Gather sticks
-   Gather stones
-   Simple inventory
-   Campfire placement
-   Networked placement
-   Fire state
-   Fire particles
-   Fire lighting
-   Fire audio
-   Sitting interaction

At this stage, the fundamental game concept exists.

------------------------------------------------------------------------

## Milestone 8 --- Persistence

Goal:

> The campsite remains after everyone leaves.

Implement:

-   World metadata
-   Structure persistence
-   Removed-resource persistence
-   Delta log
-   Save/load
-   Generator versioning

------------------------------------------------------------------------

## Milestone 9 --- Environment

Goal:

> Make simply existing in the world enjoyable.

Implement:

-   Day/night cycle
-   Better sky
-   Fog
-   Wind
-   River audio
-   Forest ambience
-   Improved lighting
-   Additional vegetation

------------------------------------------------------------------------

## Milestone 10 --- Expanded Campsite

Possible additions:

-   Lean-to
-   Log seating
-   Storage
-   Cooking
-   Lanterns
-   Decorations
-   Tents
-   Tools

------------------------------------------------------------------------

# First Complete Prototype

The first major target should be:

> Two friends launch the game. One hosts a world and the other joins.
> Both spawn in the same procedurally generated forest. They explore
> together, gather some sticks and stones, find a clearing near a river,
> build a campfire, sit down, and watch the environment transition into
> night.

If that experience is enjoyable, the foundation of the game works.

Everything else can grow from that point.

------------------------------------------------------------------------

# Guiding Technical Principle

The project should avoid unnecessary complexity while still exposing
interesting systems to learn.

The general philosophy should be:

> **Build the game-specific systems yourself; use focused open-source
> libraries for solved infrastructure problems.**

This means writing systems such as:

-   Procedural world generation
-   Chunk streaming
-   World persistence
-   Multiplayer replication
-   Gathering
-   Building
-   Campfire behavior
-   Environmental simulation

while relying on focused libraries for things such as:

-   Window creation
-   GPU abstraction
-   Audio device access
-   JSON parsing
-   Physics collision
-   UDP transport

This keeps the project educational without turning it entirely into
operating-system, graphics-driver, codec, or networking-protocol
implementation work.
