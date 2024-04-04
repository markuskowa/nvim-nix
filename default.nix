# Compat mode, pull in pkgs from flake
(builtins.getFlake "github:markuskowa/nvim-nix").outputs.packages.x86_64-linux
