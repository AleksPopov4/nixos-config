{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];
  
  #disko.devices.disk.main.device = "/dev/sda";

  virtualisation.vmVariantWithDisko = {
    virtualisation.fileSystems."/".neededForBoot = true;
    virtualisation.memorySize = 2048;
    virtualisation.diskSize = 102400;
  };

  # disko.tests.extraConfig = {
  #   ImageSize = "100G";
  # };

  # Basic system configuration for testing in a VM
  #boot.loader.grub = {
  #  enable = true;
  #  version = 2;
  #  device = "/dev/sda"; # Install GRUB on the primary disk
  #};

  # Networking
  networking.hostName = "disko-test-vm"; # Set a hostname for testing
  networking.useDHCP = true;
  networking.hostId = "e4d32f76";

  # Enable SSH for testing purposes
  services.openssh.enable = true;

  # Set a simple user for testing
  users.users.test = {
    isNormalUser = true;
    password = "test"; # Use a simple password (not secure for production)
    extraGroups = [ "wheel" ]; # Allow sudo access
  };

  # Configure the system timezone and locale
  time.timeZone = "UTC";
  i18n.defaultLocale = "en_US.UTF-8";

  # Set up a basic environment with minimal packages
  environment.systemPackages = with pkgs; [
    vim
    git
    htop
    curl
  ];

  # Nix configuration for garbage collection (optional)
  nix.settings = {
    auto-optimise-store = true;
    experimental-features = [ "nix-command" "flakes" ];
  };

  # Enable networking in the VM
  networking.firewall.enable = false;

  # Enable a basic systemd service for testing
  systemd.services.test-service = {
    enable = true;
    description = "A test service for VM Disko setup";
    script = ''
      echo "Disko VM Test is running" > /tmp/test-service.log
    '';
    serviceConfig = {
      Type = "oneshot";
    };
  };

  # Virtualization and testing environment
  #virtualisation.virtualbox.guest.enable = true;

  # Allow unfree packages if needed
  nixpkgs.config.allowUnfree = true;

  # System state version
  system.stateVersion = "24.05"; # Change to match your NixOS version
}
