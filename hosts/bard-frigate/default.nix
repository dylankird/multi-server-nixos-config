# bard-frigate specific configuration

{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  networking.hostName = "bard-frigate";

  swapDevices = [{
    device = "/var/lib/swapfile";
    size = 4 * 1024;
  }];

  fileSystems."/home/dylan/storage" = {
    device = "/dev/disk/by-uuid/18db546c-556b-4824-abf2-c72b66ad5bbc";
    fsType = "btrfs";
    options = [ "subvol=@storage" "compress=zstd" "noatime" ];
  };

  # Coral PCIe — loads gasket kernel module, creates coral group + udev rule for /dev/apex_0
  hardware.coral.pcie.enable = true;

  # Intel UHD 630 VAAPI
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver
      intel-vaapi-driver
      libvdpau-va-gl
    ];
  };

  # Give frigate user access to Coral and GPU
  users.users.frigate.extraGroups = [ "coral" "render" "video" ];

  # Redirect recordings/clips to data disk; DB stays on root SSD (avoids fsync stalls)
  systemd.tmpfiles.rules = [
    "d /home/dylan/storage/frigate            0750 frigate frigate -"
    "d /home/dylan/storage/frigate/recordings 0750 frigate frigate -"
    "d /home/dylan/storage/frigate/clips      0750 frigate frigate -"
  ];

  fileSystems."/var/lib/frigate/recordings" = {
    device  = "/home/dylan/storage/frigate/recordings";
    fsType  = "none";
    options = [ "bind" ];
    depends = [ "/home/dylan/storage" ];
  };

  fileSystems."/var/lib/frigate/clips" = {
    device  = "/home/dylan/storage/frigate/clips";
    fsType  = "none";
    options = [ "bind" ];
    depends = [ "/home/dylan/storage" ];
  };

  # Frigate web UI only reachable on tailnet (nginx on port 80)
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 80 ];

  environment.systemPackages = with pkgs; [
    libva-utils      # vainfo
    intel-gpu-tools  # intel_gpu_top
    ffmpeg-full      # ffprobe for testing RTSP streams
  ];

  services.frigate = {
    enable      = true;
    hostname    = "bard-frigate";
    vaapiDriver = "iHD";
    # checkConfig = false because RTSP URLs contain {FRIGATE_*} env vars that
    # can't be resolved at build time in the Nix sandbox
    checkConfig = false;

    settings = {
      mqtt.enabled = false;
      auth.enabled = false;

      detectors.coral = {
        type   = "edgetpu";
        device = "pci";
      };

      ffmpeg.hwaccel_args = "preset-vaapi";

      record = {
        enabled = true;
        retain  = { days = 10; mode = "all"; };
        events.retain = { default = 30; mode = "motion"; };
      };

      snapshots = {
        enabled        = true;
        retain.default = 14;
      };

      birdseye = { enabled = true; mode = "objects"; };

      cameras.cam1 = {
        ffmpeg.inputs = [
          { path  = "rtsp://{FRIGATE_CAM1_USER}:{FRIGATE_CAM1_PASSWORD}@192.168.1.114:554/h264Preview_01_main";
            roles = [ "record" ]; }
          { path  = "rtsp://{FRIGATE_CAM1_USER}:{FRIGATE_CAM1_PASSWORD}@192.168.1.114:554/h264Preview_01_sub";
            roles = [ "detect" ]; }
        ];
        detect  = { enabled = true; width = 640; height = 480; fps = 5; };
        objects.track = [ "person" "car" "dog" "cat" ];
      };
    };
  };

  # Camera credentials — file created manually on host, not in git
  systemd.services.frigate.serviceConfig = {
    EnvironmentFile = "/var/lib/frigate/.env";
    # Ensure storage dirs are owned by frigate before each start.
    # The bind-mount activation creates these as root, so we fix ownership here.
    ExecStartPre = [
      "+${pkgs.coreutils}/bin/chown -R frigate:frigate /home/dylan/storage/frigate"
    ];
  };

  system.stateVersion = "25.11";
}
