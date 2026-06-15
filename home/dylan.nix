# Shared Home Manager configuration for user dylan
{ pkgs, osConfig, ... }:

{
  home.packages = [ ];

  programs.bash.enable = true;

  programs.firefox = {
    enable = true;
    profiles = {
      default = {
        id = 0;
        name = "Default";
        isDefault = true;
        extensions.packages = with pkgs.nur.repos.rycee.firefox-addons; [
          darkreader
          ublock-origin
          bitwarden
        ];
      };
    };
  };

  # dconf settings for GNOME
  dconf.settings = {
    # Swap Caps Lock and Escape
    "org/gnome/desktop/input-sources" = {
      xkb-options = [ "caps:swapescape" ];
    };

    # Configure nautilus-open-any-terminal to use Ptyxis
    "com/github/stunkymonkey/nautilus-open-any-terminal" = {
      terminal = "ptyxis";
    };

    # Custom keybindings
    "org/gnome/settings-daemon/plugins/media-keys" = {
      custom-keybindings = [
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/open-ptyxis/"
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/open-firefox/"
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/open-resources/"
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/open-nautilus/"
      ];
      terminal = [ ];
    };

    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/open-ptyxis" = {
      name = "Open Terminal (Ptyxis)";
      command = "ptyxis --new-window";
      binding = "<Primary><Alt>t";
    };

    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/open-nautilus" = {
      name = "Open Files (Nautilus)";
      command = "nautilus --new-window";
      binding = "<Primary><Alt>n";
    };

    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/open-firefox" = {
      name = "Open Firefox";
      command = "firefox";
      binding = "<Primary><Alt>f";
    };

    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/open-resources" = {
      name = "Open Resources";
      command = "resources";
      binding = "<Primary><Shift>Escape";
    };

    # Mutter/Wayland features (base - hosts can override)
	# Added all of these here to see if I want them on my laptop
    "org/gnome/mutter" = {
      experimental-features = [
        "variable-refresh-rate"
		"scale-monitor-framebuffer"
		"xwayland-native-scaling"
      ];
    };

    # Alt-Tab switches windows instead of apps
    "org/gnome/desktop/wm/keybindings" = {
      "switch-applications" = [ ];
      "switch-applications-backward" = [ ];
      "switch-windows" = [ "<Alt>Tab" ];
      "switch-windows-backward" = [ "<Shift><Alt>Tab" ];
    };

    # Dock favorites
    "org/gnome/shell" = {
      favorite-apps = [
        "org.gnome.Settings.desktop"
        "com.mattjakeman.ExtensionManager.desktop"
        "org.gnome.Ptyxis.desktop"
        "org.gnome.Nautilus.desktop"
        "firefox.desktop"
        "proton-bridge-gui.desktop"
        "thunderbird.desktop"
        "signal.desktop"
        "joplin.desktop"
        "org.gnome.Calendar.desktop"
        "io.github.mrvladus.List.desktop"
        "onlyoffice-desktopeditors.desktop"
        "com.github.phase1geo.minder.desktop"
        "org.gnome.World.Iotas.desktop"
        "org.kicad.kicad.desktop"
        "arduino-ide.desktop"
        "code.desktop"
        "lm-studio.desktop"
        "org.freecad.FreeCAD.desktop"
        "PrusaSlicer.desktop"
        "freetube.desktop"
        "discord.desktop"
        "steam.desktop"
        "dolphin-emu.desktop"
        "Ryujinx.desktop"
      ];
    };
  };

  home.stateVersion = osConfig.system.stateVersion;
}
