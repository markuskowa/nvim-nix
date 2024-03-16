{ pkgs, ... }:
{
  configs.gitsigns = {
    plugins = [ pkgs.vimPlugins.gitsigns-nvim ];
    setup.args = {
      signs.add.text = "+";
      signs.change.text = "~";
      signs.changedelete.text = "c~";
    };
  };
}
