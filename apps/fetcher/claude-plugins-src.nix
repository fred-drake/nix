####################################
# Auto-generated -- do not modify! #
####################################
{pkgs, ...}: {
  "claude-plugins-official-src" = builtins.fetchTarball {
    url = "https://github.com/anthropics/claude-plugins-official/archive/b819188d2eea14e0400556ca29dbd1179a7c595b.tar.gz";
    sha256 = "01z5ngcb4lglclmclm40dszw31g7h9wdqwbd9n3yxm9v0q3cm22v";
  };
  "cc-marketplace-src" = pkgs.fetchFromGitHub {
    owner = "samber";
    repo = "cc";
    rev = "cf33ec47ef0b3294483222793f686e688d865015";
    hash = "sha256-xIvK8b2CHxlT5IUsW9+AdF3h9dtZid/hHSFAcJwRzDI=";
  };
  "cc-skills-golang-src" = pkgs.fetchFromGitHub {
    owner = "samber";
    repo = "cc-skills-golang";
    rev = "a18860b303ef1d3d928f9670631e03210b8698bf";
    hash = "sha256-n3ei28ZxXhhXUO6vZ+Dm0leqCGvjUdpzvMWw3sc/5N4=";
  };
  "superpowers-src" = pkgs.fetchFromGitHub {
    owner = "obra";
    repo = "superpowers";
    rev = "b36e0829c6d0140e93cfef2ca599b1b07d4a7797";
    hash = "sha256-EsGNO0dULWf5Bx6bGrCv2kI2Z8aKH0kRvGiuN23wChQ=";
  };
  "karpathy-skills-src" = pkgs.fetchFromGitHub {
    owner = "multica-ai";
    repo = "andrej-karpathy-skills";
    rev = "2c606141936f1eeef17fa3043a72095b4765b9c2";
    hash = "sha256-4z/wRdYH7UXRzF8RJU0sw8xbpx0BW/7CBv5sVEC2knY=";
  };
  "agent-rules-skill-src" = pkgs.fetchFromGitHub {
    owner = "netresearch";
    repo = "agent-rules-skill";
    rev = "8ff214dd7fb8f32efc965dd52c71502264ae33b7";
    hash = "sha256-CeNP3qY+vzyiK8Z68P/yNgJyB6NH5ciwlY90SxkoVDA=";
  };
  "anthropic-skills-src" = pkgs.fetchFromGitHub {
    owner = "anthropics";
    repo = "skills";
    rev = "3b3fad96af16a10759d930941b4520ba0c40edae";
    hash = "sha256-nVid8vENmLDh7ffDqh+bJbEWtXcVltA0qa2rItmniZM=";
  };
  "vercel-agent-skills-src" = pkgs.fetchFromGitHub {
    owner = "vercel-labs";
    repo = "agent-skills";
    rev = "dd089a8c752c966dee8bf0f27cb625ba193ffd9e";
    hash = "sha256-fXbWS0+jtRYXdVn1KdqBdU0wEirrg5t/3IxdqPaAs8M=";
  };
  "trailofbits-skills-src" = pkgs.fetchFromGitHub {
    owner = "trailofbits";
    repo = "skills";
    rev = "3deb39e7b346e0ac213f77db6f04fc6ee2275f33";
    hash = "sha256-yKbpNTYl7meziBXS7JuI9/KZsPG3Ci/g4qxuIC/XYCA=";
  };
  "remotion-skills-src" = pkgs.fetchFromGitHub {
    owner = "remotion-dev";
    repo = "skills";
    rev = "7c5c10caa5294d01b168a08c9648b4deef717274";
    hash = "sha256-TSj8qld3UF0i+ytup3hm5XL5M2P7qXaU8A4OejXSDlc=";
  };
  "marketing-skills-src" = pkgs.fetchFromGitHub {
    owner = "coreyhaines31";
    repo = "marketingskills";
    rev = "becd60ee9df07f7d595c26e092253ba49f7a9ffc";
    hash = "sha256-Wsuj/B5h+TQ5F/jk27mxiSi9+SbiORMfoB2jtX791GM=";
  };
  "herdr-src" = pkgs.fetchFromGitHub {
    owner = "ogulcancelik";
    repo = "herdr";
    rev = "d79fd746a96ddb5642939c9727baefce642d78e6";
    hash = "sha256-ljbHQ3i8lkkC4sK3kZ+qOejCANVW7PpQmV6eWTxdMM8=";
  };
}
