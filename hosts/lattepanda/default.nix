# lattepanda specific configuration

# TODO:
# 

{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  networking.hostName = "lattepanda";

  # Use latest kernel - probably shouldn't do this for compatability reasons
  #boot.kernelPackages = pkgs.linuxPackages_latest;


  # DIY NAS specific packages
  environment.systemPackages = with pkgs; [

  ];

  system.stateVersion = "25.11";
}
