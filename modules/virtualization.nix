# Virtualization: Podman, libvirtd, virt-manager
{ config, pkgs, ... }:

{
  # virt-manager and KVM for GNOME Boxes
  programs.virt-manager.enable = true;
  users.groups.libvirtd.members = [ "dylan" ];
  virtualisation.libvirtd.enable = true;
  virtualisation.spiceUSBRedirection.enable = true;

  # Podman with Docker compatibility
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
  };

  environment.systemPackages = with pkgs; [
    distrobox
    gnome-boxes
  ];
}
