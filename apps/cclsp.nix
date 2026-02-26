{
  stdenv,
  fetchurl,
  nodejs,
  makeWrapper,
  npm-packages,
}:
stdenv.mkDerivation rec {
  pname = "cclsp";
  inherit (npm-packages.cclsp) version;

  src = fetchurl {
    inherit (npm-packages.cclsp) url;
    hash = npm-packages.cclsp.url-hash;
  };

  nativeBuildInputs = [makeWrapper];

  dontBuild = true;

  unpackPhase = ''
    mkdir -p source
    tar -xzf $src -C source
  '';

  installPhase = ''
    mkdir -p $out/lib/node_modules/cclsp
    mkdir -p $out/bin

    cp -r source/package/* $out/lib/node_modules/cclsp/

    makeWrapper ${nodejs}/bin/node $out/bin/cclsp \
      --add-flags "$out/lib/node_modules/cclsp/dist/index.js"
  '';

  meta = {
    description = "MCP server bridging LLM coding agents with LSP servers";
    homepage = "https://github.com/ktnyt/cclsp";
    mainProgram = "cclsp";
  };
}
