# Shared core system configuration
{ config, pkgs, ... }:

{
  # Enable flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Automatic garbage collection
  # Not sure if I want this on servers
  # Maybe if I set up auto updates
  /*
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 90d";
  };
  */

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Time zone
  time.timeZone = "America/New_York";

  # Locale settings
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_IE.UTF-8";  # Monday as first day of week
  };

  # User account
  users.users.dylan = {
    isNormalUser = true;
    description = "Dylan Kirdahy";
    extraGroups = [ "networkmanager" "wheel" "plugdev" "input" ];
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Share bash history across all terminals, nix shell subshells, and tmux panes
  programs.bash.interactiveShellInit = ''
    HISTSIZE=100000
    HISTFILESIZE=200000
    HISTCONTROL=ignoredups:erasedups
    shopt -s histappend
    # Sync history after every command so all terminals share one live history
    PROMPT_COMMAND="history -a; history -c; history -r''${PROMPT_COMMAND:+; $PROMPT_COMMAND}"
  '';
}
