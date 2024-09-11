{ pkgs, lib }:

let
  inherit (pkgs.stdenv) isDarwin isLinux isi686 isx86_64 isAarch32 isAarch64;
  vscode-utils = pkgs.vscode-utils;
  merge = lib.attrsets.recursiveUpdate;
in
merge
  (merge
    (merge
      (merge
      {
        "eamodio"."gitlens" = vscode-utils.extensionFromVscodeMarketplace {
          name = "gitlens";
          publisher = "eamodio";
          version = "2024.9.1005";
          sha256 = "06vcdbc19izbpjqx8xzjy9n5iaws3x3zv6hpigg787rf6h8jg67k";
        };
        "pkief"."material-icon-theme" = vscode-utils.extensionFromVscodeMarketplace {
          name = "material-icon-theme";
          publisher = "pkief";
          version = "5.10.0";
          sha256 = "0w8k8nm4y8n3hh8m1snxxaqqaa0y931kla9dbnzlhdj9g17ri6zc";
        };
        "ms-vscode-remote"."remote-ssh" = vscode-utils.extensionFromVscodeMarketplace {
          name = "remote-ssh";
          publisher = "ms-vscode-remote";
          version = "0.115.2024091015";
          sha256 = "02p5bd7l9l2nlhyc9v0dnixckfldsizw3ycb0d6w77s2ypxkjs8r";
        };
        "donjayamanne"."githistory" = vscode-utils.extensionFromVscodeMarketplace {
          name = "githistory";
          publisher = "donjayamanne";
          version = "0.6.20";
          sha256 = "0x9q7sh5l1frpvfss32ypxk03d73v9npnqxif4fjwcfwvx5mhiww";
        };
        "editorconfig"."editorconfig" = vscode-utils.extensionFromVscodeMarketplace {
          name = "editorconfig";
          publisher = "editorconfig";
          version = "0.16.4";
          sha256 = "0fa4h9hk1xq6j3zfxvf483sbb4bd17fjl5cdm3rll7z9kaigdqwg";
        };
        "oderwat"."indent-rainbow" = vscode-utils.extensionFromVscodeMarketplace {
          name = "indent-rainbow";
          publisher = "oderwat";
          version = "8.3.1";
          sha256 = "0iwd6y2x2nx52hd3bsav3rrhr7dnl4n79ln09picmnh1mp4rrs3l";
        };
        "mikestead"."dotenv" = vscode-utils.extensionFromVscodeMarketplace {
          name = "dotenv";
          publisher = "mikestead";
          version = "1.0.1";
          sha256 = "0rs57csczwx6wrs99c442qpf6vllv2fby37f3a9rhwc8sg6849vn";
        };
        "wayou"."vscode-todo-highlight" = vscode-utils.extensionFromVscodeMarketplace {
          name = "vscode-todo-highlight";
          publisher = "wayou";
          version = "1.0.5";
          sha256 = "1sg4zbr1jgj9adsj3rik5flcn6cbr4k2pzxi446rfzbzvcqns189";
        };
        "tamasfe"."even-better-toml" = vscode-utils.extensionFromVscodeMarketplace {
          name = "even-better-toml";
          publisher = "tamasfe";
          version = "0.19.2";
          sha256 = "0q9z98i446cc8bw1h1mvrddn3dnpnm2gwmzwv2s3fxdni2ggma14";
        };
        "be5invis"."vscode-custom-css" = vscode-utils.extensionFromVscodeMarketplace {
          name = "vscode-custom-css";
          publisher = "be5invis";
          version = "7.2.2";
          sha256 = "1ld8l7xivlgw01s3qmysph63cilpb5i12rp4dj404aq0fj8nmdgw";
        };
        "bbenoist"."nix" = vscode-utils.extensionFromVscodeMarketplace {
          name = "nix";
          publisher = "bbenoist";
          version = "1.0.1";
          sha256 = "0zd0n9f5z1f0ckzfjr38xw2zzmcxg1gjrava7yahg5cvdcw6l35b";
        };
        "mkhl"."direnv" = vscode-utils.extensionFromVscodeMarketplace {
          name = "direnv";
          publisher = "mkhl";
          version = "0.17.0";
          sha256 = "1n2qdd1rspy6ar03yw7g7zy3yjg9j1xb5xa4v2q12b0y6dymrhgn";
        };
        "saoudrizwan"."claude-dev" = vscode-utils.extensionFromVscodeMarketplace {
          name = "claude-dev";
          publisher = "saoudrizwan";
          version = "1.6.3";
          sha256 = "1br2874pz62hfwvkdczs7alm68bf6605m7bnp750qvkw183c30d9";
        };
        "signageos"."signageos-vscode-sops" = vscode-utils.extensionFromVscodeMarketplace {
          name = "signageos-vscode-sops";
          publisher = "signageos";
          version = "0.9.1";
          sha256 = "1wr9magp4961pady696wiv20zpdw0hz97anbqixyzzgrsbxajlbg";
        };
        "mobalic"."jetbrains-dark-theme" = vscode-utils.extensionFromVscodeMarketplace {
          name = "jetbrains-dark-theme";
          publisher = "mobalic";
          version = "3.1.0";
          sha256 = "1nyxasrnv1rhyk9dg92xldkmi8a1bqlkn53b6ygwgqnpxxpz7fqi";
        };
        "rodrigocfd"."format-comment" = vscode-utils.extensionFromVscodeMarketplace {
          name = "format-comment";
          publisher = "rodrigocfd";
          version = "0.0.8";
          sha256 = "0kn56q9c94p74caaqhak67g9mwykbq34ksxbkv1jwnm2p3rvxgj6";
        };
      }
        (lib.attrsets.optionalAttrs (isLinux && (isi686 || isx86_64)) {
          "continue"."continue" = vscode-utils.extensionFromVscodeMarketplace {
            name = "continue";
            publisher = "continue";
            version = "0.9.207";
            sha256 = "10nqn19lp7slapwi235s6d99i1av2vf1s3x0mk7kwgak40byhxs4";
            arch = "linux-x64";
          };
        }))
      (lib.attrsets.optionalAttrs (isLinux && (isAarch32 || isAarch64)) {
        "continue"."continue" = vscode-utils.extensionFromVscodeMarketplace {
          name = "continue";
          publisher = "continue";
          version = "0.9.207";
          sha256 = "1xhzw42v5w89b0627n4pcmhi5ias42pbfw1yyf8m0w3lxs1lyyqk";
          arch = "linux-arm64";
        };
      }))
    (lib.attrsets.optionalAttrs (isDarwin && (isi686 || isx86_64)) {
      "continue"."continue" = vscode-utils.extensionFromVscodeMarketplace {
        name = "continue";
        publisher = "continue";
        version = "0.9.207";
        sha256 = "0k123hmy7xdhbc6h0z3zbnsjh7h4vllwqfg65m9p5bj749wmfsar";
        arch = "darwin-x64";
      };
    }))
  (lib.attrsets.optionalAttrs (isDarwin && (isAarch32 || isAarch64)) {
    "continue"."continue" = vscode-utils.extensionFromVscodeMarketplace {
      name = "continue";
      publisher = "continue";
      version = "0.9.207";
      sha256 = "0m2r7p6ihl4dvh0d6cx8qrkfa95fqm33rnw5szg2d8ajbkgi9wmk";
      arch = "darwin-arm64";
    };
  })

