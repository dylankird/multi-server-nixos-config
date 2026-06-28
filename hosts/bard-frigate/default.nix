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
      # auth enabled — all requests were getting viewer role with it disabled.
      # On first load after this change, Frigate will prompt to create an admin user.

      # Frigate configures go2rtc with these streams via API at startup.
      # Having cam1 here also tells the UI that live view restreaming is available.
      go2rtc.streams.cam1 = [
        "rtsp://{FRIGATE_CAM1_USER}:{FRIGATE_CAM1_PASSWORD}@192.168.1.114:554/h264Preview_01_main"
      ];
      go2rtc.streams.cam1_sub = [
        "rtsp://{FRIGATE_CAM1_USER}:{FRIGATE_CAM1_PASSWORD}@192.168.1.114:554/h264Preview_01_sub"
      ];

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
        # Pull from go2rtc's RTSP restream rather than directly from the camera.
        # This means go2rtc holds the single connection to the camera; live view
        # and recording both use the same already-open stream with no duplication.
        ffmpeg.inputs = [
          { path  = "rtsp://127.0.0.1:8554/cam1";
            roles = [ "record" ]; }
          { path  = "rtsp://127.0.0.1:8554/cam1_sub";
            roles = [ "detect" ]; }
        ];
        detect  = { enabled = true; width = 640; height = 480; fps = 5; };
        objects.track = [ "person" "car" "dog" "cat" ];
      };
    };
  };

  # go2rtc provides the process; Frigate configures its streams via API at startup
  services.go2rtc = {
    enable = true;
    settings.api.listen = "127.0.0.1:1984";
  };

  systemd.services.frigate.serviceConfig = {
    # Frigate needs the env file to substitute {FRIGATE_*} vars before passing
    # camera URLs to go2rtc's API and to ffmpeg
    EnvironmentFile = "/var/lib/frigate/.env";
    # Ensure storage dirs are owned by frigate before each start.
    # The bind-mount activation creates these as root, so we fix ownership here.
    ExecStartPre = [
      "+${pkgs.coreutils}/bin/chown -R frigate:frigate /home/dylan/storage/frigate"
    ];
  };

  system.stateVersion = "25.11";
}
