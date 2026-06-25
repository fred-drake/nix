# Server Plugins

## Table of Contents
- [Plugin Structure](#plugin-structure)
- [Commands](#commands)
- [Events](#events)
- [Sounds](#sounds)
- [Custom UI](#custom-ui)
- [Chat Formatting](#chat-formatting)
- [Packets](#packets)

## Plugin Structure

### Main Plugin Class
```java
public class MyPlugin extends JavaPlugin {
    @Override
    public void setup() {
        // Register commands
        getCommandRegistry().register(new MyCommand());

        // Register events
        getEventRegistry().registerGlobal(
            PlayerReadyEvent.class,
            MyEvents::onPlayerReady
        );

        // Register ECS components/systems
        getEntityStoreRegistry().registerComponent(MyComponent.class);
        getEntityStoreRegistry().registerSystem(new MySystem());
    }
}
```

## Commands

Commands extend `AbstractPlayerCommand` (async) or `AbstractCommand`.

### Basic Command
```java
public class GreetCommand extends AbstractPlayerCommand {
    public GreetCommand() {
        super("greet", "Greet a player");
    }

    @Override
    public void execute(CommandContext ctx, Store<EntityStore> store,
                        Ref<EntityStore> ref, PlayerRef player, World world) {
        player.sendMessage(Message.raw("Hello, " + player.getDisplayName()));
    }
}
```

### Command with Arguments
```java
public class TeleportCommand extends AbstractPlayerCommand {
    public TeleportCommand() {
        super("tp", "Teleport to coordinates");
        // Required arguments
        withRequiredArg("x", ArgumentType.DOUBLE);
        withRequiredArg("y", ArgumentType.DOUBLE);
        withRequiredArg("z", ArgumentType.DOUBLE);
        // Optional argument
        withOptionalArg("world", ArgumentType.STRING);
    }

    @Override
    public void execute(CommandContext ctx, Store<EntityStore> store,
                        Ref<EntityStore> ref, PlayerRef player, World world) {
        double x = ctx.getDouble("x");
        double y = ctx.getDouble("y");
        double z = ctx.getDouble("z");
        // Teleport logic...
    }
}
```

### Argument Types
- `STRING`, `INTEGER`, `BOOLEAN`, `FLOAT`, `DOUBLE`, `UUID`

**Note**: Commands execute off the main server thread (AbstractAsyncCommand).

## Events

### Standard Events
```java
public class MyEvents {
    public static void onPlayerReady(PlayerReadyEvent event) {
        Player player = event.getPlayer();
        player.sendMessage(Message.raw("Welcome!"));
    }

    public static void onPlayerChat(PlayerChatEvent event) {
        String message = event.getMessage();
        // Handle chat...
    }
}
```

Register in setup():
```java
getEventRegistry().registerGlobal(PlayerReadyEvent.class, MyEvents::onPlayerReady);
```

### Common Event Types

**IEvent (base events)**:
- `PlayerConnectEvent`, `PlayerDisconnectEvent`
- `PlayerReadyEvent`
- `AddWorldEvent`, `RemoveWorldEvent`
- `StartWorldEvent`, `AllWorldsLoadedEvent`

**IAsyncEvent (async events)**:
- `PlayerChatEvent`

**EcsEvent (cancellable)**:
- `BreakBlockEvent`, `PlaceBlockEvent`
- `InteractivelyPickupItemEvent`
- `SwitchActiveSlotEvent`
- `MoonPhaseChangeEvent`

### ECS Event Classes
For entity-based events, extend `EntityEventSystem`:
```java
public class CraftingEventSystem extends EntityEventSystem<EntityStore> {
    @Override
    public Query getQuery() {
        return Query.and(CraftingComponent.getComponentType());
    }

    @Override
    public void handle(Store<EntityStore> store, Ref<EntityStore> ref,
                       CommandBuffer<EntityStore> buffer) {
        // Handle crafting event
    }
}
```

Register: `getEntityStoreRegistry().registerSystem(new CraftingEventSystem());`

## Sounds

### Playing 3D Sound to Player
```java
// Get sound index
int soundIndex = SoundEvent.getAssetMap().getIndex("SFX_Cactus_Large_Hit");

// Get player transform
TransformComponent transform = store.getComponent(
    playerRef,
    EntityModule.get().getTransformComponentType()
);

// Play sound (must be in world.execute())
world.execute(() -> {
    SoundUtil.playSoundEvent3dToPlayer(
        playerRef,
        soundIndex,
        SoundCategory.UI,
        transform.getPosition(),
        store
    );
});
```

### Sound Categories
- `SoundCategory.Music`
- `SoundCategory.Ambient`
- `SoundCategory.SFX`
- `SoundCategory.UI`

## Custom UI

### File Structure
Place UI files in `resources/Common/UI/Custom/` within your plugin.

Set `"IncludesAssetPack": true` in manifest.json.

### UI File Syntax (HTML/CSS-like)
```
Group {
    TextField #MyInput {
        Style: $Common.@DefaultInputFieldStyle;
        Background: $Common.@InputBoxBackground;
        Anchor: (Top: 10, Width: 200, Height: 50);
    }

    Label #MyLabel {
        TextSpans: "Hello World";
        Anchor: (Top: 70, Width: 200, Height: 30);
    }
}
```

### Variables and Resources
```
@MyTex = PatchStyle(TexturePath: "MyBackground.png");
$Common = "Common.ui";
```

Use `$Common.@DefaultInputFieldStyle` to reference external styles.

### HUD (Persistent Display)
```java
public class MyHud extends CustomUIHud {
    @Override
    protected void build(HudBuilder builder) {
        builder.appendFile("MyHud.ui");
    }
}

// Display HUD
HudManager.setCustomHud(player, new MyHud());

// Hide default UI elements
HudManager.hideHudComponents(player, HudComponent.HEALTH, HudComponent.HOTBAR);
```

### Interactive Page
```java
public class MyPage extends InteractiveCustomUIPage {
    public static class Data {
        public static final BuilderCodec<Data> CODEC =
            BuilderCodec.builder(Data.class, Data::new)
                .append(new KeyedCodec<>("@MyInput", Codec.STRING),
                    (data, value) -> data.value = value,
                    data -> data.value)
                .add()
                .build();

        private String value;
    }

    @Override
    protected void build(UIBuilder builder, UIEventBuilder uiEventBuilder) {
        builder.appendFile("MyPage.ui");

        // Bind events
        uiEventBuilder.addEventBinding(
            CustomUIEventBindingType.ValueChanged,
            "#MyInput",
            EventData.of("@MyInput", "#MyInput.Value"),
            false
        );
    }

    @Override
    protected void handleDataEvent(Data data) {
        // Handle user input
        sendUpdate();  // Always call or UI shows "Loading..."
    }
}
```

### Dynamic UI Updates
```java
public void updateText(String newText) {
    UICommandBuilder builder = new UICommandBuilder();
    builder.set("#MyLabel.TextSpans", Message.raw(newText));
    update(false, builder);
}
```

## Chat Formatting

Use `Message` class for formatted text:
```java
player.sendMessage(Message.raw("Plain text"));
player.sendMessage(Message.styled("Bold text", Style.BOLD));
player.sendMessage(Message.colored("Red text", Color.RED));
```

## Packets

### Listening to Client Packets
```java
public class PacketListener {
    public static void onClientInput(ClientInputPacket packet, PlayerRef player) {
        // Handle input packet
    }
}

// Register
getPacketRegistry().register(ClientInputPacket.class, PacketListener::onClientInput);
```

### Common Packet Types
- `ClientInputPacket` - Player input (movement, actions)
- `ClientChatPacket` - Chat messages
- Various game-specific packets
