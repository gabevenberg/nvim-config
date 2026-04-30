{
  description = "Flake exporting a configured neovim package";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    wrappers = {
      url = "github:BirdeeHub/nix-wrapper-modules";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    plugins-lze = {
      url = "github:BirdeeHub/lze";
      flake = false;
    };
    plugins-lzextras = {
      url = "github:BirdeeHub/lzextras";
      flake = false;
    };
  };
  outputs = {
    self,
    nixpkgs,
    wrappers,
    treefmt-nix,
    ...
  } @ inputs: let
    forAllSystems = function:
      nixpkgs.lib.genAttrs [
        "x86_64-linux"
        "aarch64-linux"
      ] (system:
        function {
          pkgs = import nixpkgs {inherit system;};
          inherit system;
        });

    treefmtEval = forAllSystems ({pkgs, ...}: treefmt-nix.lib.evalModule pkgs ./treefmt.nix);
    module = nixpkgs.lib.modules.importApply ./module.nix inputs;
    wrapper = wrappers.lib.evalModule module;
  in {
    formatter = forAllSystems ({system, ...}: treefmtEval.${system}.config.build.wrapper);

    overlays = {
      neovim = final: prev: {neovim = wrapper.config.wrap {pkgs = final;};};
      default = self.overlays.neovim;
    };
    wrapperModules = {
      neovim = module;
      default = self.wrapperModules.neovim;
    };
    wrappers = {
      neovim = wrapper.config;
      default = self.wrappers.neovim;
    };
    packages = forAllSystems (
      {pkgs, system}: {
        neovim = wrapper.config.wrap {inherit pkgs;};
        minimal = wrapper.config.wrap {
          settings.minimal = true;
          inherit pkgs;
        };
        default = self.packages.${system}.neovim;
      }
    );
    # `wrappers.neovim.enable = true`
    nixosModules = {
      default = self.nixosModules.neovim;
      neovim = wrappers.lib.mkInstallModule {
        name = "neovim";
        value = module;
      };
    };
    # `wrappers.neovim.enable = true`
    # You can set any of the options.
    # But that is how you enable it.
    homeModules = {
      default = self.homeModules.neovim;
      neovim = wrappers.lib.mkInstallModule {
        name = "neovim";
        value = module;
        loc = [
          "home"
          "packages"
        ];
      };
    };
  };
}
