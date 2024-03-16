{ pkgs, ... }:
{
  configs.lightspeed = {
    plugins = [ pkgs.vimPlugins.lightspeed-nvim ];
    setup = { };
  };
}
