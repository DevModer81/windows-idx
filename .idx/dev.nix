{ pkgs, ... }:

{
  packages = with pkgs; [
    qemu_full
    curl
    wget
    git
    sudo
    apt
  ];

  env = {
    QEMU_AUDIO_DRV = "none";
  };
}
