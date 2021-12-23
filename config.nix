{ config, pkgs, lib, nix2nvimrc, ... }:
let
  inherit (nix2nvimrc) luaExpr;
  hasLang = lang: builtins.any (i: i == lang) config.languages;
  silent_noremap = nix2nvimrc.toKeymap { noremap = true; silent = true; };
in
{
  imports = [
    {
      options = with lib; {
        languages = mkOption {
          type = types.listOf types.str;
          default = [ ];
        };
      };
    }
  ];

  configs = {
    ${builtins.concatStringsSep "-" ([ "languages" ] ++ config.languages)} = {
      treesitter.languages = builtins.filter
        (type: builtins.hasAttr "tree-sitter-${type}" config.treesitter.grammars)
        config.languages;
    };
    global = {
      plugins = with pkgs.vimPlugins; [
        vim-speeddating # CTRL-A/CTRL-X on dates
        registers-nvim
      ]
      ++ lib.optional (hasLang "beancount" && pkgs.stdenv.hostPlatform.system != "aarch64-darwin") vim-beancount
      ++ lib.optional (hasLang "jq") jq-vim
      ;
      opts = {
        laststatus = 2;
        updatetime = 100;
        showmode = false;
        hlsearch = true;
        incsearch = true;
        compatible = false;
        sw = 2;
        cindent = true;
        backspace = "indent,eol,start";
        undofile = true;
        signcolumn = "yes";
        termguicolors = true;
      };
      vars = {
        mapleader = " ";
      };
    };

    gitsigns = {
      plugins = with pkgs.vimPlugins; [ gitsigns-nvim ];
      setup.args = {
        signs.add.text = "+";
        signs.change.text = "~";
        signs.changedelete.text = "c~";
      };
    };
    Comment = {
      plugins = with pkgs.vimPlugins; [ comment-nvim ];
      setup = { };
    };
    toggleterm = {
      plugins = with pkgs.vimPlugins; [ toggleterm-nvim ];
      setup.args = {
        open_mapping = "<c-t>";
        shade_terminals = true;
      };
    };
    telescope = {
      plugins = with pkgs.vimPlugins; [ telescope-fzy-native-nvim ];
      # https://github.com/nvim-telescope/telescope.nvim/blob/master/lua/telescope/mappings.lua
      setup = { };
      lua = [
        "require'telescope'.load_extension('fzy_native')"
      ];
      keymaps = map silent_noremap [
        [ "n" "<Leader>ff" "<Cmd>Telescope find_files<CR>" { } ]
        [ "n" "<Leader>fF" "<Cmd>Telescope git_files<CR>" { } ]
        [ "n" "<Leader>fg" "<Cmd>Telescope live_grep<CR>" { } ]
        [ "n" "<Leader>fq" "<Cmd>Telescope quickfix<CR>" { } ]
        [ "n" "<Leader>gs" "<Cmd>Telescope git_status<CR>" { } ]
      ];
    };
    nvim-treesitter = {
      plugins = with pkgs.vimPlugins; [ nvim-treesitter playground ];
      setup.modulePath = "nvim-treesitter.configs";
      setup.args = {
        highlight.enable = true;
        incremental_selection.enable = true;
        textobjects.enable = true;
        playground.enable = true;
      };
    };
    lualine = {
      plugins = with pkgs.vimPlugins; [ lualine-nvim ];
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
        options = { theme = "gruvbox_dark"; };
      };
    };
    cmp = {
      plugins = with pkgs.vimPlugins; [
        nvim-cmp
        cmp-buffer
        cmp-path
        cmp-treesitter
        cmp-nvim-lsp
        cmp-spell
        cmp-vsnip
        vim-vsnip
      ];
      setup.args = {
        snippet = {
          expand = luaExpr "function(args) vim.fn['vsnip#anonymous'](args.body) end";
        };
        sources = [
          { name = "vsnip"; }
          { name = "nvim_lsp"; }
          { name = "treesitter"; }
          { name = "path"; keyword_length = 2; }
          { name = "buffer"; keyword_length = 4; }
          { name = "spell"; keyword_length = 4; }
        ];
      };
    };
    lightspeed = {
      plugins = with pkgs.vimPlugins; [ lightspeed-nvim ];
      setup = { };
    };
    null-ls = {
      after = [ "gitsigns" ];
      plugins = with pkgs.vimPlugins; [ null-ls-nvim ];
      setup.args = {
        sources = map (s: luaExpr ("require'null-ls.builtins'." + s)) (
          [
            "formatting.prettier.with({command = '${pkgs.nodePackages.prettier}/bin/prettier'})"
          ]
          ++ lib.optionals (hasLang "bash") [
            "code_actions.shellcheck.with({command = '${pkgs.shellcheck}/bin/shellcheck'})"
            "diagnostics.shellcheck.with({command = '${pkgs.shellcheck}/bin/shellcheck'})"
          ]
        );
      };
    };
    nix-lspconfig = {
      after = [
        "global"
      ];
      lspconfig = {
        servers =
          let
            lang_server = {
              bash.bashls.pkg = pkgs.nodePackages.bash-language-server;
              nix.rnix.pkg = pkgs.rnix-lsp;
              cpp.clangd.pkg = pkgs.clang-tools;
            };
          in
          builtins.foldl'
            (old: lang: old // lang_server.${lang})
            {
            }
            (builtins.filter hasLang (builtins.attrNames lang_server));

        keymaps = map silent_noremap [
          [ "n" "gD" "<cmd>lua vim.lsp.buf.declaration()<CR>" { } ]
          [ "n" "gd" "<cmd>lua vim.lsp.buf.definition()<CR>" { } ]
          [ "n" "K" "<cmd>lua vim.lsp.buf.hover()<CR>" { } ]
          [ "n" "gi" "<cmd>lua vim.lsp.buf.implementation()<CR>" { } ]
          [ "n" "<C-k>" "<cmd>lua vim.lsp.buf.signature_help()<CR>" { } ]
          [ "n" "<Leader>wa" "<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>" { } ]
          [ "n" "<Leader>wr" "<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>" { } ]
          [ "n" "<Leader>wl" "<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>" { } ]
          [ "n" "<Leader>D" "<cmd>lua vim.lsp.buf.type_definition()<CR>" { } ]
          [ "n" "<Leader>rn" "<cmd>lua vim.lsp.buf.rename()<CR>" { } ]
          [ "n" "<Leader>ca" "<cmd>lua vim.lsp.buf.code_action()<CR>" { } ]
          [ "n" "gr" "<cmd>lua vim.lsp.buf.references()<CR>" { } ]
          [ "n" "<C-f>" "<cmd>lua vim.lsp.buf.formatting()<CR>" { } ]
          [ "v" "<C-f>" "<cmd>lua vim.lsp.buf.range_formatting()<CR>" { } ]
        ];
      };
    };
    colorscheme-and-more = {
      after = [ "global" "toggleterm" ];
      plugins = with pkgs.vimPlugins; [
        gruvbox-nvim
        lush-nvim
      ];
      vim = [
        ''
          autocmd FileType c,cpp  set formatoptions=croql cindent comments=sr:/*,mb:*,ex:*/,://
          autocmd BufWritePre * %s/\s\+$//e
        ''
        "colorscheme gruvbox"
      ];
    };
  };
}

