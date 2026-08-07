{ pkgs, inputs, settings, ... }: let
    unstable = import inputs.nixpkgs-unstable { inherit (pkgs) system; };
in {
    home-manager.users.${settings.account.name} = { config, ... }: {
        programs.zed-editor = {
            enable = true;
            package = unstable.zed-editor;

            extensions = [ "nix" "toml" "elixir" "make" "haskell" "assembly" "latex" "catppuccin" ];

            userSettings = {
                autosave = "on_focus_change";

                indent_guides = {
                    enabled = true;
                    coloring = "indent_aware";
                };

                hour_format = "hour24";
                auto_update = false;

                terminal = {
                    alternate_scroll = "off";
                    blinking = "off";
                    copy_on_select = false;
                    dock = "bottom";
                    detect_venv = {
                        on = {
                            directories = [ ".env" "env" ".venv" "venv" ];
                            activate_script = "default";
                        };
                    };
                    env.TERM = "foot";
                    font_family = settings.font.monoName;
                    font_features = null;
                    font_size = null;
                    line_height = "comfortable";
                    option_as_meta = false;
                    button = false;
                    shell = "system";
                    toolbar.title = true;
                    working_directory = "current_project_directory";
                };

                lsp = {
                    rust-analyzer.binary.path_lookup = true;
                    nix.binary.path_lookup = true;
                    haskell.binary.path_lookup = true;
                };

                load_direnv = "shell_hook";
                base_keymap = "VSCode";

                theme = {
                    mode = "system";
                    light = "One Light";
                    dark = "Catppuccin Espresso (Blur) [Heavy]";
                };

                project_panel.dock = "left";

                show_whitespaces = "all";
                ui_font_size = settings.font.uiSize;
                buffer_font_size = 14;
            };
        };
    };
}
