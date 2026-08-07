####################################
# Auto-generated -- do not modify! #
####################################
{pkgs, ...}: {
  claude-plugins-official-src = builtins.fetchTarball {
    url = "https://github.com/anthropics/claude-plugins-official/archive/82a73a367be4991ff22e2b43317b3956933c9f9a.tar.gz";
    sha256 = "0j7iz2723q1bn5nh8d2kbld1kk5mcx2zlk8gg2icdsb4qsi6fsqd";
  };
  cc-marketplace-src = pkgs.fetchFromGitHub {
    owner = "samber";
    repo = "cc";
    rev = "cf33ec47ef0b3294483222793f686e688d865015";
    hash = "sha256-xIvK8b2CHxlT5IUsW9+AdF3h9dtZid/hHSFAcJwRzDI=";
  };
  cc-skills-golang-src = pkgs.fetchFromGitHub {
    owner = "samber";
    repo = "cc-skills-golang";
    rev = "3a823627c6fac359a74b82bd9b5fc8f126a0e950";
    hash = "sha256-AHSWexd3cyO2GOUc99m21IZpUBSmh2ls5B7xAEZKp2E=";
  };
  superpowers-src = pkgs.fetchFromGitHub {
    owner = "obra";
    repo = "superpowers";
    rev = "44c9b2d6e889982ac18c27d05a19fefe335194e1";
    hash = "sha256-fnl+HbPL2qD5Zgz8a1NctjFJSqu6UsyHJAhQMLQNXXc=";
  };
  cmux-src = pkgs.fetchFromGitHub {
    owner = "manaflow-ai";
    repo = "cmux";
    rev = "6089fa04d3effd27e43c5c6104a4eada62fe859f";
    hash = "sha256-AkwueVaYuW5qLYOMMNTWBz3lgWX+pbmRxX8FiLWXxXY=";
  };
  karpathy-skills-src = pkgs.fetchFromGitHub {
    owner = "multica-ai";
    repo = "andrej-karpathy-skills";
    rev = "2c606141936f1eeef17fa3043a72095b4765b9c2";
    hash = "sha256-4z/wRdYH7UXRzF8RJU0sw8xbpx0BW/7CBv5sVEC2knY=";
  };
  agent-rules-skill-src = pkgs.fetchFromGitHub {
    owner = "netresearch";
    repo = "agent-rules-skill";
    rev = "8089e92bb4803bb95fc51f61e24be9fd41e861c4";
    hash = "sha256-9IDu8dK7q5KxCkpGme2+TypN9+Y9n7t6L522lQ7M9vQ=";
  };
  anthropic-skills-src = pkgs.fetchFromGitHub {
    owner = "anthropics";
    repo = "skills";
    rev = "f17010c9bb483898c1d9c9f42dde2b3a98889434";
    hash = "sha256-vTqAu8eRY+8ymbf065SWHHjNX/li3SOR+sWq1npteTM=";
  };
  vercel-agent-skills-src = pkgs.fetchFromGitHub {
    owner = "vercel-labs";
    repo = "agent-skills";
    rev = "7c180d9044c9ae2b442b567aad4e42a28dd5ed62";
    hash = "sha256-5i/QesRS+SQ4gDFCyj22uthen90GZsnhT7dQvetRbpA=";
  };
  trailofbits-skills-src = pkgs.fetchFromGitHub {
    owner = "trailofbits";
    repo = "skills";
    rev = "7b9bd5f950f89a9ba71b249b9801c1a95be3928e";
    hash = "sha256-gxzcnfXgjq4TYKdYzEH5g5+pmFpKBwqCg+6fdnq5YBg=";
  };
  remotion-skills-src = pkgs.fetchFromGitHub {
    owner = "remotion-dev";
    repo = "skills";
    rev = "eed702478ce34eff4eb77230b748375332c536ae";
    hash = "sha256-j+Tpj6KLGy8xVwR9gNBieVDlYDCbdDVwIuf2sKJeD5M=";
  };
  marketing-skills-src = pkgs.fetchFromGitHub {
    owner = "coreyhaines31";
    repo = "marketingskills";
    rev = "7868cb9251fad80a73d26e488a5ad5f6c4a9f335";
    hash = "sha256-NfHll8eEj5QZt0ubURhJdIhms1RuMAoAKHXOsss3U4s=";
  };
  herdr-src = pkgs.fetchFromGitHub {
    owner = "ogulcancelik";
    repo = "herdr";
    rev = "50ddc06f00ec69ede35fd5488a260dec2b74e98a";
    hash = "sha256-PhCEh2+3PI+dVeUinkrD+1aOGRlroJalXcbmMS0Hheo=";
  };
}
