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
            version = "2025.3.1005";
            sha256 = "1pjbd1b763ma2l7s2w8i2lcxml54s0hs0fpzx76rmm1ynvy17inh";
          };
          "pkief"."material-icon-theme" = vscode-utils.extensionFromVscodeMarketplace {
            name = "material-icon-theme";
            publisher = "pkief";
            version = "5.20.0";
            sha256 = "1nhmb5x773s23i2clbwqagzhz5zm0v19779kkcqpg6gwyxfcbkb7";
          };
          "ms-vscode-remote"."remote-ssh" = vscode-utils.extensionFromVscodeMarketplace {
            name = "remote-ssh";
            publisher = "ms-vscode-remote";
            version = "0.119.2025030615";
            sha256 = "1jqc97bqz1l1axnwqfin25926gdw0l9ldxclbbgnwbc5gcpy8jfc";
          };
          "ms-dotnettools"."vscode-dotnet-runtime" = vscode-utils.extensionFromVscodeMarketplace {
            name = "vscode-dotnet-runtime";
            publisher = "ms-dotnettools";
            version = "2.2.8";
            sha256 = "1k4d7idgkmf8py47hf911n22cjmaj8s6z7p9ijcr02whl68j9p6m";
          };
          "golang"."go" = vscode-utils.extensionFromVscodeMarketplace {
            name = "go";
            publisher = "golang";
            version = "0.47.1";
            sha256 = "0b82wrrn2v2vssgxgbbk0g8q7b23njzhz99dyjnj3v8ffaywz9hl";
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
            version = "0.17.1";
            sha256 = "0al61nfnq3zsir5m3mp7a2kgi2lwvdk59rj132h0888zpm5aw2xq";
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
            version = "3.24.0";
            sha256 = "00avhl46r5kv51f7pbn5jlhpr1rfx2iwmfjfdsvgyv63i93mg75g";
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
          "fnando"."linter" = vscode-utils.extensionFromVscodeMarketplace {
            name = "linter";
            publisher = "fnando";
            version = "0.0.19";
            sha256 = "13bllbxd7sy4qlclh37qvvnjp1v13al11nskcf2a8pmnmj455v4g";
          };
          "fill-labs"."dependi" = vscode-utils.extensionFromVscodeMarketplace {
            name = "dependi";
            publisher = "fill-labs";
            version = "0.7.13";
            sha256 = "1dsd4qal7wmhhbzv5jmcrf8igm20dnr256s2gp1m5myhj08qlzay";
          };
          "rooveterinaryinc"."roo-cline" = vscode-utils.extensionFromVscodeMarketplace {
            name = "roo-cline";
            publisher = "rooveterinaryinc";
            version = "3.8.4";
            sha256 = "0arx23hfz6ykwj4nj9jl1y81k25wppnjjbiz8qgxivd3rfca8rmv";
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
            version = "0.4.12";
            sha256 = "0rdq9wnqfrj8k1g5fcaam5iahzd16bdpi3sa0n2gi0rh02kg55fy";
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
          "augment"."vscode-augment" = vscode-utils.extensionFromVscodeMarketplace {
            name = "vscode-augment";
            publisher = "augment";
            version = "0.377.0";
            sha256 = "12dlsdgglsw38hkv799xyspdwb26j24hzrdcl77pknviqyrvfq8p";
          };
          "bluebrown"."yamlfmt" = vscode-utils.extensionFromVscodeMarketplace {
            name = "yamlfmt";
            publisher = "bluebrown";
            version = "0.1.4";
            sha256 = "0faff5dnaq26l6dwmrn6jmz4shphlaa174958x229jqpgcwli5cg";
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
          "ms-dotnettools"."csharp" = vscode-utils.extensionFromVscodeMarketplace {
            name = "csharp";
            publisher = "ms-dotnettools";
            version = "2.68.46";
            sha256 = "1c2w1mr93ij84w6waw1928wfqdqncrxfg6xc1sqg4xgrdn3j2sha";
            arch = "linux-x64";
          };
          "ms-dotnettools"."csdevkit" = vscode-utils.extensionFromVscodeMarketplace {
            name = "csdevkit";
            publisher = "ms-dotnettools";
            version = "1.17.48";
            sha256 = "160gd986zrfy9g7kd4mfwxh5bja545qbnmlqir6j5i45gc9ql4b2";
            arch = "linux-x64";
          };
          "rust-lang"."rust-analyzer" = vscode-utils.extensionFromVscodeMarketplace {
            name = "rust-analyzer";
            publisher = "rust-lang";
            version = "0.4.2336";
            sha256 = "1d1xiq8zzvcjpms0n1cs3g2izdwpm487qba2igms8hlpkppj01a1";
            arch = "linux-x64";
          };
          "continue"."continue" = vscode-utils.extensionFromVscodeMarketplace {
            name = "continue";
            publisher = "continue";
            version = "1.1.7";
            sha256 = "0h2h5rj7dcg0mwd5lpvp79cn1k288jn6glm67fr63ln9dpwidq8w";
            arch = "linux-x64";
          };
        }))
      (lib.attrsets.optionalAttrs (isLinux && (isAarch32 || isAarch64)) {
        "ms-dotnettools"."csharp" = vscode-utils.extensionFromVscodeMarketplace {
          name = "csharp";
          publisher = "ms-dotnettools";
          version = "2.68.46";
          sha256 = "1i9dz70b5cpr7kj6pzjmbcnvz124x1izk59l1kizfvrbpzj3m221";
          arch = "linux-arm64";
        };
        "ms-dotnettools"."csdevkit" = vscode-utils.extensionFromVscodeMarketplace {
          name = "csdevkit";
          publisher = "ms-dotnettools";
          version = "1.17.48";
          sha256 = "0apxvqk9ci7fqdpq6fxm0y8yvv8623gpkbg0g9qzpzqimdm8i8rx";
          arch = "linux-arm64";
        };
        "rust-lang"."rust-analyzer" = vscode-utils.extensionFromVscodeMarketplace {
          name = "rust-analyzer";
          publisher = "rust-lang";
          version = "0.4.2336";
          sha256 = "0smksq9k9ma80gqz91gxiw5shb7g5pidmi2mj0zisdkq880gqc31";
          arch = "linux-arm64";
        };
        "continue"."continue" = vscode-utils.extensionFromVscodeMarketplace {
          name = "continue";
          publisher = "continue";
          version = "1.1.7";
          sha256 = "0sym3qx73gkw9cp46hz10zj9jdqrmg5gilqbcm9b9gfdm16xanw1";
          arch = "linux-arm64";
        };
      }))
    (lib.attrsets.optionalAttrs (isDarwin && (isi686 || isx86_64)) {
      "ms-dotnettools"."csharp" = vscode-utils.extensionFromVscodeMarketplace {
        name = "csharp";
        publisher = "ms-dotnettools";
        version = "2.68.46";
        sha256 = "0jjy3mxc13jwgnaxqpyczp652naxzmjr23j92jnw55is4d2lmclb";
        arch = "darwin-x64";
      };
      "ms-dotnettools"."csdevkit" = vscode-utils.extensionFromVscodeMarketplace {
        name = "csdevkit";
        publisher = "ms-dotnettools";
        version = "1.17.48";
        sha256 = "1gczgaskw0ypvkapac9qsrk1mmz9ic2dy3vg9zx4anf2v2jksy50";
        arch = "darwin-x64";
      };
      "rust-lang"."rust-analyzer" = vscode-utils.extensionFromVscodeMarketplace {
        name = "rust-analyzer";
        publisher = "rust-lang";
        version = "0.4.2336";
        sha256 = "1l7357pfi5g8rwp41izp67knzz6vahl7zfgdi8qlqhkw37jz2c69";
        arch = "darwin-x64";
      };
      "continue"."continue" = vscode-utils.extensionFromVscodeMarketplace {
        name = "continue";
        publisher = "continue";
        version = "1.1.7";
        sha256 = "1nls1j23gyrairx330plhscv9rnhaamy04dbk7s5v1cmd3zc05md";
        arch = "darwin-x64";
      };
    }))
  (lib.attrsets.optionalAttrs (isDarwin && (isAarch32 || isAarch64)) {
    "ms-dotnettools"."csharp" = vscode-utils.extensionFromVscodeMarketplace {
      name = "csharp";
      publisher = "ms-dotnettools";
      version = "2.68.46";
      sha256 = "0d4ml7rv109gzicah448ym7yfkkbaapp1kcykiv2pwsvcmfsydnv";
      arch = "darwin-arm64";
    };
    "ms-dotnettools"."csdevkit" = vscode-utils.extensionFromVscodeMarketplace {
      name = "csdevkit";
      publisher = "ms-dotnettools";
      version = "1.17.48";
      sha256 = "06y80zbvg7inzhm6apab4zp48xrdmk4b18lb01f8gahmclnfbdhw";
      arch = "darwin-arm64";
    };
    "rust-lang"."rust-analyzer" = vscode-utils.extensionFromVscodeMarketplace {
      name = "rust-analyzer";
      publisher = "rust-lang";
      version = "0.4.2336";
      sha256 = "055mv06qz10p03j7npswdjc3v0y5fh9fdplf9dyk7gz9jigvxiq3";
      arch = "darwin-arm64";
    };
    "continue"."continue" = vscode-utils.extensionFromVscodeMarketplace {
      name = "continue";
      publisher = "continue";
      version = "1.1.7";
      sha256 = "1ljr5f0426v3zhfm5r3nsihx8nkxlv0wdfhjy506bcf8478gk6d6";
      arch = "darwin-arm64";
    };
  })
