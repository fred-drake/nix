# Development Environment Setup

## Table of Contents
- [Prerequisites](#prerequisites)
- [Java Development Kit](#java-development-kit)
- [IntelliJ IDEA](#intellij-idea)
- [Maven](#maven)
- [Workspace Setup](#workspace-setup)
- [HytaleServer.jar Installation](#hytaleserverjar-installation)

## Prerequisites

- Windows 10/11, macOS, or Linux
- Minimum 8GB RAM
- 10GB free disk space
- Administrative privileges

## Java Development Kit

Hytale modding requires **Java 25 or later**. Use OpenJDK from Adoptium.

### Windows
1. Download OpenJDK 25 from [Adoptium](https://adoptium.net/)
2. Run installer with default settings
3. Verify: `java -version`

### macOS
```bash
brew install openjdk@25

# Add to PATH if needed
echo 'export PATH="$(brew --prefix)/opt/openjdk@25/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

### Linux (Ubuntu/Debian)
```bash
sudo apt update
sudo apt install openjdk-25-jdk
```

## IntelliJ IDEA

**Recommended IDE**: IntelliJ IDEA Community Edition

1. Download from [JetBrains](https://www.jetbrains.com/idea/download/)
2. Install with defaults
3. Complete initial setup wizard

## Maven

1. Download `apache-maven-3.9.12-bin.zip` from [maven.apache.org](https://maven.apache.org/download.cgi)
2. Unzip the archive
3. Add `apache-maven-3.9.12/bin/` to system PATH
4. Verify: `mvn -version`

## Workspace Setup

### Clone Template Repository
```bash
git clone https://github.com/HytaleModding/plugin-template.git MyFirstMod
cd MyFirstMod
```

### Import into IntelliJ IDEA
1. Open IntelliJ IDEA
2. Click "Open" and select project directory
3. IDE auto-detects Maven project
4. Wait for indexing and dependency downloads

## HytaleServer.jar Installation

### Download Server JAR
1. Use Hytale Downloader to obtain HytaleServer.jar

### Add as IntelliJ Library
1. File → Project Structure → Libraries
2. Click + icon
3. Select the JAR file

### Install to Maven Repository
```bash
mvn install:install-file \
  -Dfile="[PATH_TO_JAR]" \
  -DgroupId="com.hypixel.hytale" \
  -DartifactId="HytaleServer-parent" \
  -Dversion="1.0-SNAPSHOT" \
  -Dpackaging="jar"
```

**PowerShell note**: Wrap parameters in quotes to avoid errors.

## Project Configuration Files

### pom.xml
Maven project configuration with dependencies and build settings.

### manifest.json
Plugin metadata:
```json
{
    "PluginId": "com.example.myplugin",
    "PluginName": "My Plugin",
    "PluginVersion": "1.0.0",
    "IncludesAssetPack": false
}
```

Set `IncludesAssetPack: true` when including custom UI or asset files.
