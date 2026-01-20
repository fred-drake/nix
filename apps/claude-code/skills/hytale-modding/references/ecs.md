# Entity Component System (ECS)

## Table of Contents
- [Core Concepts](#core-concepts)
- [Store](#store)
- [Holder (Blueprint Pattern)](#holder-blueprint-pattern)
- [Ref (Safe References)](#ref-safe-references)
- [Components](#components)
- [Systems](#systems)
- [CommandBuffer](#commandbuffer)
- [Queries](#queries)

## Core Concepts

ECS emphasizes **composition over inheritance**:
- **Entities**: Unique identifiers with no data or logic
- **Components**: Data containers with no behavior
- **Systems**: Logic that operates on entities with specific components

Instead of "is a" (inheritance), use "has a" (composition).

## Store

The `Store` class manages entity storage using **Archetypes** - groups of similar entities for optimized retrieval.

### EntityStore
Implements `WorldProvider`, manages entities within worlds:
- `entitiesByUuid` - Lookup by persistent UUID
- `networkIdToRef` - Lookup by network ID

### ChunkStore
Manages block-related components:
- `WorldChunk` containing `EntityChunk` and `BlockChunk`

### Getting the Store
```java
// From player
World world = player.getWorld();
Store<EntityStore> store = world.getEntityStore().getStore();

// From Universe
World world = Universe.get().getWorld("world-uuid");
Store<EntityStore> store = world.getEntityStore().getStore();
```

## Holder (Blueprint Pattern)

Holders are blueprints for entities before they exist in the store. Think of it as a shopping cart: collect all components, then "check out" at the store.

```java
Holder<EntityStore> holder = EntityStore.REGISTRY.newHolder();

// Add components to holder
holder.addComponent(new TransformComponent(position, rotation));
holder.addComponent(new PersistentModel(model));
holder.addComponent(new ModelComponent(model));
holder.addComponent(new BoundingBox(...));
holder.addComponent(new NetworkId());

// Spawn entity
store.addEntity(holder, AddReason.SPAWN);
```

## Ref (Safe References)

`Ref` objects are safe handles to entities that track entity lifecycle.

**Critical Rule**: NEVER store direct references to entity objects. Always use Ref.

```java
Ref<EntityStore> playerRef = player.getReference();

// Get component via ref
TransformComponent transform = store.getComponent(
    playerRef,
    EntityModule.get().getTransformComponentType()
);
```

## Components

Components are pure data containers implementing `Component<EntityStore>`.

### Requirements
- Default constructor (for registration)
- Copy constructor (for cloning)
- `getComponentType()` static method
- `clone()` method
- `BuilderCodec CODEC` for serialization

### Example Component
```java
public class PoisonComponent implements Component<EntityStore> {
    private float damage;
    private float tickInterval;
    private float elapsedTime;

    public PoisonComponent() {}  // Default constructor

    public PoisonComponent(float damage, float tickInterval) {
        this.damage = damage;
        this.tickInterval = tickInterval;
        this.elapsedTime = 0;
    }

    // Copy constructor
    public PoisonComponent(PoisonComponent other) {
        this.damage = other.damage;
        this.tickInterval = other.tickInterval;
        this.elapsedTime = other.elapsedTime;
    }

    public static ComponentType<EntityStore, PoisonComponent> getComponentType() {
        return COMPONENT_TYPE;
    }

    @Override
    public PoisonComponent clone() {
        return new PoisonComponent(this);
    }
}
```

### Common Built-in Components
- `TransformComponent` - Position (Vector3d) and rotation (Vector3f)
- `PlayerRef` - Player connection, username, UUID, packet handlers
- `Player` - Physical presence in world (only when spawned)
- `UUIDComponent` - Entity unique identifier
- `ModelComponent` - Visual model
- `BoundingBox` - Collision bounds
- `NetworkId` - Network synchronization

## Systems

Systems contain logic and operate on entities matching component queries.

### System Types

#### EntityTickingSystem
Most common - executes every tick per matching entity:
```java
public class PoisonSystem extends EntityTickingSystem<EntityStore> {
    @Override
    public Query getQuery() {
        return Query.and(poisonComponentType, Player.getComponentType());
    }

    @Override
    public void tick(float deltaTime, Store<EntityStore> store,
                     Ref<EntityStore> ref, CommandBuffer<EntityStore> buffer) {
        PoisonComponent poison = store.getComponent(ref, poisonComponentType);
        // Apply poison damage...
    }
}
```

#### TickingSystem
Executes once per tick globally (no entity targeting):
```java
public class WorldUpdateSystem extends TickingSystem<EntityStore> {
    @Override
    public void tick(float deltaTime, Store<EntityStore> store,
                     CommandBuffer<EntityStore> buffer) {
        // Global world update logic
    }
}
```

#### DelayedEntitySystem
Per-entity with built-in delay (constructor accepts seconds):
```java
public class RegenerationSystem extends DelayedEntitySystem<EntityStore> {
    public RegenerationSystem() {
        super(5.0f);  // Execute every 5 seconds
    }
}
```

#### RefChangeSystem
Monitors component changes - triggers on add/update/remove:
```java
public class ComponentWatcher extends RefChangeSystem<EntityStore> {
    @Override
    public void onComponentAdded(Ref<EntityStore> ref, Component component) {
        // React to component addition
    }
}
```

### Registration
```java
@Override
public void setup() {
    getEntityStoreRegistry().registerComponent(PoisonComponent.class);
    getEntityStoreRegistry().registerSystem(new PoisonSystem());
}
```

## CommandBuffer

Queues entity modifications for thread safety:

```java
// Add component
buffer.addComponent(ref, componentType, new MyComponent());

// Remove component
buffer.removeComponent(ref, componentType);

// Get component (may be queued)
MyComponent comp = buffer.getComponent(ref, componentType);
```

Use CommandBuffer instead of direct store modifications in systems.

## Queries

Queries filter which entities a system processes:

```java
// Single component
Query.and(poisonComponentType)

// Multiple components (AND)
Query.and(poisonComponentType, Player.getComponentType())

// Exclusion (NOT)
Query.and(Player.getComponentType(), Query.not(DeathComponent.getComponentType()))
```

### System Groups and Dependencies

Systems execute in groups for ordered processing. Example damage pipeline:
1. `GatherDamageGroup` - Collect damage sources
2. `FilterDamageGroup` - Apply reductions/cancellations
3. Apply damage to health
4. `InspectDamageGroup` - Handle side effects
