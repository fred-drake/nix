---
name: hytale-modding
description: Develop mods for Hytale, a voxel-based sandbox RPG by Hypixel Studios. Use when creating server plugins (commands, events, entities), working with the Entity Component System (ECS), creating custom UI, managing inventory, world generation, prefabs, or publishing mods. Covers Java 25 development with Maven, IntelliJ IDEA setup, and the complete plugin development lifecycle.
---

# Hytale Modding

## Quick Start

1. **Setup**: Java 25 + IntelliJ IDEA + Maven (see `references/dev-environment.md`)
2. **Clone template**: `git clone https://github.com/HytaleModding/plugin-template.git MyMod`
3. **Add server JAR**: Install HytaleServer.jar to local Maven repo
4. **Build**: `mvn package` produces JAR in `target/`
5. **Test**: Copy JAR to `%appdata%/Hytale/UserData/Mods/`

## Architecture: Entity Component System (ECS)

Hytale uses ECS - understand these core concepts:

| Concept | Purpose | Example |
|---------|---------|---------|
| **Entity** | Unique identifier (no data) | Player, Minecart, Block |
| **Component** | Data container (no logic) | TransformComponent, Health |
| **System** | Logic processor | DamageSystem, MovementSystem |
| **Store** | Entity manager | EntityStore, ChunkStore |
| **Holder** | Blueprint before spawning | "Shopping cart" for components |
| **Ref** | Safe entity reference | NEVER store entity objects directly |

See `references/ecs.md` for complete ECS guide.

## Plugin Structure

```
MyMod/
├── pom.xml                 # Maven config
├── manifest.json           # Plugin metadata
├── src/main/java/
│   └── com/example/
│       └── MyPlugin.java   # Main plugin class
└── resources/
    └── Common/UI/Custom/   # UI files (if using custom UI)
```

**Main Plugin Class**:
```java
public class MyPlugin extends JavaPlugin {
    @Override
    public void setup() {
        // Register commands, events, systems here
    }
}
```

## Common Tasks

### Creating Commands

Extend `AbstractPlayerCommand`:
```java
public class MyCommand extends AbstractPlayerCommand {
    public MyCommand() {
        super("mycommand", "Description");
    }

    @Override
    public void execute(CommandContext ctx, Store<EntityStore> store,
                        Ref<EntityStore> ref, PlayerRef player, World world) {
        player.sendMessage(Message.raw("Hello!"));
    }
}
```

Register in `setup()`: `getCommandRegistry().register(new MyCommand());`

### Listening to Events

```java
public static void onPlayerReady(PlayerReadyEvent event) {
    Player player = event.getPlayer();
    player.sendMessage(Message.raw("Welcome " + player.getDisplayName()));
}
```

Register: `getEventRegistry().registerGlobal(PlayerReadyEvent.class, MyEvents::onPlayerReady);`

### Spawning Entities

```java
world.execute(() -> {
    Holder<EntityStore> holder = EntityStore.REGISTRY.newHolder();
    ModelAsset asset = ModelAsset.getAssetMap().getAsset("Minecart");
    Model model = Model.createScaledModel(asset, 1.0f);

    holder.addComponent(new TransformComponent(position, rotation));
    holder.addComponent(new PersistentModel(model));
    holder.addComponent(new ModelComponent(model));
    // ... add required components

    store.addEntity(holder, AddReason.SPAWN);
});
```

### Playing Sounds

```java
int soundIndex = SoundEvent.getAssetMap().getIndex("SFX_Cactus_Large_Hit");
world.execute(() -> {
    SoundUtil.playSoundEvent3dToPlayer(playerRef, soundIndex,
        SoundCategory.UI, transform.getPosition(), store);
});
```

## Reference Documentation

| Topic | File | Contents |
|-------|------|----------|
| Dev Environment | `references/dev-environment.md` | Java 25, IntelliJ, Maven setup |
| ECS Architecture | `references/ecs.md` | Store, Holder, Ref, Components, Systems |
| Server Plugins | `references/server-plugins.md` | Commands, events, UI, packets |
| Gameplay Systems | `references/gameplay-systems.md` | Entities, inventory, blocks, prefabs |
| World Generation | `references/world-generation.md` | Zones, biomes, caves |
| Publishing | `references/publishing.md` | Modtale, CurseForge distribution |

## Key APIs

**Entity Access**:
- `player.getWorld()` - Get world from player
- `world.getEntityStore().getStore()` - Get entity store
- `store.getComponent(ref, componentType)` - Get component from entity

**Common Components**:
- `TransformComponent` - Position and rotation
- `PlayerRef` / `Player` - Player connection and presence
- `UUIDComponent` - Entity unique ID
- `ModelComponent` - Visual model

**System Types**:
- `EntityTickingSystem` - Per-entity each tick
- `TickingSystem` - Global each tick
- `DelayedEntitySystem` - Per-entity with delay
- `RefChangeSystem` - React to component changes

## Manifest.json

```json
{
    "PluginId": "com.example.myplugin",
    "PluginName": "My Plugin",
    "PluginVersion": "1.0.0",
    "IncludesAssetPack": true
}
```

Set `IncludesAssetPack: true` when including custom UI or assets.

## Testing Workflow

1. Build: `mvn package`
2. Copy JAR to `%appdata%/Hytale/UserData/Mods/`
3. Launch Hytale → Create World → Settings → Mods
4. Enable "Diagnostic Mode" in settings for error details
