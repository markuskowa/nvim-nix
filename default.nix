{
  pkgs ? import <nixpkgs> {}
, system ? builtins.currentSystem
} :

let
  lockFile = with builtins; (fromJSON (readFile ./flake.lock)).nodes;
  # tested nixpgks-unstable version
  nixpkgs' = lockFile.nixpkgs.locked;
  nix2nvimrc' = lockFile.nix2nvimrc.locked;

  nixpkgs = import (pkgs.fetchFromGitHub {
    inherit (nixpkgs') owner repo rev;
    sha256 = nixpkgs'.narHash;
  }) {};

  nix2nvimrc = import "${(pkgs.fetchFromGitHub {
    inherit (nix2nvimrc') owner repo rev;
    sha256 = nix2nvimrc'.narHash;
  })}/lib.nix";

  adminLanguages = [ "nix" "yaml" "bash" "markdown" "json" "toml" ];
  nvim = with nixpkgs; name: languages: runCommandLocal "nvim"
    { nativeBuildInputs = [ makeWrapper ]; }
    ''
      makeWrapper ${neovim-unwrapped}/bin/nvim $out/bin/nvim \
        --add-flags "-u ${nixpkgs.writeText ("nvimrc-" + name) (nix2nvimrc.toRc nixpkgs { inherit languages; imports = [ ./config.nix ];})}"
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

in packages
