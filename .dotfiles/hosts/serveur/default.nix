{ config, lib, pkgs, ... }:

let
  # À adapter
  tailnet = "tail5f7944.ts.net";          # ex: tail1234.ts.net (visible dans l'admin Tailscale)
  sshKey  = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOl5q2GNDioN3kITcJP0840GzEUEgD7fHQBf0W1wzN1S dod250amp@proton.me";
in
{
  imports = [ ./hardware-configuration.nix ];

  # ───────────── Boot ─────────────
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 20;
  boot.loader.efi.canTouchEfiVariables = true;

  # ───────────── Système ─────────────
  networking.hostName = "serveur";
  time.timeZone = "Europe/Paris";
  i18n.defaultLocale = "fr_FR.UTF-8";
  console.keyMap = "fr";

  zramSwap.enable = true;

  environment.systemPackages = with pkgs; [
    git
    vim
    htop
    btrfs-progs
    compsize   # pour voir le gain de compression btrfs
  ];

  # ───────────── Nix ─────────────
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
    trusted-users = [ "root" "@wheel" ];
  };
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  # ───────────── Utilisateurs & SSH ─────────────
  users.users.dod = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [ sshKey ];
  };
  users.users.root.openssh.authorizedKeys.keys = [ sshKey ];

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "prohibit-password";
    };
  };

  # ───────────── Réseau : tout passe par Tailscale ─────────────
  services.tailscale = {
    enable = true;
    useRoutingFeatures = "server";
  };

  networking.firewall = {
    enable = true;
    trustedInterfaces = [ "tailscale0" ];
    allowedTCPPorts = [ 22 ];
    allowedUDPPorts = [ config.services.tailscale.port ];
  };

  # ───────────── Disque de données (HDD btrfs) ─────────────
  # mkForce : remplace les options du hardware-configuration au lieu de les dupliquer
  fileSystems."/data/immich".options =
    lib.mkForce [ "subvol=immich" "noatime" "compress=zstd" ];
  fileSystems."/data/.snapshots".options =
    lib.mkForce [ "subvol=snapshots" "noatime" ];

  services.btrfs.autoScrub = {
    enable = true;
    interval = "monthly";
    fileSystems = [ "/data/immich" ];
  };

  # ───────────── Immich ─────────────
  services.immich = {
    enable = true;
    host = "0.0.0.0";
    port = 2283;
    mediaLocation = "/data/immich";
    # accelerationDevices = null;  # décommente pour donner accès à /dev/dri (iGPU)
  };

  # Ne pas démarrer Immich si le HDD n'est pas monté
  systemd.services.immich-server.unitConfig.RequiresMountsFor = [ "/data/immich" ];

  # ───────────── Dashboard : Homepage ─────────────
  services.homepage-dashboard = {
    enable = true;
    listenPort = 8082;
    allowedHosts = "localhost:8082,serveur:8082,serveur.${tailnet}:8082";

    # Fichier à créer à la main sur le serveur (chmod 600) :
    #   HOMEPAGE_VAR_IMMICH_KEY=<clé API créée dans Immich>
    environmentFile = "/var/lib/secrets/homepage.env";

    settings = {
      title = "Serveur";
      language = "fr";
      theme = "dark";
    };

    widgets = [
      { resources = { cpu = true; memory = true; uptime = true; }; }
      { resources = { label = "Système"; disk = "/"; }; }
      { resources = { label = "Données"; disk = "/data/immich"; }; }
    ];

    services = [
      {
        "Médias" = [
          {
            "Immich" = {
              href = "https://serveur.${tailnet}";
              description = "Photos";
              icon = "immich.png";
              widget = {
                type = "immich";
                url = "http://localhost:2283";
                key = "{{HOMEPAGE_VAR_IMMICH_KEY}}";
                version = 2;
              };
            };
          }
        ];
      }
    ];
  };

  # Ne change jamais cette valeur après l'installation
  system.stateVersion = "26.05";
}
