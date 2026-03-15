# Framework specific configuration

# TODO:
# 

{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  networking.hostName = "framework";

  # Swap file (64GB for unified memory as VRAM)
  swapDevices = [{
    device = "/var/lib/swapfile";
    size = 64 * 1024;
  }];

  # Use latest kernel - probably shouldn't do this for compatability reasons
  #boot.kernelPackages = pkgs.linuxPackages_latest;


  # Framework specific packages
  environment.systemPackages = with pkgs; [
	lmstudio
  ];

  system.stateVersion = "25.11";
}
