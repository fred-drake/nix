{
  pkgs,
  lib,
  ...
}: {
  editorconfig = {
    enable = true;
    settings = {
      "*" = {
        charset = "utf-8";
        end_of_line = "lf";
        trim_trailing_whitespace = true;
        insert_final_newline = true;
        max_line_width = 100;
        indent_style = "space";
        indent_size = 4;
      };
      "*.{toml,js,nix,yaml}" = {indent_size = 2;};
    };
  };

  programs = {
    jq.enable = true;

    lazygit = {
      enable = true;
      settings = {
        git.pagers = [{pager = "delta --dark --paging=never";}];
        gui.theme = {lightTheme = true;};
      };
    };

    helix = {
      enable = true;
      defaultEditor = true;

      themes = {
        tokyonight_transparent = {
          inherits = "tokyonight";
          "ui.background" = {};
          "ui.cursorline.primary" = {};
          "ui.statusline" = {fg = "#a9b1d6";};
          "ui.statusline.inactive" = {fg = "#565f89";};
          "ui.bufferline" = {fg = "#565f89";};
          "ui.bufferline.active" = {fg = "#a9b1d6";};
        };
      };

      settings = {
        theme = "tokyonight_transparent";

        editor = {
          line-number = "relative";
          mouse = true;
          cursorline = true;
          rulers = [100];
          color-modes = true;
          bufferline = "multiple";
          true-color = true;
          popup-border = "all";
          end-of-line-diagnostics = "hint";

          inline-diagnostics = {
            cursor-line = "warning";
            other-lines = "warning";
          };

          auto-save = {
            focus-lost = true;
            after-delay = {
              enable = true;
              timeout = 500;
            };
          };

          cursor-shape = {
            insert = "bar";
            normal = "block";
            select = "underline";
          };

          file-picker.hidden = false;

          indent-guides = {
            render = true;
            character = "│";
          };

          lsp = {
            display-messages = true;
            display-inlay-hints = true;
          };

          statusline = {
            left = ["mode" "spinner" "file-name" "file-modification-indicator"];
            center = [];
            right = ["diagnostics" "selections" "register" "position" "file-encoding"];
            separator = "│";
            mode = {
              normal = "NORMAL";
              insert = "INSERT";
              select = "SELECT";
            };
          };

          whitespace.render.tab = "all";
          whitespace.render.newline = "none";

          soft-wrap.enable = true;
        };

        keys = {
          normal = {
            K = "hover";
            C-s = ":w";
            C-q = ":q";
            C-h = ":bp";
            C-l = ":bn";
            y = "yank_to_clipboard";
            d = ["yank_to_clipboard" "delete_selection_noyank"];
            c = ["yank_to_clipboard" "change_selection_noyank"];
          };

          insert = {
            j = {k = "normal_mode";};
          };

          select = {
            j = {k = "normal_mode";};
          };
        };
      };

      languages = {
        language-server = {
          nil = {
            command = "${lib.getExe pkgs.nil}";
          };

          rust-analyzer = {
            command = "${lib.getExe pkgs.rust-analyzer}";
          };

          basedpyright = {
            command = "${pkgs.basedpyright}/bin/basedpyright-langserver";
            args = ["--stdio"];
          };

          ruff = {
            command = "${lib.getExe pkgs.ruff}";
            args = ["server"];
          };

          gopls = {
            command = "${lib.getExe pkgs.gopls}";
          };

          clangd = {
            command = "${lib.getExe' pkgs.clang-tools "clangd"}";
          };

          html = {
            command = "${pkgs.vscode-langservers-extracted}/bin/vscode-html-language-server";
            args = ["--stdio"];
          };

          css = {
            command = "${pkgs.vscode-langservers-extracted}/bin/vscode-css-language-server";
            args = ["--stdio"];
          };

          json = {
            command = "${pkgs.vscode-langservers-extracted}/bin/vscode-json-language-server";
            args = ["--stdio"];
          };

          yaml = {
            command = "${pkgs.yaml-language-server}/bin/yaml-language-server";
            args = ["--stdio"];
          };

          taplo = {
            command = "${pkgs.taplo}/bin/taplo";
            args = ["lsp" "stdio"];
          };

          jdtls = {
            command = "${lib.getExe pkgs.jdt-language-server}";
          };

          marksman = {
            command = "${lib.getExe pkgs.marksman}";
          };

          markdown-oxide = {
            command = "${lib.getExe pkgs.markdown-oxide}";
          };
        };

        language = [
          {
            name = "nix";
            auto-format = true;
            language-servers = ["nil"];
            formatter.command = "${lib.getExe pkgs.alejandra}";
            formatter.args = ["-q"];
          }
          {
            name = "rust";
            auto-format = true;
            language-servers = ["rust-analyzer"];
          }
          {
            name = "python";
            auto-format = true;
            language-servers = ["basedpyright" "ruff"];
            formatter = {
              command = "${lib.getExe pkgs.ruff}";
              args = ["format" "-"];
            };
          }
          {
            name = "go";
            auto-format = true;
            language-servers = ["gopls"];
          }
          {
            name = "c";
            auto-format = true;
            language-servers = ["clangd"];
            formatter.command = "${lib.getExe' pkgs.clang-tools "clang-format"}";
          }
          {
            name = "html";
            auto-format = true;
            language-servers = ["html"];
            formatter = {
              command = "${lib.getExe pkgs.prettier}";
              args = ["--stdin-filepath" "file.html"];
            };
          }
          {
            name = "css";
            auto-format = true;
            language-servers = ["css"];
            formatter = {
              command = "${lib.getExe pkgs.prettier}";
              args = ["--stdin-filepath" "file.css"];
            };
          }
          {
            name = "scss";
            auto-format = true;
            language-servers = ["css"];
          }
          {
            name = "json";
            auto-format = false;
            language-servers = ["json"];
            formatter.command = "${pkgs.jaq}/bin/jaq";
          }
          {
            name = "yaml";
            auto-format = true;
            language-servers = ["yaml"];
          }
          {
            name = "toml";
            auto-format = true;
            language-servers = ["taplo"];
            formatter.command = "${lib.getExe pkgs.taplo}";
            formatter.args = ["format" "-"];
          }
          {
            name = "java";
            language-servers = ["jdtls"];
          }
          {
            name = "markdown";
            auto-format = true;
            language-servers = ["markdown-oxide" "marksman"];
            formatter = {
              command = "${lib.getExe pkgs.prettier}";
              args = ["--stdin-filepath" "file.md"];
            };
          }
        ];
      };
    };
  };
}
