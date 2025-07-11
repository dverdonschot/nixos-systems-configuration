{ config, lib, pkgs, ... }:

{
  wayland.windowManager.sway = {
    enable = true;
    config = {
      # Use Alt as modifier instead of Super
      modifier = "Mod1";  # Alt key
      
      # Terminal
      terminal = "alacritty";
      
      # Menu launcher
      menu = "wofi --show drun";
      
      # Input configuration
      input = {
        "type:touchpad" = {
          tap = "enabled";
          natural_scroll = "enabled";
          dwt = "enabled";
          accel_profile = "adaptive";
          click_method = "clickfinger";
        };
        "type:keyboard" = {
          xkb_layout = "us";
        };
      };

      # Output configuration
      output = {};

      # Window decoration
      gaps = {
        inner = 5;
        outer = 20;
      };
      
      window = {
        border = 2;
        titlebar = false;
      };

      # Focus settings
      focus = {
        followMouse = true;
      };

      # Colors (Dracula theme)
      colors = {
        focused = {
          border = "#bd93f9";
          background = "#bd93f9";
          text = "#f8f8f2";
          indicator = "#bd93f9";
          childBorder = "#bd93f9";
        };
        focusedInactive = {
          border = "#44475a";
          background = "#44475a";
          text = "#f8f8f2";
          indicator = "#44475a";
          childBorder = "#44475a";
        };
        unfocused = {
          border = "#282a36";
          background = "#282a36";
          text = "#bfbfbf";
          indicator = "#282a36";
          childBorder = "#282a36";
        };
        urgent = {
          border = "#ff5555";
          background = "#ff5555";
          text = "#f8f8f2";
          indicator = "#ff5555";
          childBorder = "#ff5555";
        };
      };

      # Keybindings using Alt instead of Super
      keybindings = {
        # Application shortcuts
        "Mod1+Return" = "exec alacritty";
        "Mod1+q" = "kill";
        "Mod1+Shift+e" = "exec swaynag -t warning -m 'You pressed the exit shortcut. Do you really want to exit sway? This will end your Wayland session.' -b 'Yes, exit sway' 'swaymsg exit'";
        "Mod1+e" = "exec nautilus";
        "Mod1+Shift+space" = "floating toggle";
        "Mod1+r" = "exec wofi --show drun";
        "Mod1+f" = "fullscreen toggle";

        # Move focus with Alt + arrow keys
        "Mod1+Left" = "focus left";
        "Mod1+Down" = "focus down";
        "Mod1+Up" = "focus up";
        "Mod1+Right" = "focus right";

        # Move focus with Alt + hjkl
        "Mod1+h" = "focus left";
        "Mod1+j" = "focus down";
        "Mod1+k" = "focus up";
        "Mod1+l" = "focus right";

        # Move windows with Alt + Shift + arrow keys
        "Mod1+Shift+Left" = "move left";
        "Mod1+Shift+Down" = "move down";
        "Mod1+Shift+Up" = "move up";
        "Mod1+Shift+Right" = "move right";

        # Move windows with Alt + Shift + hjkl
        "Mod1+Shift+h" = "move left";
        "Mod1+Shift+j" = "move down";
        "Mod1+Shift+k" = "move up";
        "Mod1+Shift+l" = "move right";

        # Switch to workspace
        "Mod1+1" = "workspace number 1";
        "Mod1+2" = "workspace number 2";
        "Mod1+3" = "workspace number 3";
        "Mod1+4" = "workspace number 4";
        "Mod1+5" = "workspace number 5";
        "Mod1+6" = "workspace number 6";
        "Mod1+7" = "workspace number 7";
        "Mod1+8" = "workspace number 8";
        "Mod1+9" = "workspace number 9";
        "Mod1+0" = "workspace number 10";

        # Move window to workspace
        "Mod1+Shift+1" = "move container to workspace number 1";
        "Mod1+Shift+2" = "move container to workspace number 2";
        "Mod1+Shift+3" = "move container to workspace number 3";
        "Mod1+Shift+4" = "move container to workspace number 4";
        "Mod1+Shift+5" = "move container to workspace number 5";
        "Mod1+Shift+6" = "move container to workspace number 6";
        "Mod1+Shift+7" = "move container to workspace number 7";
        "Mod1+Shift+8" = "move container to workspace number 8";
        "Mod1+Shift+9" = "move container to workspace number 9";
        "Mod1+Shift+0" = "move container to workspace number 10";

        # Layout commands
        "Mod1+b" = "splith";
        "Mod1+v" = "splitv";
        "Mod1+s" = "layout stacking";
        "Mod1+w" = "layout tabbed";
        "Mod1+Shift+s" = "layout toggle split";
        "Mod1+space" = "focus mode_toggle";
        "Mod1+a" = "focus parent";

        # Resize mode
        "Mod1+Shift+r" = "mode resize";

        # Volume control
        "XF86AudioRaiseVolume" = "exec wpctl set-volume @DEFAULT_AUDIO_SINK@ +5%";
        "XF86AudioLowerVolume" = "exec wpctl set-volume @DEFAULT_AUDIO_SINK@ -5%";
        "XF86AudioMute" = "exec wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";

        # Brightness control
        "XF86MonBrightnessUp" = "exec brightnessctl set +10%";
        "XF86MonBrightnessDown" = "exec brightnessctl set 10%-";

        # Screenshot
        "Mod1+Print" = "exec grim -g \"$(slurp)\" - | wl-copy";
        "Print" = "exec grim - | wl-copy";

        # Lock screen
        "Mod1+Ctrl+l" = "exec swaylock -f";

        # Media control
        "XF86AudioPlay" = "exec playerctl play-pause";
        "XF86AudioNext" = "exec playerctl next";
        "XF86AudioPrev" = "exec playerctl previous";
      };

      # Resize mode bindings
      modes = {
        resize = {
          "Left" = "resize shrink width 10px";
          "Down" = "resize grow height 10px";
          "Up" = "resize shrink height 10px";
          "Right" = "resize grow width 10px";
          "h" = "resize shrink width 10px";
          "j" = "resize grow height 10px";
          "k" = "resize shrink height 10px";
          "l" = "resize grow width 10px";
          "Return" = "mode default";
          "Escape" = "mode default";
        };
      };

      # Window rules
      window.commands = [
        {
          criteria = { app_id = "pavucontrol"; };
          command = "floating enable";
        }
        {
          criteria = { app_id = "blueman-manager"; };
          command = "floating enable";
        }
        {
          criteria = { app_id = "nm-connection-editor"; };
          command = "floating enable";
        }
      ];

      # Auto-start applications
      startup = [
        { command = "waybar"; }
        { command = "dunst"; }
        { command = "nm-applet --indicator"; }
        { command = "blueman-applet"; }
        { command = "swayidle -w timeout 300 'swaylock -f' timeout 600 'swaymsg \"output * power off\"' resume 'swaymsg \"output * power on\"' before-sleep 'swaylock -f'"; }
      ];

      # Bars (disable default, we'll use waybar)
      bars = [];
    };

    # Extra configuration
    extraConfig = ''
      # Laptop-specific configurations
      bindswitch --reload --locked lid:on exec swaylock -f
    '';
  };

  # Configure waybar for Sway
  programs.waybar = {
    enable = true;
    systemd.enable = true;
    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 30;
        spacing = 4;

        modules-left = [ "sway/workspaces" "sway/mode" ];
        modules-center = [ "sway/window" ];
        modules-right = [ "pulseaudio" "network" "cpu" "memory" "temperature" "battery" "clock" "tray" ];

        "sway/workspaces" = {
          disable-scroll = true;
          all-outputs = true;
          format = "{icon}";
          format-icons = {
            "1" = "1";
            "2" = "2";
            "3" = "3";
            "4" = "4";
            "5" = "5";
            "6" = "6";
            "7" = "7";
            "8" = "8";
            "9" = "9";
            "10" = "10";
          };
        };

        "sway/mode" = {
          format = "<span style=\"italic\">{}</span>";
        };

        "sway/window" = {
          format = "{}";
          max-length = 50;
          separate-outputs = true;
        };

        tray = {
          spacing = 10;
        };

        clock = {
          tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
          format-alt = "{:%Y-%m-%d}";
        };

        cpu = {
          format = "{usage}% ";
          tooltip = false;
        };

        memory = {
          format = "{}% ";
        };

        temperature = {
          critical-threshold = 80;
          format = "{temperatureC}°C {icon}";
          format-icons = ["" "" ""];
        };

        battery = {
          states = {
            warning = 30;
            critical = 15;
          };
          format = "{capacity}% {icon}";
          format-charging = "{capacity}% ";
          format-plugged = "{capacity}% ";
          format-alt = "{time} {icon}";
          format-icons = ["" "" "" "" ""];
        };

        network = {
          format-wifi = "{essid} ({signalStrength}%) ";
          format-ethernet = "{ipaddr}/{cidr} ";
          tooltip-format = "{ifname} via {gwaddr} ";
          format-linked = "{ifname} (No IP) ";
          format-disconnected = "Disconnected ⚠";
          format-alt = "{ifname}: {ipaddr}/{cidr}";
        };

        pulseaudio = {
          format = "{volume}% {icon} {format_source}";
          format-bluetooth = "{volume}% {icon} {format_source}";
          format-bluetooth-muted = " {icon} {format_source}";
          format-muted = " {format_source}";
          format-source = "{volume}% ";
          format-source-muted = "";
          format-icons = {
            headphone = "";
            hands-free = "";
            headset = "";
            phone = "";
            portable = "";
            car = "";
            default = ["" "" ""];
          };
          on-click = "pavucontrol";
        };
      };
    };

    style = ''
      * {
        border: none;
        border-radius: 0;
        font-family: "Hack Nerd Font";
        font-size: 13px;
        min-height: 0;
      }

      window#waybar {
        background-color: rgba(40, 42, 54, 0.8);
        border-bottom: 3px solid rgba(189, 147, 249, 0.5);
        color: #f8f8f2;
        transition-property: background-color;
        transition-duration: .5s;
      }

      #workspaces button {
        padding: 0 5px;
        background-color: transparent;
        color: #f8f8f2;
        border-bottom: 3px solid transparent;
        min-width: 50px;
      }

      #workspaces button:hover {
        background: rgba(68, 71, 90, 0.2);
      }

      #workspaces button.focused {
        background-color: #6272a4;
        border-bottom: 3px solid #bd93f9;
      }

      #workspaces button.urgent {
        background-color: #ff5555;
      }

      #mode {
        background-color: #ff79c6;
        border-bottom: 3px solid #f8f8f2;
        color: #282a36;
      }

      #clock, #battery, #cpu, #memory, #temperature, #network, #pulseaudio, #tray {
        padding: 0 10px;
        color: #f8f8f2;
      }

      #battery.charging, #battery.plugged {
        color: #f8f8f2;
        background-color: #50fa7b;
      }

      #battery.critical:not(.charging) {
        background-color: #ff5555;
        color: #f8f8f2;
        animation-name: blink;
        animation-duration: 0.5s;
        animation-timing-function: linear;
        animation-iteration-count: infinite;
        animation-direction: alternate;
      }

      @keyframes blink {
        to {
          background-color: #f8f8f2;
          color: #ff5555;
        }
      }
    '';
  };

  # Configure wofi (application launcher)
  programs.wofi = {
    enable = true;
    settings = {
      width = 600;
      height = 400;
      location = "center";
      show = "drun";
      prompt = "Search...";
      filter_rate = 100;
      allow_markup = true;
      no_actions = true;
      halign = "fill";
      orientation = "vertical";
      content_halign = "fill";
      insensitive = true;
      allow_images = true;
      image_size = 40;
      gtk_dark = true;
    };

    style = ''
      window {
        margin: 0px;
        border: 1px solid #bd93f9;
        background-color: #282a36;
        border-radius: 15px;
      }

      #input {
        margin: 5px;
        border: none;
        color: #f8f8f2;
        background-color: #44475a;
        border-radius: 15px;
      }

      #inner-box {
        margin: 5px;
        border: none;
        background-color: #282a36;
      }

      #outer-box {
        margin: 5px;
        border: none;
        background-color: #282a36;
      }

      #scroll {
        margin: 0px;
        border: none;
      }

      #text {
        margin: 5px;
        border: none;
        color: #f8f8f2;
      }

      #entry {
        border: none;
        border-radius: 15px;
      }

      #entry:selected {
        background-color: #44475a;
      }
    '';
  };

  # Configure dunst (notifications)
  services.dunst = {
    enable = true;
    settings = {
      global = {
        monitor = 0;
        follow = "mouse";
        width = 300;
        height = 300;
        origin = "top-right";
        offset = "10x50";
        scale = 0;
        notification_limit = 0;
        progress_bar = true;
        progress_bar_height = 10;
        progress_bar_frame_width = 1;
        progress_bar_min_width = 150;
        progress_bar_max_width = 300;
        indicate_hidden = "yes";
        transparency = 0;
        separator_height = 2;
        padding = 8;
        horizontal_padding = 8;
        text_icon_padding = 0;
        frame_width = 3;
        frame_color = "#bd93f9";
        separator_color = "frame";
        sort = "yes";
        idle_threshold = 120;
        font = "Hack 12";
        line_height = 0;
        markup = "full";
        format = "<b>%s</b>\n%b";
        alignment = "left";
        vertical_alignment = "center";
        show_age_threshold = 60;
        ellipsize = "middle";
        ignore_newline = "no";
        stack_duplicates = true;
        hide_duplicate_count = false;
        show_indicators = "yes";
        icon_position = "left";
        min_icon_size = 0;
        max_icon_size = 32;
        sticky_history = "yes";
        history_length = 20;
        browser = "/usr/bin/env firefox";
        always_run_script = true;
        title = "Dunst";
        class = "Dunst";
        corner_radius = 10;
        ignore_dbusclose = false;
        force_xwayland = false;
        force_xinerama = false;
        mouse_left_click = "close_current";
        mouse_middle_click = "do_action, close_current";
        mouse_right_click = "close_all";
      };
      experimental = {
        per_monitor_dpi = false;
      };
      urgency_low = {
        background = "#282a36";
        foreground = "#6272a4";
        timeout = 10;
      };
      urgency_normal = {
        background = "#282a36";
        foreground = "#bd93f9";
        timeout = 10;
      };
      urgency_critical = {
        background = "#ff5555";
        foreground = "#f8f8f2";
        frame_color = "#ff5555";
        timeout = 0;
      };
    };
  };

  # Configure alacritty terminal
  programs.alacritty = {
    enable = true;
    settings = {
      colors = {
        primary = {
          background = "#282a36";
          foreground = "#f8f8f2";
        };
        normal = {
          black = "#000000";
          red = "#ff5555";
          green = "#50fa7b";
          yellow = "#f1fa8c";
          blue = "#bd93f9";
          magenta = "#ff79c6";
          cyan = "#8be9fd";
          white = "#bfbfbf";
        };
        bright = {
          black = "#4d4d4d";
          red = "#ff6e67";
          green = "#5af78e";
          yellow = "#f4f99d";
          blue = "#caa9fa";
          magenta = "#ff92d0";
          cyan = "#9aedfe";
          white = "#e6e6e6";
        };
      };
      font = {
        normal.family = "Hack Nerd Font";
        bold.family = "Hack Nerd Font";
        italic.family = "Hack Nerd Font";
        size = 12.0;
      };
      window = {
        opacity = 0.9;
        padding = {
          x = 10;
          y = 10;
        };
      };
    };
  };

  # Required packages for the setup
  home.packages = with pkgs; [
    # Core utilities
    grim                # Screenshot tool
    slurp               # Select area for screenshots
    wl-clipboard        # Wayland clipboard utilities
    brightnessctl       # Brightness control
    pavucontrol         # Audio control GUI
    networkmanagerapplet # Network manager applet
    blueman             # Bluetooth manager
    swaylock            # Screen locker
    swayidle            # Idle daemon
    playerctl           # Media player control
    
    # Theme and appearance
    oreo-cursors-plus   # Cursor theme
    
    # Utilities
    nautilus            # File manager
  ];

}