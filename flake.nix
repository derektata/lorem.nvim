{
  description = "A very basic Neovim dev environment flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};

      buildInputs = [
        pkgs.neovim
        pkgs.lua
        pkgs.luajitPackages.luarocks-nix
        pkgs.git
        pkgs.stylua
      ];

      neovimClean = pkgs.writeShellScriptBin "neovim-clean" ''
        exec ${pkgs.neovim}/bin/nvim --clean "$@"
      '';
    in {
      wrappers = {
        neovimClean = neovimClean;
      };

      devShells = {
        default = pkgs.mkShell {
          buildInputs = buildInputs;
        };
      };

      apps = {
        neovim = {
          type = "app";
          program = "${neovimClean}/bin/neovim-clean";
        };
      };
    });
}
