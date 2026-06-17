# bard-frigate specific configuration

# TODO:
# 

{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  networking.hostName = "bard-frigate";

  # Swap file (4GB)
  swapDevices = [{
    device = "/var/lib/swapfile";
    size = 4 * 1024;
  }];

  # Use latest kernel - probably shouldn't do this for compatability reasons
  #boot.kernelPackages = pkgs.linuxPackages_latest;

  fileSystems."/home/dylan/storage" = {
    device = "/dev/disk/by-uuid/18db546c-556b-4824-abf2-c72b66ad5bbc";
    fsType = "btrfs";
    options = [ "subvol=@storage" "compress=zstd" "noatime" ];
  };


  # bard-frigate specific packages
  environment.systemPackages = with pkgs; [

  ];

  system.stateVersion = "25.11";
}
