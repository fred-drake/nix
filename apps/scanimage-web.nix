{
  pkgs,
  buildNpmPackage,
  lib,
  nodejs,
}: let
  repos-src = import ../apps/fetcher/repos-src.nix {inherit pkgs;};
in
  buildNpmPackage {
    pname = "scanimage-web";
    version = "unstable";

    src = repos-src.scanimage-web-src;

    npmDepsHash = "sha256-7LA7pEeyro57/Vg7B4kLyskcF3zN1XGz3Yg63EHRBoM=";

    # NextJS needs to build the production bundle
    npmBuild = "npm run build";

    # Install the built application
    installPhase = ''
      runHook preInstall

      # Create the output directory structure
      mkdir -p $out/lib/scanimage-web
      mkdir -p $out/bin

      # Copy the entire built application
      cp -r .next $out/lib/scanimage-web/
      cp -r public $out/lib/scanimage-web/ || true
      cp -r node_modules $out/lib/scanimage-web/
      cp package.json $out/lib/scanimage-web/
      cp next.config.ts $out/lib/scanimage-web/ || cp next.config.js $out/lib/scanimage-web/ || true

      # Create a startup script
      cat > $out/bin/scanimage-web << EOF
      #!${pkgs.bash}/bin/bash
      cd $out/lib/scanimage-web
      # Unbuffer Node.js output for systemd logging
      exec ${nodejs}/bin/node --trace-warnings node_modules/.bin/next start -H "\''${HOST:-127.0.0.1}" -p "\''${PORT:-3000}" "\$@"
      EOF

      chmod +x $out/bin/scanimage-web

      runHook postInstall
    '';

    meta = with lib; {
      description = "Web-based scanner interface built with Next.js";
      homepage = "https://github.com/fred-drake/scanimage-web";
      license = licenses.mit;
      mainProgram = "scanimage-web";
      platforms = platforms.linux;
    };
  }
