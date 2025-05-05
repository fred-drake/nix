####################################
# Auto-generated -- do not modify! #
####################################
{
  pkgs,
  lib,
}: let
  inherit (pkgs.stdenv) isDarwin isLinux isi686 isx86_64 isAarch32 isAarch64;
  vscode-utils = pkgs.vscode-utils;
  merge = lib.attrsets.recursiveUpdate;
in
  merge
  (merge
    (merge
      (merge
        {
          "esbenp"."prettier-vscode" = vscode-utils.extensionFromVscodeMarketplace {
            name = "prettier-vscode";
            publisher = "esbenp";
            version = "11.0.0";
            sha256 = "1fcz8f4jgnf24kblf8m8nwgzd5pxs2gmrv235cpdgmqz38kf9n54";
          };
          "eamodio"."gitlens" = vscode-utils.extensionFromVscodeMarketplace {
            name = "gitlens";
            publisher = "eamodio";
            version = "2025.5.305";
            sha256 = "1kinpf2dn93fcjy16n35mvhr85cs80wysgrlqqsqyvbw0d73swqq";
          };
          "github"."copilot" = vscode-utils.extensionFromVscodeMarketplace {
            name = "copilot";
            publisher = "github";
            version = "1.312.0";
            sha256 = "0sflac0wyc52walfaakxq5jh6whrvyhjjxyq5x4zszp9y89qxhqa";
          };
          "pkief"."material-icon-theme" = vscode-utils.extensionFromVscodeMarketplace {
            name = "material-icon-theme";
            publisher = "pkief";
            version = "5.22.0";
            sha256 = "15m2g18q0ysr363f7jf50kxv4frbpzkflvykq757k1dljx4h5m8k";
          };
          "ms-vscode-remote"."remote-ssh" = vscode-utils.extensionFromVscodeMarketplace {
            name = "remote-ssh";
            publisher = "ms-vscode-remote";
            version = "0.120.2025050115";
            sha256 = "0p6bj1wcgax75sn1fz8kjj7vncxnvynmvh8p1bfpglrpzbl1vrsn";
          };
          "ms-dotnettools"."vscode-dotnet-runtime" = vscode-utils.extensionFromVscodeMarketplace {
            name = "vscode-dotnet-runtime";
            publisher = "ms-dotnettools";
            version = "2.3.2";
            sha256 = "0wyh977ml2ib0bpinnm47x1z7jncjw34nmsnws2zzxkds20fygqd";
          };
          "golang"."go" = vscode-utils.extensionFromVscodeMarketplace {
            name = "go";
            publisher = "golang";
            version = "0.47.2";
            sha256 = "02afv4k95906mx46xqb76mjkcs8s0yfsbd8wnbbc793plyn5fqkp";
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
            version = "0.17.2";
            sha256 = "1s0a2zgxk6qxl6lzw6klkn8xhsxk0l87vcbms2k8535kvscbwbay";
          };
          "oderwat"."indent-rainbow" = vscode-utils.extensionFromVscodeMarketplace {
            name = "indent-rainbow";
            publisher = "oderwat";
            version = "8.3.1";
            sha256 = "0iwd6y2x2nx52hd3bsav3rrhr7dnl4n79ln09picmnh1mp4rrs3l";
          };
          "vscodevim"."vim" = vscode-utils.extensionFromVscodeMarketplace {
            name = "vim";
            publisher = "vscodevim";
            version = "1.29.0";
            sha256 = "1r29gd6na3gyc38v8ynmc2c46mi38zms1p87y65v9n2rj94pqx97";
          };
          "mikestead"."dotenv" = vscode-utils.extensionFromVscodeMarketplace {
            name = "dotenv";
            publisher = "mikestead";
            version = "1.0.1";
            sha256 = "0rs57csczwx6wrs99c442qpf6vllv2fby37f3a9rhwc8sg6849vn";
          };
          "usernamehw"."errorlens" = vscode-utils.extensionFromVscodeMarketplace {
            name = "errorlens";
            publisher = "usernamehw";
            version = "3.26.0";
            sha256 = "0rmvzr5qsbq8zni9vwg4y6bh8l6s5hci974x676m57hi0pfj82d4";
          };
          "gruntfuggly"."todo-tree" = vscode-utils.extensionFromVscodeMarketplace {
            name = "todo-tree";
            publisher = "gruntfuggly";
            version = "0.0.226";
            sha256 = "0yrc9qbdk7zznd823bqs1g6n2i5xrda0f9a7349kknj9wp1mqgqn";
          };
          "wayou"."vscode-todo-highlight" = vscode-utils.extensionFromVscodeMarketplace {
            name = "vscode-todo-highlight";
            publisher = "wayou";
            version = "1.0.5";
            sha256 = "1sg4zbr1jgj9adsj3rik5flcn6cbr4k2pzxi446rfzbzvcqns189";
          };
          "mtxr"."sqltools" = vscode-utils.extensionFromVscodeMarketplace {
            name = "sqltools";
            publisher = "mtxr";
            version = "0.28.4";
            sha256 = "0bszagbm10004rx2jdhg2g33wg0f1l0kp3cs1jzkdj1r4an9w5qk";
          };
          "tamasfe"."even-better-toml" = vscode-utils.extensionFromVscodeMarketplace {
            name = "even-better-toml";
            publisher = "tamasfe";
            version = "0.21.2";
            sha256 = "0208cms054yj2l8pz9jrv3ydydmb47wr4i0sw8qywpi8yimddf11";
          };
          "be5invis"."vscode-custom-css" = vscode-utils.extensionFromVscodeMarketplace {
            name = "vscode-custom-css";
            publisher = "be5invis";
            version = "7.4.2";
            sha256 = "1k10k03al0lvj9zf5g9s8bgikq2l47ispgk5d7jnsj53dc2mkwdr";
          };
          "neikeq"."godot-csharp-vscode" = vscode-utils.extensionFromVscodeMarketplace {
            name = "godot-csharp-vscode";
            publisher = "neikeq";
            version = "0.2.1";
            sha256 = "04gm1k1kh6aa3yzrbjhby10ddqs8bmsikiii6syg78syhzxhzfxh";
          };
          "rooveterinaryinc"."roo-cline" = vscode-utils.extensionFromVscodeMarketplace {
            name = "roo-cline";
            publisher = "rooveterinaryinc";
            version = "3.15.3";
            sha256 = "18q9g2si94lhr3176r0xqipnpxiya3f5mqv8czfq2mjy1y6lb62l";
          };
          "fill-labs"."dependi" = vscode-utils.extensionFromVscodeMarketplace {
            name = "dependi";
            publisher = "fill-labs";
            version = "0.7.13";
            sha256 = "1dsd4qal7wmhhbzv5jmcrf8igm20dnr256s2gp1m5myhj08qlzay";
          };
          "fnando"."linter" = vscode-utils.extensionFromVscodeMarketplace {
            name = "linter";
            publisher = "fnando";
            version = "0.0.19";
            sha256 = "13bllbxd7sy4qlclh37qvvnjp1v13al11nskcf2a8pmnmj455v4g";
          };
          "csharpier"."csharpier-vscode" = vscode-utils.extensionFromVscodeMarketplace {
            name = "csharpier-vscode";
            publisher = "csharpier";
            version = "2.0.6";
            sha256 = "14a8kyx68v1apdx9f3i9kdf1yl5a1065j4vbnrvbx71s2c3bwsii";
          };
          "jnoortheen"."nix-ide" = vscode-utils.extensionFromVscodeMarketplace {
            name = "nix-ide";
            publisher = "jnoortheen";
            version = "0.4.16";
            sha256 = "0mhc58lzdn153yskqi6crvzx6pgi1d72mdhmnpc4qkbf1wx47l9i";
          };
          "mkhl"."direnv" = vscode-utils.extensionFromVscodeMarketplace {
            name = "direnv";
            publisher = "mkhl";
            version = "0.17.0";
            sha256 = "1n2qdd1rspy6ar03yw7g7zy3yjg9j1xb5xa4v2q12b0y6dymrhgn";
          };
          "gaborv"."flatbuffers" = vscode-utils.extensionFromVscodeMarketplace {
            name = "flatbuffers";
            publisher = "gaborv";
            version = "0.1.0";
            sha256 = "1jqa5824cv79w3xrln60k5i0s1l4l6qjvi9jkswy1rdd53b2csyx";
          };
          "skellock"."just" = vscode-utils.extensionFromVscodeMarketplace {
            name = "just";
            publisher = "skellock";
            version = "2.0.0";
            sha256 = "1ph869zl757a11f8iq643f79h8gry7650a9i03mlxyxlqmspzshl";
          };
          "signageos"."signageos-vscode-sops" = vscode-utils.extensionFromVscodeMarketplace {
            name = "signageos-vscode-sops";
            publisher = "signageos";
            version = "0.9.2";
            sha256 = "1fsdfm7wd3vrf907lvbb8b2sy03f6balz63qj55slx1gqgr46lda";
          };
          "bluebrown"."yamlfmt" = vscode-utils.extensionFromVscodeMarketplace {
            name = "yamlfmt";
            publisher = "bluebrown";
            version = "0.1.6";
            sha256 = "11vzk60zikjgylvkszzxahmdjs1zsgli3i30fz4w67f70akcirkb";
          };
          "mobalic"."jetbrains-dark-theme" = vscode-utils.extensionFromVscodeMarketplace {
            name = "jetbrains-dark-theme";
            publisher = "mobalic";
            version = "3.1.0";
            sha256 = "1nyxasrnv1rhyk9dg92xldkmi8a1bqlkn53b6ygwgqnpxxpz7fqi";
          };
          "kamadorueda"."alejandra" = vscode-utils.extensionFromVscodeMarketplace {
            name = "alejandra";
            publisher = "kamadorueda";
            version = "1.0.0";
            sha256 = "1ncjzhrc27c3cwl2cblfjvfg23hdajasx8zkbnwx5wk6m2649s88";
          };
          "arr"."marksman" = vscode-utils.extensionFromVscodeMarketplace {
            name = "marksman";
            publisher = "arr";
            version = "0.3.4";
            sha256 = "1pvapvydbrlllhihy7bkgvz38851381fmcvwc3z2m3w6dpywaijm";
          };
          "rodrigocfd"."format-comment" = vscode-utils.extensionFromVscodeMarketplace {
            name = "format-comment";
            publisher = "rodrigocfd";
            version = "0.0.8";
            sha256 = "0kn56q9c94p74caaqhak67g9mwykbq34ksxbkv1jwnm2p3rvxgj6";
          };
          "gofenix"."go-lines" = vscode-utils.extensionFromVscodeMarketplace {
            name = "go-lines";
            publisher = "gofenix";
            version = "0.0.10";
            sha256 = "1w9zhw1y97ij1rrrfg84nw5wjj5ikbihhg2wwba80rh7fv2rq5xy";
          };
        }
        (lib.attrsets.optionalAttrs (isLinux && (isi686 || isx86_64)) {
          "ms-python"."python" = vscode-utils.extensionFromVscodeMarketplace {
            name = "python";
            publisher = "ms-python";
            version = "2025.5.2025042501";
            sha256 = "1wralawbzk2x2g02jk1y0j07davgmpbvnlxwqjhm7qw7jlwv8mbm";
            arch = "linux-x64";
          };
          "ms-dotnettools"."csharp" = vscode-utils.extensionFromVscodeMarketplace {
            name = "csharp";
            publisher = "ms-dotnettools";
            version = "2.74.24";
            sha256 = "1r37x9wdz344mh7irxl8a2p0zfa3aw1v89db68iwcgjf77994876";
            arch = "linux-x64";
          };
          "ms-dotnettools"."csdevkit" = vscode-utils.extensionFromVscodeMarketplace {
            name = "csdevkit";
            publisher = "ms-dotnettools";
            version = "1.19.45";
            sha256 = "0xb8j0wi1ink6avr3sf2pi70d3l57znakxm74yd0dixd6hb7rchj";
            arch = "linux-x64";
          };
          "rust-lang"."rust-analyzer" = vscode-utils.extensionFromVscodeMarketplace {
            name = "rust-analyzer";
            publisher = "rust-lang";
            version = "0.4.2446";
            sha256 = "09vp06icica7i189sskvnpjl6dlr36wsvrgisbf03zv0705s4dbx";
            arch = "linux-x64";
          };
        }))
      (lib.attrsets.optionalAttrs (isLinux && (isAarch32 || isAarch64)) {
        "ms-python"."python" = vscode-utils.extensionFromVscodeMarketplace {
          name = "python";
          publisher = "ms-python";
          version = "2025.5.2025042501";
          sha256 = "0byvq5pp6x00l5d3lfcgpd543m6za6z3i5f6rrdc21xidvvrd0wr";
          arch = "linux-arm64";
        };
        "ms-dotnettools"."csharp" = vscode-utils.extensionFromVscodeMarketplace {
          name = "csharp";
          publisher = "ms-dotnettools";
          version = "2.74.24";
          sha256 = "17qdbqbk447vvd635h80lf8798wv216p4zxf4akanqhr60rymvrs";
          arch = "linux-arm64";
        };
        "ms-dotnettools"."csdevkit" = vscode-utils.extensionFromVscodeMarketplace {
          name = "csdevkit";
          publisher = "ms-dotnettools";
          version = "1.19.45";
          sha256 = "1hr0zbxg6z82ss7wpjmwd6lhgnp3sr2nbg5f2wxgf53sangijw8n";
          arch = "linux-arm64";
        };
        "rust-lang"."rust-analyzer" = vscode-utils.extensionFromVscodeMarketplace {
          name = "rust-analyzer";
          publisher = "rust-lang";
          version = "0.4.2446";
          sha256 = "1jwayqhky5rgbx750n6wwyl36r9npx6f74pbbzrcyyzgnz6cn8ac";
          arch = "linux-arm64";
        };
      }))
    (lib.attrsets.optionalAttrs (isDarwin && (isi686 || isx86_64)) {
      "ms-python"."python" = vscode-utils.extensionFromVscodeMarketplace {
        name = "python";
        publisher = "ms-python";
        version = "2025.5.2025042501";
        sha256 = "1i0y56lykfq7f9mq3w1x46sbhcfsj9pbl9wjsmi2kxgvm1g669si";
        arch = "darwin-x64";
      };
      "ms-dotnettools"."csharp" = vscode-utils.extensionFromVscodeMarketplace {
        name = "csharp";
        publisher = "ms-dotnettools";
        version = "2.74.24";
        sha256 = "1amhsh6yc6i5w6m2hsjfm59az00jv34aq01334j1z0ikhakyhh6v";
        arch = "darwin-x64";
      };
      "ms-dotnettools"."csdevkit" = vscode-utils.extensionFromVscodeMarketplace {
        name = "csdevkit";
        publisher = "ms-dotnettools";
        version = "1.19.45";
        sha256 = "0glhvjv6rw74szjl42cqa15hpy7km31khhha7n7pc3mjd7ppz5z1";
        arch = "darwin-x64";
      };
      "rust-lang"."rust-analyzer" = vscode-utils.extensionFromVscodeMarketplace {
        name = "rust-analyzer";
        publisher = "rust-lang";
        version = "0.4.2446";
        sha256 = "15jbabkw8n3rq9y6glzrcfgg1rm7d1dlb06b9klfnxapb49mv6jw";
        arch = "darwin-x64";
      };
    }))
  (lib.attrsets.optionalAttrs (isDarwin && (isAarch32 || isAarch64)) {
    "ms-python"."python" = vscode-utils.extensionFromVscodeMarketplace {
      name = "python";
      publisher = "ms-python";
      version = "2025.5.2025042501";
      sha256 = "1xnnzbcwrr8wzllv074apmrii61gq4bipw0hzjbwwyv3wybh1sjb";
      arch = "darwin-arm64";
    };
    "ms-dotnettools"."csharp" = vscode-utils.extensionFromVscodeMarketplace {
      name = "csharp";
      publisher = "ms-dotnettools";
      version = "2.74.24";
      sha256 = "0j40sdpkld1zadw6bxghbrqh6lzqglk18zsajbmac676gcrpgfhj";
      arch = "darwin-arm64";
    };
    "ms-dotnettools"."csdevkit" = vscode-utils.extensionFromVscodeMarketplace {
      name = "csdevkit";
      publisher = "ms-dotnettools";
      version = "1.19.45";
      sha256 = "0bg6ma6s7wp8czzkbcylj0z80wy574hmg08rkqhx9xifzddn2131";
      arch = "darwin-arm64";
    };
    "rust-lang"."rust-analyzer" = vscode-utils.extensionFromVscodeMarketplace {
      name = "rust-analyzer";
      publisher = "rust-lang";
      version = "0.4.2446";
      sha256 = "16cxjkbrmk6slpwfdkij6lwkzr9h99c32c093yll0l0idafzcdfy";
      arch = "darwin-arm64";
    };
  })
