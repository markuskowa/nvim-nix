{ pkgs, ... }:
{
  configs = {
    global = {
      plugins = [
        pkgs.vimPlugins.lush-nvim
      ];
      after = [ "leader" ];
      opts = {
        laststatus = 2;
        updatetime = 100;
        showmode = false;
        hlsearch = true;
        incsearch = true;
        compatible = false;
        expandtab = true;
        tabstop = 2;
        sw = 2;
        cindent = true;
        backspace = "indent,eol,start";
        undofile = true;
        signcolumn = "yes";
        termguicolors = true;
      };
      vim = [
        ''
          autocmd FileType c,cpp  set formatoptions=croql cindent comments=sr:/*,mb:*,ex:*/,://
          autocmd BufWritePre * %s/\s\+$//e
        ''
      ];
    };
  };
}

