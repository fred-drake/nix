# World Generation

## Table of Contents
- [Overview](#overview)
- [Zones](#zones)
- [Biomes](#biomes)
- [Caves](#caves)
- [System Integration](#system-integration)

## Overview

Hytale's procedural world generation uses three interconnected systems:

| System | Scope | Purpose |
|--------|-------|---------|
| **Zones** | Large-scale | Overall world structure and regions |
| **Biomes** | Within zones | Terrain characteristics and environment |
| **Caves** | Underground | Cave networks and structures |

## Zones

Zones define large-scale regions with distinct characteristics.

### Zone Lookup
```java
ZonePatternGenerator zoneGen = /* world generator */;
ZoneGeneratorResult zoneResult = zoneGen.generate(seed, x, z);
Zone zone = zoneResult.getZone();
```

### Creating Custom Zones

Configure zone discovery settings:
```java
ZoneDiscoveryConfig config = new ZoneDiscoveryConfig()
    .setDisplayName("My Zone")
    .setSoundEvent("zone_discovery_sound")
    .setIconResource("textures/zone_icon.png")
    .setMajorZone(true)
    .setAnimationDuration(2.0f)
    .setFadeIn(0.5f)
    .setFadeOut(0.5f);
```

Assign generators to zone:
```java
zone.setBiomePatternGenerator(biomeGenerator);
zone.setCaveGenerator(caveGenerator);
zone.addPrefab(structurePrefab);
```

### Zone Properties
- Notification display settings
- Display names and icons
- Sound events on discovery
- Major/minor zone designation
- Animation timings
- Associated biomes and caves
- Unique structure prefabs

## Biomes

Biomes define terrain characteristics within zones.

### Biome Generation
```java
// Get biome from zone
BiomePatternGenerator biomeGen = zone.getBiomePatternGenerator();
Biome biome = biomeGen.generate(seed, x, z);
```

### Biome Properties
- Terrain height and variation
- Block composition (surface, subsurface, deep)
- Vegetation and decoration
- Weather and atmosphere
- Mob spawning rules

## Caves

Caves generate underground structures and networks.

### Cave Generation
```java
// Check if zone has caves
CaveGenerator caveGen = zone.getCaveGenerator();
if (caveGen != null) {
    CaveResult cave = caveGen.generate(seed, x, y, z);
    // Process cave data...
}
```

### Cave Properties
- Tunnel networks
- Cave room generation
- Underground biomes
- Ore distribution
- Structure placement

## System Integration

### Zone-Biome Integration
Each zone defines its own biome pattern, allowing region-specific terrain:
```java
Zone forestZone = new Zone();
forestZone.setBiomePatternGenerator(new ForestBiomeGenerator());

Zone desertZone = new Zone();
desertZone.setBiomePatternGenerator(new DesertBiomeGenerator());
```

### Zone-Cave Integration
Zones specify their cave patterns:
```java
zone.setCaveGenerator(new StandardCaveGenerator());
// or for specific cave types
zone.setCaveGenerator(new CrystalCaveGenerator());
```

### Biome-Cave Integration
Caves use biome masks for placement control:
```java
caveGenerator.setBiomeMask(BiomeMask.EXCLUDE, "desert", "ocean");
// Caves won't generate in desert or ocean biomes
```

### Border Transitions
Systems respect zone boundaries with smooth transitions:
```java
// Calculate distance to border
float borderDistance = zone.getDistanceToBorder(x, z);

// Fade biome properties near borders
if (borderDistance < TRANSITION_WIDTH) {
    float blend = borderDistance / TRANSITION_WIDTH;
    // Blend between adjacent zone biomes
}
```

### Custom World Generation

Register custom generators in plugin setup:
```java
@Override
public void setup() {
    // Register custom zone
    getWorldGenRegistry().registerZone("my_zone", new MyZoneGenerator());

    // Register custom biome
    getWorldGenRegistry().registerBiome("my_biome", new MyBiomeGenerator());

    // Register custom cave
    getWorldGenRegistry().registerCave("my_cave", new MyCaveGenerator());
}
```
