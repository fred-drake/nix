####################################
# Auto-generated -- do not modify! #
####################################
{pkgs, ...}: {
  claude-plugins-official-src = builtins.fetchTarball {
    url = "https://github.com/anthropics/claude-plugins-official/archive/e3e378cbbb205673a5d7254ded32679cafa6179d.tar.gz";
    sha256 = "13imy5lynsa97ziv6pmsfz38gwfpl77vhridms5yi2b7z8wf72yk";
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
    rev = "709b18186985c2ae7b6b5eb9cded2c635aa74be5";
    hash = "sha256-EQr2k7d0fDZgXG4JQUswJFwE+UHJfe6RCY9CYHAWcA8=";
  };
  superpowers-src = pkgs.fetchFromGitHub {
    owner = "obra";
    repo = "superpowers";
    rev = "d884ae04edebef577e82ff7c4e143debd0bbec99";
    hash = "sha256-kHdQ9e44doBk2yYW88tMSCqVG8ycYcvJSZlrIziXhpA=";
  };
  cmux-src = pkgs.fetchFromGitHub {
    owner = "manaflow-ai";
    repo = "cmux";
    rev = "d19f59aa2997549b38f107b2131685ba80597fc6";
    hash = "sha256-KOczBvNKLq3V5S9JbrqjHYftzsZeJJcoSrKsZvkdaW0=";
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
    rev = "1a9eae7ac182bf94e9f72e572384b3b2385fe2db";
    hash = "sha256-dFF3SuOlx4+u9+e2cloYmvtwrIeOWGUWc3ZOlGd14A4=";
  };
  anthropic-skills-src = pkgs.fetchFromGitHub {
    owner = "anthropics";
    repo = "skills";
    rev = "1f630fdf9259cec4a14913127dfd7c3b69ef72eb";
    hash = "sha256-XPXKd05IEiyTPlAPkowfJUal1UfRlxEHo+GgszgHQCI=";
  };
  vercel-agent-skills-src = pkgs.fetchFromGitHub {
    owner = "vercel-labs";
    repo = "agent-skills";
    rev = "4559f18a20c1691c744b4395194290db6a0df5e9";
    hash = "sha256-SxkDanZXjdGAzLMPV3kk6gEtlHx7vsGFrTiS97WX+gg=";
  };
  trailofbits-skills-src = pkgs.fetchFromGitHub {
    owner = "trailofbits";
    repo = "skills";
    rev = "cfe5d7b1619e47fb5b38b7e2561dad7e5f1e89af";
    hash = "sha256-hOA3v+QFGJLkw7OVPSzjtCZXS7zU792AfqGNdSNgsgA=";
  };
  remotion-skills-src = pkgs.fetchFromGitHub {
    owner = "remotion-dev";
    repo = "skills";
    rev = "0dd76fafa3fd337b7bc6b5cd95b7db0179828a3d";
    hash = "sha256-ZVAIy/aZS5a72zwjH8qBeqPdFWOxyBq7MPr0fwjvF1o=";
  };
  marketing-skills-src = pkgs.fetchFromGitHub {
    owner = "coreyhaines31";
    repo = "marketingskills";
    rev = "c21a984a56da10fb6085e6334f6f60929220a4da";
    hash = "sha256-pUC8Z0mu7LuTBqfTYGfnp8/n8VR7glXJDK2E7vZGP8A=";
  };
  herdr-src = pkgs.fetchFromGitHub {
    owner = "ogulcancelik";
    repo = "herdr";
    rev = "2a20e90a026936d0d5b96823d74e2e4fe13a166f";
    hash = "sha256-SlmAeR1bZE3+kwpVZXK4iFEDOaaaDZZPfYOeCsdeIxU=";
  };
}
