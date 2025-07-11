{ config, lib, pkgs, ... }:

{
  # Enable Wayland session variables for proper Sway integration
  home.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    MOZ_ENABLE_WAYLAND = "1";
    QT_QPA_PLATFORM = "wayland";
    CLUTTER_BACKEND = "wayland";
    XDG_SESSION_TYPE = "wayland";
    GDK_BACKEND = "wayland,x11";
  };

  # Import the main Sway configuration
  imports = [ ./sway.nix ];

  # Laptop76-specific packages for Sway
  home.packages = with pkgs; [
    firefox-wayland
    nerdfonts
  ];

  # Laptop76-specific Sway overrides
  wayland.windowManager.sway.config = {
    # Laptop-specific output configuration
    output = {
      "eDP-1" = {
        bg = "/home/ewt/.config/wallpaper.jpg fill";
        scale = "1";
      };
    };

    # Additional laptop-specific keybindings
    keybindings = lib.mkAfter {
      # Laptop lid switch handled by system, but add manual lock
      "Mod1+Shift+l" = "exec swaylock -f";
      
      # Laptop-specific shortcuts
      "Mod1+Tab" = "workspace next";
      "Mod1+Shift+Tab" = "workspace prev";
    };
  };

  # Override alacritty font size for laptop screen
  programs.alacritty.settings.font.size = lib.mkForce 11.0;

  # Waybar laptop-specific styling
  programs.waybar.style = lib.mkAfter ''
    window#waybar {
      font-size: 12px;
    }
  '';
}