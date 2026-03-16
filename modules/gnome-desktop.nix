# GNOME desktop environment configuration
{ config, pkgs, lib, ... }:

{
  # X11 and GNOME
  services.xserver.enable = true;
  services.displayManager.gdm.enable = true;
  services.xserver.displayManager.gdm.autoLogin = {
    enable = true;
	user = "dylan";
  };
  services.desktopManager.gnome.enable = true;

  # This workaround is needed because of a GNOME race condition
  # that can cause the login to fail on first boot
  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@tty1".enable = false;

  # Keymap
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Printing
  services.printing.enable = true;

  # Enable dconf (needed for some GNOME apps)
  programs.dconf.enable = true;

  # Audio with PipeWire
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # GNOME Extensions and appearance
  environment.systemPackages = with pkgs; [
    # Appearance
    adw-gtk3

    # GNOME utilities
    gnome-tweaks
    gnome-extension-manager

	# Nautilus integration
	nautilus-python
	nautilus-open-any-terminal

	# GUI applications
	resources
	firefox
	warp
	ptyxis



    # GNOME Extensions (shared across machines)
    gnomeExtensions.weather-or-not
    gnomeExtensions.blur-my-shell
    gnomeExtensions.hot-edge
    gnomeExtensions.gsconnect
    gnomeExtensions.astra-monitor
    gnomeExtensions.night-theme-switcher
    gnomeExtensions.adw-gtk3-colorizer
    gnomeExtensions.grand-theft-focus
    gnomeExtensions.light-style
    gnomeExtensions.accent-directories
    gnomeExtensions.caffeine
    gnomeExtensions.tiling-assistant
    gnomeExtensions.battery-indicator-icon
	gnomeExtensions.hide-top-bar
	gnomeExtensions.power-off-options
	gnomeExtensions.rounded-corners
    gnomeExtensions.display-configuration-switcher
  ];

}
