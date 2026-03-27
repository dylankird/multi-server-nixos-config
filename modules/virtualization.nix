# Virtualization: Podman, libvirtd, virt-manager
{ config, pkgs, ... }:

{
  # KVM/libvirt for headless VM hosting
  virtualisation.libvirtd = {
    enable = true;
    qemu.vhostUserPackages = [ pkgs.virtiofsd ];
  };

  users.groups.libvirtd.members = [ "dylan" ];

  # Podman with Docker compatibility
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
  };

  environment.systemPackages = with pkgs; [
    distrobox
  ];
}
