{
  description = "dod's flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    home-manager.url = "github:nix-community/home-manager/release-25.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    
    stylix = {
      url = "github:danth/stylix/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    catppuccin-sddm = {
      url = "github:catppuccin/sddm";
      flake = false;
    };
    
    # Lanzaboote for Secure Boot
    lanzaboote = {
      url = "github:nix-community/lanzaboote";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    # spicetify-nix
    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    # NixVim
    nixvim = {
      url = "github:nix-community/nixvim";
    };

    # Quickshell
    quickshell = {
      url = "git+https://git.outfoxxed.me/outfoxxed/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, lanzaboote, spicetify-nix, nixvim, stylix, quickshell, ... }:
  let
    lib = nixpkgs.lib;
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
  in {
    nixosConfigurations = {
      nixos = lib.nixosSystem {
        inherit system;
        modules = [ 
          ./configuration.nix
          lanzaboote.nixosModules.lanzaboote 
        ];
      };
    };
    
    homeConfigurations = {
      dod = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        # Passer spicetify-nix aux modules via extraSpecialArgs
        extraSpecialArgs = { 
          inherit spicetify-nix;
          quickshell-pkg = quickshell.packages.${system}.default;
        };
        modules = [ 
          ./home.nix
          nixvim.homeModules.nixvim
          stylix.homeModules.stylix
          # Import du module spicetify-nix
          spicetify-nix.homeManagerModules.default
        ];
      };
    };
  };
}