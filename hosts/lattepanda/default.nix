# lattepanda specific configuration

# TODO:
# 

{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  networking.hostName = "lattepanda";

  # Swap file (8GB)
  swapDevices = [{
    device = "/var/lib/swapfile";
    size = 8 * 1024;
  }];

  # Use latest kernel - probably shouldn't do this for compatability reasons
  #boot.kernelPackages = pkgs.linuxPackages_latest;


  # LattePanda specific packages
  environment.systemPackages = with pkgs; [

  ];

  system.stateVersion = "25.11";
}
