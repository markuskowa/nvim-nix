{
  description = "Nvim";

  inputs = {
    ck3d-configs.url = "github:ck3d/ck3d-nvim-configs";
  };

  outputs = { self, ck3d-configs }:
    let
      inherit (ck3d-configs.inputs) nixpkgs nix2nvimrc;
      inherit (nixpkgs) lib;
      inherit (ck3d-configs.lib lib) readDirNix;

      forAllSystems = lib.genAttrs lib.systems.flakeExposed;
      nix2nvimrcConfigs = readDirNix ./configs
        // {
        inherit (ck3d-configs.nix2nvimrcConfigs)
          Comment
          toggleterm
          leader
          registers
          vim-speeddating
          lspconfig
          lsp-status
          cmp
          nvim-treesitter
          ;
      };
    in
    {
      inherit nix2nvimrcConfigs;

      packages = forAllSystems
        (system:
          let
            pkgs = nixpkgs.legacyPackages.${system};

            nvims = builtins.mapAttrs
              (name: languages: (lib.evalModules {
                modules =
                  (nix2nvimrc.lib.modules pkgs)
                  ++ (builtins.attrValues ck3d-configs.nix2nvimrcModules)
                  ++ (builtins.attrValues nix2nvimrcConfigs)
                  ++ [{
                    wrapper.name = name;
                    inherit languages;
                  }];
              }).config.wrapper.drv)
              rec {
                nvim-admin = [ "nix" "yaml" "bash" "markdown" "json" "toml" ];
                nvim-dev = nvim-admin ++ [
                  "beancount"
                  "c"
                  "cpp"
                  "make"
                  "python"
                ];
              };
          in
          nvims // { default = nvims.nvim-admin; });
    };
}
