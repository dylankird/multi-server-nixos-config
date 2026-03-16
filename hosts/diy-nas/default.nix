# DIY NAS specific configuration

# TODO:
# 

{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  networking.hostName = "diy-nas";

  # Swap file (8GB)
  swapDevices = [{
    device = "/var/lib/swapfile";
    size = 8 * 1024;
  }];

  # Use latest kernel - probably shouldn't do this for compatability reasons
  #boot.kernelPackages = pkgs.linuxPackages_latest;


  # DIY NAS specific packages
  environment.systemPackages = with pkgs; [
	syncthing
  ];

  services.syncthing = {
  enable = true;
  user = "dylan";
  dataDir = "/home/dylan/pool/syncthing";
  guiAddress = "0.0.0.0:8384";
};

networking.firewall.allowedTCPPorts = [ 8384 22000 ];
networking.firewall.allowedUDPPorts = [ 22000 21027 ];

  fileSystems."/home/dylan/pool/nextcloud" = {
  device = "/dev/disk/by-uuid/acb218f0-ce2d-4d6e-8fa6-43c1e1c01470";
  fsType = "btrfs";
  options = [ "subvol=@nextcloud" "compress=zstd" "noatime" ];
};

  fileSystems."/home/dylan/pool/syncthing" = {
  device = "/dev/disk/by-uuid/acb218f0-ce2d-4d6e-8fa6-43c1e1c01470";
  fsType = "btrfs";
  options = [ "subvol=@syncthing" "compress=zstd" "noatime" ];
};

fileSystems."/home/dylan/pool/backups" = {
  device = "/dev/disk/by-uuid/acb218f0-ce2d-4d6e-8fa6-43c1e1c01470";
  fsType = "btrfs";
  options = [ "subvol=@backups" "compress=zstd" "noatime" ];
};

fileSystems."/home/dylan/pool/network-storage" = {
  device = "/dev/disk/by-uuid/acb218f0-ce2d-4d6e-8fa6-43c1e1c01470";
  fsType = "btrfs";
  options = [ "subvol=@network-storage" "compress=zstd" "noatime" ];
};


  system.stateVersion = "25.11";
}
