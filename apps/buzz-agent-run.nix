{
  agentCommand,
  agentPath,
  binutils,
  codexPath,
  coreutils,
  file,
  lib,
  pkgsStatic,
  serviceHome ? "/home/buzz1",
  static ? false,
  stdenv,
}: let
  builder =
    if static
    then pkgsStatic.stdenv
    else stdenv;
in
  builder.mkDerivation {
    pname = "buzz-agent-run";
    version = "1.0.0";
    dontUnpack = true;
    strictDeps = true;
    nativeBuildInputs = [file] ++ lib.optionals static [binutils];

    buildPhase = ''
      runHook preBuild
      cp ${./buzz-agent-run.c} buzz-agent-run.c
      cat >config.h <<EOF
      #define AGENT_COMMAND "${agentCommand}"
      #define CODEX_PATH "${codexPath}"
      #define AGENT_PATH "${agentPath}"
      #define SERVICE_HOME ${builtins.toJSON serviceHome}
      #define CONTRACT_PATH "$out/share/buzz-agent-run/publication-contract.txt"
      EOF
      $CC -std=c11 -D_POSIX_C_SOURCE=200809L -O2 -Wall -Wextra -Werror \
        -o buzz-agent-run buzz-agent-run.c
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      install -Dm755 buzz-agent-run "$out/bin/buzz-agent-run"
      install -Dm444 ${./buzz-publication-contract.txt} \
        "$out/share/buzz-agent-run/publication-contract.txt"
      runHook postInstall
    '';

    doInstallCheck = true;
    installCheckPhase = ''
      "$out/bin/buzz-agent-run" ${coreutils}/bin/true
      ${coreutils}/bin/env -i \
        HOME=/untrusted CODEX_HOME=/untrusted CODEX_CONFIG=/untrusted \
        XDG_CONFIG_HOME=/untrusted XDG_DATA_HOME=/untrusted \
        XDG_STATE_HOME=/untrusted XDG_CACHE_HOME=/untrusted \
        "$out/bin/buzz-agent-run" ${coreutils}/bin/env >effective-environment
      grep -Fx 'HOME=${serviceHome}' effective-environment
      grep -Fx 'CODEX_HOME=${serviceHome}/.codex' effective-environment
      ! grep -Eq '^(CODEX_CONFIG|XDG_CONFIG_HOME|XDG_DATA_HOME|XDG_STATE_HOME|XDG_CACHE_HOME)=' \
        effective-environment

      set -- -i
      index=0
      while test "$index" -lt 222; do
        set -- "$@" "PERSISTED_$index="
        index=$((index + 1))
      done
      set -- "$@" BUZZ_ACP_SUBSCRIBE=mentions BUZZ_ACP_HEARTBEAT_INTERVAL=0
      index=0
      while test "$index" -lt 25; do
        set -- "$@" "SYSTEMD_$index="
        index=$((index + 1))
      done
      ${coreutils}/bin/env "$@" HOME=/untrusted CODEX_HOME=/untrusted \
        "$out/bin/buzz-agent-run" ${coreutils}/bin/true
      set -- "$@" SYSTEMD_25=
      if ${coreutils}/bin/env "$@" HOME=/untrusted CODEX_HOME=/untrusted \
        "$out/bin/buzz-agent-run" ${coreutils}/bin/true \
        >entry-limit.out 2>entry-limit.err; then
        echo "buzz-agent-run accepted oversized effective environment" >&2
        exit 1
      fi
      test ! -s entry-limit.out
      grep -Fx 'buzz-agent-run: environment too large' entry-limit.err

      at_limit=$(${coreutils}/bin/head -c 65536 /dev/zero \
        | ${coreutils}/bin/tr '\0' x \
        | ${coreutils}/bin/base64 --wrap=0)
      BUZZ_MANAGED_TEAM_INSTRUCTIONS_B64="$at_limit" \
        "$out/bin/buzz-agent-run" ${coreutils}/bin/true
      above_limit=$(${coreutils}/bin/head -c 65537 /dev/zero \
        | ${coreutils}/bin/tr '\0' x \
        | ${coreutils}/bin/base64 --wrap=0)
      if BUZZ_MANAGED_TEAM_INSTRUCTIONS_B64="$above_limit" \
        "$out/bin/buzz-agent-run" ${coreutils}/bin/true \
        >above-limit.out 2>above-limit.err; then
        echo "buzz-agent-run accepted oversized team instructions" >&2
        exit 1
      fi
      test ! -s above-limit.out
      grep -Fx 'buzz-agent-run: team instructions too large' above-limit.err
      ${lib.optionalString static ''
        file "$out/bin/buzz-agent-run" | grep -Eq 'static(-pie|ally) linked'
        ! readelf -l "$out/bin/buzz-agent-run" | grep -q 'interpreter'
      ''}
    '';

    meta.mainProgram = "buzz-agent-run";
  }
