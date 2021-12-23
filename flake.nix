{
  description = "Nvim";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable-small";
    nix2nvimrc.url = "github:ck3d/nix2nvimrc";
    utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, utils, nix2nvimrc }:
    utils.lib.eachDefaultSystem (system:
      let
        nixpkgs' = import nixpkgs { inherit system; };
        adminLanguages = [ "nix" "yaml" "bash" "markdown" "json" "toml" ];
        nvim = with nixpkgs'; name: languages: runCommandLocal
          "nvim"
          { nativeBuildInputs = [ makeWrapper ]; }
          ''
            makeWrapper ${neovim-unwrapped}/bin/nvim $out/bin/nvim \
              --add-flags "-u ${nixpkgs'.writeText ("nvimrc-" + name) (nix2nvimrc.lib.toRc nixpkgs' { inherit languages; imports = [ ./config.nix ];})}"
          '';
        packages = builtins.mapAttrs nvim {
          admin = adminLanguages;
          dev = adminLanguages ++ [
            # treesitter
            "beancount"
            "c"
            "cpp"
            "make"
            "python"
          ];
        };
      in
      {
        inherit packages;
        defaultPackage = packages.admin;
      });
}
