# This module is just for temporarily sending SSH keys
# DO NOT USE IN PRODUCTION
{ config, pkgs, ... }:

{
  # Networking with iwd for WiFi
  networking.networkmanager.enable = true;
  networking.networkmanager.wifi.backend = "iwd";
  networking.wireless.iwd.enable = true;

  # SSH - key-based auth only, no root login
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = true;
      KbdInteractiveAuthentication = true;
      PermitRootLogin = "no";
    };
  };

  # Firewall - allow SSH and KDE Connect / GSConnect ports
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 ];
  };

  # Configure tailscale:
  # Be sure to run  "sudo tailscale up --auth-key=KEY" with the key generated at https://login.tailscale.com/admin/machines/new-linux
  services.tailscale.enable = true;
}
