{ pkgs, nix2nvimrc, ... }:
{
  configs = {
    telescope = {
      plugins = [ pkgs.vimPlugins.telescope-fzy-native-nvim ];
      setup = { };
      lua = [
        "require'telescope'.load_extension('fzy_native')"
      ];
      # https://github.com/nvim-telescope/telescope.nvim/blob/master/lua/telescope/mappings.lua
      keymaps = map (nix2nvimrc.toKeymap { silent = true; }) [
        [ "n" "<Leader>ff" "<Cmd>Telescope find_files<CR>" { } ]
        [ "n" "<Leader>fF" "<Cmd>Telescope git_files<CR>" { } ]
        [ "n" "<Leader>fg" "<Cmd>Telescope live_grep<CR>" { } ]
        [ "n" "<Leader>fq" "<Cmd>Telescope quickfix<CR>" { } ]
        [ "n" "<Leader>gs" "<Cmd>Telescope git_status<CR>" { } ]
      ];
    };
  };
}
