# Publishing Your Mod

## Table of Contents
- [Preparation](#preparation)
- [Building for Release](#building-for-release)
- [Publishing Platforms](#publishing-platforms)
- [Best Practices](#best-practices)

## Preparation

### Pre-Release Checklist
- [ ] Test thoroughly in multiple scenarios
- [ ] Update version number in manifest.json
- [ ] Update version in pom.xml
- [ ] Write clear description and changelog
- [ ] Create screenshots/videos if applicable
- [ ] Ensure no debug/test code remains
- [ ] Verify all dependencies are documented

### Manifest.json for Release
```json
{
    "PluginId": "com.yourname.modname",
    "PluginName": "Your Mod Name",
    "PluginVersion": "1.0.0",
    "PluginDescription": "Clear description of what your mod does",
    "PluginAuthor": "Your Name",
    "IncludesAssetPack": true
}
```

## Building for Release

### Clean Build
```bash
mvn clean package
```

### Output Location
JAR file appears in `target/` directory:
- `YourMod-1.0.0.jar` (based on artifactId and version in pom.xml)

### Verify Build
1. Copy to fresh Hytale installation
2. Test all features work as expected
3. Check for errors in game logs

## Publishing Platforms

### Modtale
Primary Hytale mod marketplace.

**Steps**:
1. Create account at Modtale
2. Navigate to mod upload section
3. Fill in mod details:
   - Title
   - Description
   - Category
   - Screenshots
   - Version
4. Upload JAR file
5. Submit for review

### CurseForge
Established modding platform.

**Steps**:
1. Create CurseForge account
2. Navigate to Hytale section
3. Create new project
4. Upload mod files
5. Configure project settings
6. Publish

### Direct Distribution
For private or limited distribution:
- Host on personal website
- Share via Discord servers
- GitHub releases

## Best Practices

### Versioning
Use semantic versioning (MAJOR.MINOR.PATCH):
- **MAJOR**: Breaking changes
- **MINOR**: New features, backward compatible
- **PATCH**: Bug fixes

### Documentation
Include with your mod:
- Installation instructions
- Feature list
- Configuration options
- Known issues
- Changelog

### Updates
- Maintain backward compatibility when possible
- Clearly document breaking changes
- Provide migration guides for major updates

### Community Engagement
- Respond to bug reports
- Consider feature requests
- Provide support channels (Discord, GitHub Issues)

### Legal Considerations
- Include appropriate license
- Credit any third-party resources
- Follow Hytale's modding guidelines and terms

## FAQ

### Can I monetize my mod?
Check Hytale's official modding terms for monetization policies.

### How do I handle mod conflicts?
- Use unique package names
- Avoid modifying core game files directly
- Provide configuration options for compatibility

### What about client mods?
Currently, the client cannot be modified directly. Server plugins control visuals similar to Minecraft resource packs.
