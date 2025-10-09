{
  pkgs,
  lib,
  stdenv,
  cmake,
  ninja,
  nodejs,
  qt6,
  qt6Packages,
  kdePackages,
  protobuf,
  cmark-gfm,
  libqalculate,
  minizip,
  rapidfuzz-cpp,
}: let
  repos-src = import ../apps/fetcher/repos-src.nix {inherit pkgs;};
in
  stdenv.mkDerivation rec {
    pname = "vicinae";
    version = "latest";

    src = repos-src.vicinae-src;

    nativeBuildInputs = [
      cmake
      ninja
      nodejs
      qt6.wrapQtAppsHook
    ];

    buildInputs = [
      qt6.qtbase
      qt6.qtsvg
      qt6.qtwayland
      kdePackages.layer-shell-qt
      protobuf
      cmark-gfm
      libqalculate
      minizip
      qt6Packages.qtkeychain
      rapidfuzz-cpp
    ];

    preConfigure = ''
            export HOME=$TMPDIR

            # Make npm unavailable to prevent CMake from finding it
            export PATH=$(echo $PATH | tr ':' '\n' | grep -v node | tr '\n' ':')

            # Create a fake npm that does nothing
            mkdir -p $TMPDIR/bin
            cat > $TMPDIR/bin/npm << 'EOF'
      #!/bin/sh
      echo "npm is disabled in Nix build"
      exit 0
      EOF
            chmod +x $TMPDIR/bin/npm
            export PATH=$TMPDIR/bin:$PATH
    '';

    patchPhase = ''
      runHook prePatch

      # Find and patch the main CMakeLists.txt to completely skip TypeScript builds
      sed -i '/add_subdirectory.*typescript/d' CMakeLists.txt
      sed -i '/include.*ExtensionApi/d' CMakeLists.txt
      sed -i '/include.*ExtensionManager/d' CMakeLists.txt

      # Replace the entire ExtensionApi.cmake to skip npm builds
      cat > cmake/ExtensionApi.cmake << 'EOF'
      # Dummy ExtensionApi.cmake to skip npm builds
      set(EXT_API_SRC_DIR "$\{CMAKE_SOURCE_DIR}/api")
      set(EXT_API_OUT_DIR "$\{CMAKE_SOURCE_DIR}/api/dist")
      set(API_DIST_DIR "$\{CMAKE_SOURCE_DIR}/api/dist")

      # Create empty target (do nothing)
      add_custom_target(build-api
        COMMAND ${pkgs.coreutils}/bin/true
        COMMENT "Skipping API build (Nix)"
      )
      EOF

      # Replace ExtensionManager.cmake if it exists
      if [ -f cmake/ExtensionManager.cmake ]; then
        cat > cmake/ExtensionManager.cmake << 'EOF'
      # Dummy ExtensionManager.cmake to skip npm builds
      set(EXT_MANAGER_DIST "$\{CMAKE_SOURCE_DIR}/vicinae/assets/extension-runtime.js")

      # Create empty target (do nothing)
      add_custom_target(build-extension-manager
        COMMAND ${pkgs.coreutils}/bin/true
        COMMENT "Skipping Extension Manager build (Nix)"
      )
      EOF
      fi

      # Completely remove typescript directory from build if it exists
      if [ -d typescript ]; then
        rm -rf typescript/*/CMakeLists.txt || true
      fi

      # Create all required dummy files that the build expects
      mkdir -p api/dist/dist/components api/dist/dist/hooks api/dist/dist/context api/dist/dist/jsx
      mkdir -p api/dist/components api/dist/hooks api/dist/context api/dist/bin api/dist/lib
      mkdir -p vicinae/assets extension-manager/dist

      # Create main API files
      for file in ai alert bus cache clipboard color controls environment hooks icon image index keyboard local-storage oauth preference toast utils; do
        echo "export {};" > api/dist/$file.js
        echo "export {};" > api/dist/dist/$file.d.js
      done

      # Create component files
      for file in action-pannel actions detail empty-view form index list metadata tag; do
        echo "export {};" > api/dist/dist/components/$file.d.js
      done
      echo "export {};" > api/dist/components/index.js

      # Create hook files
      for file in index use-applications use-imperative-form-handle use-navigation; do
        echo "export {};" > api/dist/dist/hooks/$file.d.js
        echo "export {};" > api/dist/hooks/$file.js
      done

      # Create context files
      for file in index navigation-context navigation-provider; do
        echo "export {};" > api/dist/dist/context/$file.d.js
        echo "export {};" > api/dist/context/$file.js
      done

      # Create bin files
      for file in build develop main utils; do
        echo "#!/usr/bin/env node" > api/dist/bin/$file.js
      done

      # Create other required files
      echo "export {};" > api/dist/dist/jsx/jsx-runtime.d.js
      echo "export {};" > api/dist/lib/result.js
      echo "export {};" > api/dist/bus.d.js
      echo "export {};" > api/dist/index.d.js
      echo "export {};" > api/dist/hooks/index.d.js
      echo "export {};" > api/dist/hooks/use-applications.d.js
      echo "export {};" > api/dist/hooks/use-navigation.d.js
      echo "export {};" > api/dist/context/index.d.js

      # Create extension runtime
      echo "// Extension runtime placeholder" > vicinae/assets/extension-runtime.js
      echo "// Extension manager dist" > extension-manager/dist/runtime.js

      runHook postPatch
    '';

    cmakeFlags = [
      "-G Ninja"
      "-DBUILD_TESTING=OFF"
      "-DSKIP_NPM_BUILD=ON"
    ];

    # Disable network access during build
    __impureHostDeps = [];
    __noChroot = false;

    meta = with lib; {
      description = "A high-performance, native launcher for Linux — built with C++ and Qt (without npm components)";
      homepage = "https://vicinae.com";
      license = licenses.gpl3Only;
      maintainers = with maintainers; [];
      platforms = platforms.linux;
      mainProgram = "vicinae";
    };
  }
