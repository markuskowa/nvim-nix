{ pkgs, nix2nvimrc, ... }:
let
  inherit (nix2nvimrc) luaExpr;
in
{
  configs.lualine = {
    plugins = [ pkgs.vimPlugins.lualine-nvim ];
    setup.args = {
      sections = {
        lualine_a = [ "mode" ];
        lualine_b = [
          "branch"
          (luaExpr "{'diagnostics', sources={'nvim_diagnostic'}}")
        ];
        lualine_c = [ (luaExpr "{'filename', path = 1}") ];
        lualine_x = [
          "diff"
          "filetype"
        ];
        lualine_y = [ "progress" ];
        lualine_z = [ "location" ];
      };
      options = { theme = "powerline"; };
    };
  };
}

