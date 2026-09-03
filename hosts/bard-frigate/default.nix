# bard-frigate specific configuration

# Note: Edit secrets with: 'sudo vim /var/lib/frigate/.env'

# Masks/zones drawn in the Frigate web UI live in a tmpfs config copy and
# get wiped on every frigate.service restart (see masks-zones.json below).
# After editing masks/zones in the UI, run ./sync-masks-zones.sh (on
# bard-frigate itself, e.g. over ssh) to pull them into masks-zones.json,
# review the git diff, and commit — that file is merged into the camera
# configs below and is what makes the masks/zones survive
# `nixos-rebuild switch`. It's a generated file; don't hand-edit it.

{ config, pkgs, lib, ... }:

let
  masksZonesFile = ./masks-zones.json;
  masksZones =
    if builtins.pathExists masksZonesFile
    then builtins.fromJSON (builtins.readFile masksZonesFile)
    else { };

  # Merges live-captured motion/zone/object-filter masks (produced by
  # ./sync-masks-zones.sh, committed to git) on top of a camera's base
  # config. No-ops before the first sync has ever been run.
  withMasks = cameraName: baseConfig:
    lib.recursiveUpdate baseConfig (masksZones.${cameraName} or { });
in

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
    # Frigate's log API reads from this path (s6-overlay creates it in Docker; we do it here)
    "d /dev/shm/logs/frigate 0755 frigate frigate -"
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

      # go2rtc.streams here is UI-only — tells the live view tab that restreaming
      # is available. The actual streams are configured in services.go2rtc below.
      go2rtc.streams.street = [
        "rtsp://{FRIGATE_STREET_USER}:{FRIGATE_STREET_PASSWORD}@192.168.1.114:554/h264Preview_01_main"
      ];
      go2rtc.streams.street_sub = [
        "rtsp://{FRIGATE_STREET_USER}:{FRIGATE_STREET_PASSWORD}@192.168.1.114:554/h264Preview_01_sub"
      ];

      go2rtc.streams.front = [
        "rtsp://{FRIGATE_FRONT_USER}:{FRIGATE_FRONT_PASSWORD}@192.168.1.111:554/h264Preview_01_main"
      ];
      go2rtc.streams.front_sub = [
        "rtsp://{FRIGATE_FRONT_USER}:{FRIGATE_FRONT_PASSWORD}@192.168.1.111:554/h264Preview_01_sub"
      ];

      go2rtc.streams.side = [
        "rtsp://{FRIGATE_SIDE_USER}:{FRIGATE_SIDE_PASSWORD}@192.168.1.113:554/h264Preview_01_main"
      ];
      go2rtc.streams.side_sub = [
        "rtsp://{FRIGATE_SIDE_USER}:{FRIGATE_SIDE_PASSWORD}@192.168.1.113:554/h264Preview_01_sub"
      ];

      go2rtc.streams.back = [
        "rtsp://{FRIGATE_BACK_USER}:{FRIGATE_BACK_PASSWORD}@192.168.1.112:554/h264Preview_01_main"
      ];
      go2rtc.streams.back_sub = [
        "rtsp://{FRIGATE_BACK_USER}:{FRIGATE_BACK_PASSWORD}@192.168.1.112:554/h264Preview_01_sub"
      ];

      detectors.coral = {
        type   = "edgetpu";
        device = "pci";
      };

      ffmpeg.hwaccel_args = "preset-vaapi";

      record = {
        enabled = true;
        retain  = { days = 10; mode = "all"; };
        # Effectively unlimited: motion-tagged events are kept until the disk
        # fills up. Frigate auto-deletes the oldest recordings once free space
        # drops below ~1 hour, regardless of this retention value.
        events.retain = { default = 10000; mode = "motion"; };
      };

      snapshots = {
        enabled        = true;
        retain.default = 14;
      };

      birdseye = { enabled = true; mode = "objects"; };

      cameras.street = withMasks "street" {
        # Pull from go2rtc's RTSP restream rather than directly from the camera.
        # This means go2rtc holds the single connection to the camera; live view
        # and recording both use the same already-open stream with no duplication.
        ffmpeg.inputs = [
          { path  = "rtsp://127.0.0.1:8554/street";
            roles = [ "record" ]; }
          { path  = "rtsp://127.0.0.1:8554/street_sub";
            roles = [ "detect" ]; }
        ];
        detect  = { enabled = true; width = 640; height = 480; fps = 5; };
        objects.track = [ "person" "car" "dog" "cat" ];
      };

      cameras.front = withMasks "front" {
        # Pull from go2rtc's RTSP restream rather than directly from the camera.
        # This means go2rtc holds the single connection to the camera; live view
        # and recording both use the same already-open stream with no duplication.
        ffmpeg.inputs = [
          { path  = "rtsp://127.0.0.1:8554/front";
            roles = [ "record" ]; }
          { path  = "rtsp://127.0.0.1:8554/front_sub";
            roles = [ "detect" ]; }
        ];
        detect  = { enabled = true; width = 640; height = 480; fps = 5; };
        objects.track = [ "person" "car" "dog" "cat" ];
      };

	  cameras.side= withMasks "side" {
        # Pull from go2rtc's RTSP restream rather than directly from the camera.
        # This means go2rtc holds the single connection to the camera; live view
        # and recording both use the same already-open stream with no duplication.
        ffmpeg.inputs = [
          { path  = "rtsp://127.0.0.1:8554/side";
            roles = [ "record" ]; }
          { path  = "rtsp://127.0.0.1:8554/side_sub";
            roles = [ "detect" ]; }
        ];
        detect  = { enabled = true; width = 640; height = 480; fps = 5; };
        objects.track = [ "person" "car" "dog" "cat" ];
      };

      cameras.back = withMasks "back" {
        # Pull from go2rtc's RTSP restream rather than directly from the camera.
        # This means go2rtc holds the single connection to the camera; live view
        # and recording both use the same already-open stream with no duplication.
        ffmpeg.inputs = [
          { path  = "rtsp://127.0.0.1:8554/back";
            roles = [ "record" ]; }
          { path  = "rtsp://127.0.0.1:8554/back_sub";
            roles = [ "detect" ]; }
        ];
        detect  = { enabled = true; width = 640; height = 480; fps = 5; };
        objects.track = [ "person" "car" "dog" "cat" ];
      };

    };
  };

  # go2rtc holds the single connection to the camera; Frigate ffmpeg and live view
  # both consume its RTSP restream. Streams use ${VAR} substitution (go2rtc native).
  services.go2rtc = {
    enable = true;
    settings = {
      api.listen = "127.0.0.1:1984";

      streams.street = [
        "rtsp://\${FRIGATE_STREET_USER}:\${FRIGATE_STREET_PASSWORD}@192.168.1.114:554/h264Preview_01_main"
      ];
      streams.street_sub = [
        "rtsp://\${FRIGATE_STREET_USER}:\${FRIGATE_STREET_PASSWORD}@192.168.1.114:554/h264Preview_01_sub"
      ];

      streams.front = [
        "rtsp://\${FRIGATE_FRONT_USER}:\${FRIGATE_FRONT_PASSWORD}@192.168.1.111:554/h264Preview_01_main"
      ];
      streams.front_sub = [
        "rtsp://\${FRIGATE_FRONT_USER}:\${FRIGATE_FRONT_PASSWORD}@192.168.1.111:554/h264Preview_01_sub"
      ];
	  
      streams.side = [
        "rtsp://\${FRIGATE_SIDE_USER}:\${FRIGATE_SIDE_PASSWORD}@192.168.1.113:554/h264Preview_01_main"
      ];
      streams.side_sub = [
        "rtsp://\${FRIGATE_SIDE_USER}:\${FRIGATE_SIDE_PASSWORD}@192.168.1.113:554/h264Preview_01_sub"
      ];

      streams.back = [
        "rtsp://\${FRIGATE_BACK_USER}:\${FRIGATE_BACK_PASSWORD}@192.168.1.112:554/h264Preview_01_main"
      ];
      streams.back_sub = [
        "rtsp://\${FRIGATE_BACK_USER}:\${FRIGATE_BACK_PASSWORD}@192.168.1.112:554/h264Preview_01_sub"
      ];

    };
  };

  # go2rtc must run as frigate user to read credentials from the shared env file
  systemd.services.go2rtc.serviceConfig = {
    DynamicUser    = lib.mkForce false;
    User           = lib.mkForce "frigate";
    Group          = lib.mkForce "frigate";
    EnvironmentFile = "/var/lib/frigate/.env";
  };

  systemd.services.frigate.serviceConfig = {
    EnvironmentFile = "/var/lib/frigate/.env";
    ExecStartPre = [
      "+${pkgs.coreutils}/bin/chown -R frigate:frigate /home/dylan/storage/frigate"
    ];
    # Route logs to the file Frigate's web UI log viewer expects
    StandardOutput = lib.mkForce "append:/dev/shm/logs/frigate/current";
    StandardError  = lib.mkForce "append:/dev/shm/logs/frigate/current";
  };

  system.stateVersion = "25.11";
}
