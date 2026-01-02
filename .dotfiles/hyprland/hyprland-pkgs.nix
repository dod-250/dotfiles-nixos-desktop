# =================
# hyprland-pkgs.nix
# =================

{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    # === Hyprland ecosystem ===
    hyprpaper          # Wallpaper daemon
    hyprlock           # Screen locker
    hypridle           # Idle daemon
    hyprpicker         # Color picker

    # === Terminal & Shell ===
    kitty              # Terminal emulator
    fish               # Shell
    starship           # Prompt

    # ===  Files===
    xfce.mousepad           # Text editor
    kdePackages.gwenview            # Photo viewer
    gvfs         # Virtual Filesystem support library
    samba
    unzip

    # === Launchers & Menus ===
    rofi      # Application launcher

    # === Status bar ===
    waybar             # Status bar

    # === Notifications ===
    libnotify          # Notification library

    # === Screenshot & Screen recording ===
    hyprshot           # Screenshot utility
    obs-studio         # Advanced recording

    # === Clipboard ===
    wl-clipboard       # Wayland clipboard
    cliphist           # Clipboard history

    # === Browsers ===
    firefox            # Web browser

    # === Media ===
    pavucontrol        # Audio control GUI
    cava               # Audio visualizer
    wireplumber        # Modular session / policy manager for PipeWire
    playerctl          # Media player controller
    pulseaudio

    # === Screen ===

    brightnessctl      # Read and control device brightness

    # === System monitoring ===
    btop               # Modern system monitor
    fastfetch          # System info

    # === Network ===
    networkmanagerapplet  # Network manager GUI

    # === Bluetooth ===
    blueman            # Bluetooth manager

    # === Fonts ===
    nerd-fonts._0xproto

    # === Productivity ===
    onlyoffice-desktopeditors
    joplin-desktop
  ];
}
