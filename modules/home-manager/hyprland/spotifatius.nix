{pkgs ? import <nixpkgs> {}}: let
  repos-src = import ../../../apps/fetcher/repos-src.nix {inherit pkgs;};
in
  (pkgs.rustPlatform.buildRustPackage {
    pname = "spotifatius";
    version = "0.1.0";

    src = repos-src.spotifatius-src;

    cargoHash = "sha256-9yX9zSKeN7j8J4Ux5jre+HEd3yx/Nu6sdyJQbdzDHFI=";

    nativeBuildInputs = with pkgs; [
      pkg-config
      cmake
    ];

    buildInputs = with pkgs; [
      openssl
    ];
  }).overrideAttrs (_oldAttrs: {
    postConfigure = ''
      # Patch the vendored prost-build CMakeLists.txt after cargo vendor is set up
      find .. -path "*/prost-build-*/third-party/protobuf/cmake/CMakeLists.txt" -exec sed -i 's/cmake_minimum_required(VERSION 2\.8\.12)/cmake_minimum_required(VERSION 3.5)/' {} \;
    '';
  })
