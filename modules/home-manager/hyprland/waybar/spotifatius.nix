{pkgs ? import <nixpkgs> {}}:
pkgs.rustPlatform.buildRustPackage rec {
  pname = "spotifatius";
  version = "0.1.0";

  src = pkgs.fetchFromGitHub {
    owner = "AndreasBackx";
    repo = "spotifatius";
    rev = "6eceb8e992ba2d1d89d370961a18a1fdeae729fa";
    sha256 = "sha256-esQiz9nduOm7nAUIq/Y5dMMxpKo2m19lEbZl6iRcxpo=";
  };

  cargoHash = "sha256-9yX9zSKeN7j8J4Ux5jre+HEd3yx/Nu6sdyJQbdzDHFI=";

  nativeBuildInputs = with pkgs; [
    pkg-config
    cmake
  ];

  buildInputs = with pkgs; [
    openssl
  ];
}
