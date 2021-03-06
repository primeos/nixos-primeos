{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.programs.rootston;

  rootstonWrapped = pkgs.writeScriptBin "rootston" ''
    #! ${pkgs.runtimeShell}
    if [[ "$#" -ge 1 ]]; then
      exec ${pkgs.wlroots.bin}/bin/rootston "$@"
    else
      ${cfg.extraSessionCommands}
      exec ${pkgs.wlroots.bin}/bin/rootston -C ${cfg.configFile}
    fi
  '';
in {
  options.programs.rootston = {
    enable = mkEnableOption ''
      rootston, the reference compositor for wlroots. The purpose of rootston
      is to test and demonstrate the features of wlroots (if you want a real
      Wayland compositor you should e.g. use Sway instead). You can manually
      start the compositor by running "rootston" from a terminal'';

    extraSessionCommands = mkOption {
      type = types.lines;
      default = "";
      example = ''
      '';
      description = ''
        Shell commands executed just before rootston is started.
      '';
    };

    extraPackages = mkOption {
      type = with types; listOf package;
      default = with pkgs; [
        westonLite xwayland rofi
      ];
      defaultText = literalExample ''
        with pkgs; [
          westonLite xwayland rofi
        ]
      '';
      example = literalExample "[ ]";
      description = ''
        Extra packages to be installed system wide.
      '';
    };

    config = mkOption {
      type = types.attrs;
      default = {
        keyboard = {
          meta-key = "Logo";
        };

        bindings = {
          # Sway/i3 like Keybindings
          # Maps key combinations with commands to execute
          # Commands include:
          # - "exit" to stop the compositor
          # - "exec" to execute a shell command
          # - "close" to close the current view
          # - "next_window" to cycle through windows
          "Logo+Shift+e" = "exit";
          "Logo+q" = "close";
          "Logo+m" = "maximize";
          "Alt+Tab" = "next_window";
          "Logo+Return" = "exec weston-terminal";
          "Logo+d" = "exec rofi -show run";
        };
      };
      description = ''
        Default configuration for rootston (used when called without any
        parameters).
      '';
    };

    extraConfig = mkOption {
      type = types.attrs;
      default = { };
      example = {
        keyboard = {
          layout = "de,us";
          variant = "nodeadkeys";
          options = "grp:alt_shift_toggle,caps:escape";
        };
      };
      description = ''
        Extra configuration options for rootston. These options will be merged
        with the base configuration from config (overriding existing options).
      '';
    };

    configFile = mkOption {
      type = types.path;
      default = "/etc/rootston.ini";
      example = literalExample "${pkgs.wlroots.bin}/etc/rootston.ini";
      description = ''
        Path to the default rootston configuration file (the "config" option
        will have no effect if you change the path).
      '';
    };
  };

  config = mkIf cfg.enable {
    environment.etc."rootston.ini".text = lib.generators.toINI {}
      (lib.recursiveUpdate cfg.config cfg.extraConfig);
    environment.systemPackages = [ rootstonWrapped ] ++ cfg.extraPackages;

    hardware.opengl.enable = mkDefault true;
    fonts.enableDefaultFonts = mkDefault true;
    programs.dconf.enable = mkDefault true;
  };

  meta.maintainers = with lib.maintainers; [ primeos ];
}
