# Gameplay Systems

## Table of Contents
- [Entities](#entities)
- [Spawning Entities](#spawning-entities)
- [Inventory Management](#inventory-management)
- [Block Components](#block-components)
- [Prefabs](#prefabs)

## Entities

### Entity Categories

**Animals**: Antelope, Bat, Bear, Bison, Bluebird, Boar, Bunny, Camel, Cat, Chicken, Cow, Deer, Dog, Duck, etc.

**Hostile Creatures**: Ghoul, Skeleton (multiple variants), Zombie (variants), Dragons (Fire, Frost, Void)

**NPCs**: Feran (various types), Goblin (variants), Outlander (types), Slothian (roles), Trork (classes)

**Special**: Debug, Mannequin, Minecart, Player, Warp, Trash

### Getting Entity Models
```java
ModelAsset modelAsset = ModelAsset.getAssetMap().getAsset("Minecart");
Model model = Model.createScaledModel(modelAsset, 1.0f);
```

## Spawning Entities

### Complete Spawn Example
```java
// Get world and store
World world = player.getWorld();
Store<EntityStore> store = world.getEntityStore().getStore();

// Must execute within world context
world.execute(() -> {
    // Create holder (blueprint)
    Holder<EntityStore> holder = EntityStore.REGISTRY.newHolder();

    // Get model
    ModelAsset modelAsset = ModelAsset.getAssetMap().getAsset("Minecart");
    Model model = Model.createScaledModel(modelAsset, 1.0f);

    // Position and rotation
    Vector3d position = new Vector3d(100, 50, 100);
    Vector3f rotation = new Vector3f(0, 0, 0);

    // Add required components
    holder.addComponent(new TransformComponent(position, rotation));
    holder.addComponent(new PersistentModel(model));
    holder.addComponent(new ModelComponent(model));
    holder.addComponent(new BoundingBox(/* bounds */));
    holder.addComponent(new NetworkId());

    // Add default Hytale components
    holder.addComponent(new UUIDComponent(UUID.randomUUID()));

    // For interactable entities
    holder.addComponent(new Interactable());
    holder.addComponent(new Interactions(/* interaction handlers */));

    // Spawn entity
    store.addEntity(holder, AddReason.SPAWN);
});
```

### Required Components for Entities
- `TransformComponent` - Position and rotation
- `PersistentModel` - Model persistence
- `ModelComponent` - Visual representation
- `BoundingBox` - Collision bounds
- `NetworkId` - Network synchronization
- `UUIDComponent` - Unique identifier

## Inventory Management

### Accessing Inventory
```java
Inventory inventory = player.getInventory();
```

### Inventory Pages (Page enum)
- `Page.None`
- `Page.Bench`
- `Page.Inventory`
- `Page.ToolsSettings`
- `Page.Map`
- `Page.MachinimaEditor`
- `Page.ContentCreation`
- `Page.Custom`

### Opening Inventory Page
```java
PageManager pageManager = player.getPageManager();
pageManager.setPage(Page.Inventory);
```

### Creating ItemStacks
```java
// Basic item
ItemStack item = new ItemStack("Stone");

// With quantity
ItemStack stack = new ItemStack("Stone", 64);

// With durability
ItemStack tool = new ItemStack("DiamondSword", 1, 100.0, 100.0, metadata);

// With custom metadata (BsonDocument)
BsonDocument metadata = new BsonDocument();
metadata.put("customKey", new BsonString("customValue"));
ItemStack customItem = new ItemStack("Stone", 1, metadata);
```

### Item Containers
```java
// Individual containers
ItemContainer storage = inventory.getStorage();
ItemContainer armor = inventory.getArmor();
ItemContainer backpack = inventory.getBackpack();
ItemContainer hotbar = inventory.getHotbar();
ItemContainer utility = inventory.getUtility();

// Combined access
ItemContainer everything = inventory.getCombinedEverything();
```

### Adding Items
```java
// Add to any available slot
storage.addItemStack(itemStack);

// Add to specific slot
storage.addItemStackToSlot(itemStack, slotIndex);
```

### Removing Items
```java
// Remove item
storage.removeItemStack(itemStack);

// Remove from specific slot
storage.removeItemStackFromSlot(slotIndex);
```

## Block Components

Block components enable custom block behavior through the ECS system.

### Block Component Class
```java
public class ExampleBlock implements Component<ChunkStore> {
    public static final BuilderCodec<ExampleBlock> CODEC = /* serialization */;

    private static ComponentType<ChunkStore, ExampleBlock> COMPONENT_TYPE;

    public ExampleBlock() {}

    public static ComponentType<ChunkStore, ExampleBlock> getComponentType() {
        return COMPONENT_TYPE;
    }

    public void runBlockAction(World world, int worldX, int worldY, int worldZ) {
        // Block behavior - e.g., place Ice Block at x+1
        world.setBlock(worldX + 1, worldY, worldZ, BlockType.ICE);
    }

    @Override
    public ExampleBlock clone() {
        return new ExampleBlock();
    }
}
```

### Block Ticking System
```java
public class ExampleSystem extends EntityTickingSystem<ChunkStore> {
    @Override
    public Query getQuery() {
        return Query.and(
            BlockSection.getComponentType(),
            ChunkSection.getComponentType()
        );
    }

    @Override
    public BlockTickStrategy tick(float deltaTime, Store<ChunkStore> store,
                                   Ref<ChunkStore> ref,
                                   CommandBuffer<ChunkStore> buffer) {
        // Get block section
        BlockSection blockSection = store.getComponent(ref, BlockSection.getComponentType());

        // Iterate ticking blocks
        for (TickingBlock block : blockSection.getTickingBlocks()) {
            ExampleBlock comp = block.getComponent(ExampleBlock.getComponentType());
            if (comp != null) {
                // Convert local to world coordinates
                int worldX = chunkX * 16 + block.getLocalX();
                int worldY = chunkY * 16 + block.getLocalY();
                int worldZ = chunkZ * 16 + block.getLocalZ();

                comp.runBlockAction(world, worldX, worldY, worldZ);
            }
        }

        return BlockTickStrategy.CONTINUE;
    }
}
```

### Registration
```java
@Override
public void setup() {
    getChunkStoreRegistry().registerComponent(ExampleBlock.class);
    getChunkStoreRegistry().registerSystem(new ExampleSystem());
}
```

## Prefabs

Prefabs are reusable structures saved as JSON files.

### Creating a Prefab
1. `/editprefab new <world name>` - Create editing world
2. Build your structure
3. Use selection brush to select area
4. `/prefab save` - Save structure
5. `/editprefab exit` - Exit editing world
6. Use Paste brush and press 'e' to select prefab

### Prefab Commands

**`/prefab`** - Manage existing prefabs:
- `save` - Save current selection
- `load <name>` - Load prefab
- `delete <name>` - Delete prefab
- `list` - List available prefabs

**`/editprefab`** - Create/modify prefabs:
- `new <name>` - Create new editing world
- `load <name>` - Load existing prefab for editing
- `exit` - Exit editing world
- `save` - Save changes

### Using Prefabs
- Press 't' to toggle material visualization
- Paste brush applies prefab to world
- Prefabs can be spawned programmatically via world generation
