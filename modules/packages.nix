# Shared packages across all machines
{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # Terminal programs
    btop
    git
    appimage-run
    steam-run
    usbutils
	pciutils
	tmux
	tree
	fastfetch
	claude-code
	smartmontools
	lm_sensors
	python3
	nmap
	cowsay
	ncdu
	tailscale
	gptfdisk
	curl
	jq
	yq-go

	# Vim with vimrc:
	(vim-full.customize {
    	vimrcConfig.customRC = builtins.readFile ../vimrc;
    })
  ];
}
