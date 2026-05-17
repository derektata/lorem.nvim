{
  description = "lorem.nvim — Neovim plugin dev environment";

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

      # Boots Neovim with the plugin loaded from the current working directory.
      # Equivalent to: nvim -u minimal.vim
      nvimDev = pkgs.writeShellScriptBin "nvim-lorem" ''
        exec ${pkgs.neovim}/bin/nvim \
          --clean \
          -c "set rtp^=$PWD" \
          -c "lua require('lorem')" \
          "$@"
      '';
      loremNvim = pkgs.vimUtils.buildVimPlugin {
        pname = "lorem-nvim";
        version = "unstable";
        src = ./.;
      };
    in {
      packages.default = loremNvim;

      devShells.default = pkgs.mkShell {
        buildInputs = [
          pkgs.neovim
          pkgs.stylua
          pkgs.luajitPackages.luacheck
          pkgs.lua-language-server
          pkgs.git
          nvimDev
        ];
      };

      apps.default = {
        type = "app";
        program = "${nvimDev}/bin/nvim-lorem";
      };

    });
}
