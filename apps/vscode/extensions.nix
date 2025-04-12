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
            version = "2025.4.905";
            sha256 = "0sqk73wbcb8k7izbjj8nh005qi8c3h3zqkbsiqpl026fzy99c9rj";
          };
          "github"."copilot" = vscode-utils.extensionFromVscodeMarketplace {
            name = "copilot";
            publisher = "github";
            version = "1.277.1411";
            sha256 = "0vv0fzidcp8av4n980phxqjkxs7imyzhkjsqcnsihw50yvczxf8w";
          };
          "pkief"."material-icon-theme" = vscode-utils.extensionFromVscodeMarketplace {
            name = "material-icon-theme";
            publisher = "pkief";
            version = "5.21.2";
            sha256 = "00p10xzccy6y3qk2fsa21jibkq9335ac9sl9abwwg8l2wimhaiqw";
          };
          "ms-vscode-remote"."remote-ssh" = vscode-utils.extensionFromVscodeMarketplace {
            name = "remote-ssh";
            publisher = "ms-vscode-remote";
            version = "0.120.2025040915";
            sha256 = "0zpgk1nf40750b1z8idsj1449xrl6qahshwfy3wpw53a9f4w2vjx";
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
            version = "3.25.0";
            sha256 = "0raszn6p3ywrr2nhh1ya6vfznd8r2gcfx1shh70s1dw9q7mg7k0s";
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
            version = "3.11.12";
            sha256 = "1lpkf661yw5qy7y7xpnrh8ld7hgyam358ckg6aq1qlvzw72hzckz";
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
          "ms-python"."python" = vscode-utils.extensionFromVscodeMarketplace {
            name = "python";
            publisher = "ms-python";
            version = "2025.5.2025041001";
            sha256 = "04nhfnzgkkr34g77bqb3hsl2wk3qwd8772f0vy8cgnbnzd1f2xsj";
            arch = "linux-x64";
          };
          "ms-dotnettools"."csharp" = vscode-utils.extensionFromVscodeMarketplace {
            name = "csharp";
            publisher = "ms-dotnettools";
            version = "2.73.16";
            sha256 = "1mbhxmdkmigx52dib5dc1iywjqilplgi5pg817n9pmc26dd8qfky";
            arch = "linux-x64";
          };
          "ms-dotnettools"."csdevkit" = vscode-utils.extensionFromVscodeMarketplace {
            name = "csdevkit";
            publisher = "ms-dotnettools";
            version = "1.19.4";
            sha256 = "0jj82d585nps306gwx3ar1ar2lankflz4i49kgr4gi456q27v0hp";
            arch = "linux-x64";
          };
          "rust-lang"."rust-analyzer" = vscode-utils.extensionFromVscodeMarketplace {
            name = "rust-analyzer";
            publisher = "rust-lang";
            version = "0.4.2375";
            sha256 = "03g1gp752h8kkz2l6fxfff76a47casj0509d7nbd8lf7wbz73ykk";
            arch = "linux-x64";
          };
        }))
      (lib.attrsets.optionalAttrs (isLinux && (isAarch32 || isAarch64)) {
        "ms-python"."python" = vscode-utils.extensionFromVscodeMarketplace {
          name = "python";
          publisher = "ms-python";
          version = "2025.5.2025041001";
          sha256 = "0h6dzdr92imnskg0mv08l6c3ni98igb6060pjybhckjpiwg5jgz8";
          arch = "linux-arm64";
        };
        "ms-dotnettools"."csharp" = vscode-utils.extensionFromVscodeMarketplace {
          name = "csharp";
          publisher = "ms-dotnettools";
          version = "2.73.16";
          sha256 = "0gz59if9r506if6x6b2lzhczbnvbabjdirr9118078gl5rnfpmqz";
          arch = "linux-arm64";
        };
        "ms-dotnettools"."csdevkit" = vscode-utils.extensionFromVscodeMarketplace {
          name = "csdevkit";
          publisher = "ms-dotnettools";
          version = "1.19.4";
          sha256 = "072as06k9c1z9pv7aj6ykbi8kf1xxx2vzvhpka45hv21ciyxcpgv";
          arch = "linux-arm64";
        };
        "rust-lang"."rust-analyzer" = vscode-utils.extensionFromVscodeMarketplace {
          name = "rust-analyzer";
          publisher = "rust-lang";
          version = "0.4.2375";
          sha256 = "16fnj0m5mfa91hy1nf4p1if2jpaarlld6wyj91gjfsjyl9dfp4rl";
          arch = "linux-arm64";
        };
      }))
    (lib.attrsets.optionalAttrs (isDarwin && (isi686 || isx86_64)) {
      "ms-python"."python" = vscode-utils.extensionFromVscodeMarketplace {
        name = "python";
        publisher = "ms-python";
        version = "2025.5.2025041001";
        sha256 = "18zyl65xnszbr5il3ird0ma5sqlql1g9l57kfpqj23b0i4r4nzcf";
        arch = "darwin-x64";
      };
      "ms-dotnettools"."csharp" = vscode-utils.extensionFromVscodeMarketplace {
        name = "csharp";
        publisher = "ms-dotnettools";
        version = "2.73.16";
        sha256 = "1p04pcmx3b500jb22w3sy89n9wm09lxccfkplr2w2wypjsghvz3h";
        arch = "darwin-x64";
      };
      "ms-dotnettools"."csdevkit" = vscode-utils.extensionFromVscodeMarketplace {
        name = "csdevkit";
        publisher = "ms-dotnettools";
        version = "1.19.4";
        sha256 = "02ia55pq87sjyvzffn07i1zyyxfgvlxr9v8z4bv0rc4m4pqmnxds";
        arch = "darwin-x64";
      };
      "rust-lang"."rust-analyzer" = vscode-utils.extensionFromVscodeMarketplace {
        name = "rust-analyzer";
        publisher = "rust-lang";
        version = "0.4.2375";
        sha256 = "140cqyrdnk0rgplycdn0v9q21ilp0hqmyr224i4fnjjiyfyyqlxy";
        arch = "darwin-x64";
      };
    }))
  (lib.attrsets.optionalAttrs (isDarwin && (isAarch32 || isAarch64)) {
    "ms-python"."python" = vscode-utils.extensionFromVscodeMarketplace {
      name = "python";
      publisher = "ms-python";
      version = "2025.5.2025041001";
      sha256 = "06c75i82cr74f4lyzwkq71mhb5dzy8kygil49ihqw240g6kcfqrl";
      arch = "darwin-arm64";
    };
    "ms-dotnettools"."csharp" = vscode-utils.extensionFromVscodeMarketplace {
      name = "csharp";
      publisher = "ms-dotnettools";
      version = "2.73.16";
      sha256 = "0wjjr7s68wdq4djhc0553h7a500m26sq6nd434l80vfj7446713a";
      arch = "darwin-arm64";
    };
    "ms-dotnettools"."csdevkit" = vscode-utils.extensionFromVscodeMarketplace {
      name = "csdevkit";
      publisher = "ms-dotnettools";
      version = "1.19.4";
      sha256 = "17gl22idg1vkc94dgkzi4rqljhmrf2kkxyfr8i75m7h4iaplnj9j";
      arch = "darwin-arm64";
    };
    "rust-lang"."rust-analyzer" = vscode-utils.extensionFromVscodeMarketplace {
      name = "rust-analyzer";
      publisher = "rust-lang";
      version = "0.4.2375";
      sha256 = "0bnfr0zhbfbw81lw9v0nfh9dk6bgibk0kxpb9v4fkmlk9v635dp6";
      arch = "darwin-arm64";
    };
  })
