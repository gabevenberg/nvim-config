inputs: {
  config,
  wlib,
  lib,
  pkgs,
  ...
}: {
  imports = [wlib.wrapperModules.neovim];
  # NOTE: see the tips and tricks section or the bottom of this file + flake inputs to understand this value
  options.nvim-lib.neovimPlugins = lib.mkOption {
    readOnly = true;
    type = lib.types.attrsOf wlib.types.stringable;
    # Makes plugins autobuilt from our inputs available with
    # `config.nvim-lib.neovimPlugins.<name_without_prefix>`
    default = config.nvim-lib.pluginsFromPrefix "plugins-" inputs;
  };

  # choose a directory for your config.
  config.settings.config_directory = ./.;
  # you can also use an impure path!
  # config.settings.config_directory = lib.generators.mkLuaInline "vim.fn.stdpath('config')";
  # config.settings.config_directory = "/home/<USER>/.config/nvim";
  # If you do that, it will not be provisioned by nix, but it will have normal reload for quick edits!

  # If you want to install multiple neovim derivations via home.packages or environment.systemPackages
  # in order to prevent path collisions:

  # set this to true:
  # config.settings.dont_link = true;

  # and make sure these dont share values:
  # config.binName = "nvim";
  # config.settings.aliases = [ ];

  # To add a wrapped $out/bin/${config.binName}-neovide to the resulting neovim derivation
  # config.hosts.neovide.nvim-host.enable = true;

  # You can declare your own options!
  options.settings.colorscheme = lib.mkOption {
    type = lib.types.str;
    default = "onedark_dark";
  };
  options.settings.minimal = lib.mkOption {
    type = lib.types.bool;
    default = false;
  };
  config.settings.colorscheme = "gruvbox"; # <- just demonstrating that it is an option
  # and grab it in lua with `require(vim.g.nix_info_plugin_name)("onedark", "settings", "colorscheme") == "moonfly"`
  config.specs.colorscheme = {
    lazy = true;
    enable = lib.mkIf config.settings.minimal (lib.mkDefault true);
    data = builtins.getAttr config.settings.colorscheme (
      with pkgs.vimPlugins; {
        "onedark_dark" = onedarkpro-nvim;
        "onedark_vivid" = onedarkpro-nvim;
        "onedark" = onedarkpro-nvim;
        "onelight" = onedarkpro-nvim;
        "moonfly" = vim-moonfly-colors;
        "catppuccin" = catppuccin-nvim;
        "tokyonight" = tokyonight-nvim;
        "nord" = nord-nvim;
        "gruvbox" = gruvbox-nvim;
      }
    );
  };
  config.specs.lze = {
    enable = lib.mkIf config.settings.minimal (lib.mkDefault true);
    data = [
      config.nvim-lib.neovimPlugins.lze
      config.nvim-lib.neovimPlugins.lzextras
    ];
  };

  config.specs.general = {
    # this would ensure any config included from nix in here will be ran after any provided by the `lze` spec
    # If we provided any from within either spec, anyway
    after = ["lze"];
    enable = lib.mkIf config.settings.minimal (lib.mkDefault true);
    extraPackages = with pkgs; [
      ripgrep
      fd
      fzf
      zoxide
      git
      lazygit
      tree-sitter
    ];
    # here we chose a DAL of plugins, but we can also pass a single plugin, or null
    data = with pkgs.vimPlugins; [
      snacks-nvim
      lualine-nvim
      plenary-nvim
      oil-nvim
      nvim-web-devicons
      nvim-numbertoggle
      lualine-nvim
      marks-nvim
    ];
  };
  config.specs.lazy = {
    after = ["lze"];
    enable = lib.mkIf config.settings.minimal (lib.mkDefault true);
    lazy = true;
    data = with pkgs.vimPlugins; [
      gitsigns-nvim
      nvim-surround
      treesj
      which-key-nvim
      todo-comments-nvim
      comment-nvim
      rainbow-delimiters-nvim
      nvim-treesitter.withAllGrammars
    ];
  };
  config.specs.completion = {
    after = ["lze"];
    lazy = true;
    enable = lib.mkIf config.settings.minimal false;
    data = with pkgs.vimPlugins; [
      luasnip
      friendly-snippets
      cmp-cmdline
      blink-cmp
      blink-emoji-nvim
      blink-compat
      colorful-menu-nvim
    ];
  };

  config.specs.markdown = {
    after = ["general" "lazy"];
    enable = lib.mkIf config.settings.minimal false;
    lazy = true;
    data = with pkgs.vimPlugins; [
      markdown-preview-nvim
    ];
    extraPackages = with pkgs; [
      mermaid-cli
      imagemagick
      texliveSmall
    ];
  };

  config.specs.lsp = {
    enable = lib.mkIf config.settings.minimal false;
    after = ["general" "lazy"];
    lazy = true;

    data = with pkgs.vimPlugins; [
      trouble-nvim
      lualine-lsp-progress
      nvim-lspconfig
    ];
  };

  config.specs.zk = {
    after = ["general" "lazy"];
    data = with pkgs.vimPlugins; [
      zk-nvim
    ];
    extraPackages = with pkgs; [
      zk
    ];
  };

  config.specs.typst = {
    name = "typst";
    after = ["general" "lazy"];
    data = with pkgs.vimPlugins; [
      typst-preview-nvim
    ];
    extraPackages = with pkgs; [
      typst
      tinymist
    ];
  };

  config.specs.nix = {
    name = "nix";
    after = ["general" "lazy"];
    data = null;
    extraPackages = with pkgs; [
      nixd
      alejandra
    ];
  };

  config.specs.lua = {
    name = "lua";
    after = ["general" "lazy"];
    data = with pkgs.vimPlugins; [
      lazydev-nvim
    ];
    extraPackages = with pkgs; [
      lua-language-server
      stylua
    ];
  };

  config.specs.rust = {
    name = "rust";
    after = ["general" "lazy"];
    data = with pkgs.vimPlugins; [
      rustaceanvim
    ];
    extraPackages = with pkgs; [
      rust-analyzer
      cargo
    ];
  };

  config.specs.python = {
    name = "python";
    after = ["general" "lazy"];
    data = null;
    extraPackages = with pkgs; [
      ty
      ruff
    ];
  };

  config.specs.C = {
    name = "C";
    after = ["general" "lazy"];
    data = null;
    extraPackages = with pkgs; [
      libclang
    ];
  };

  config.specs.bash = {
    name = "bash";
    after = ["general" "lazy"];
    lazy = true;
    data = null;
    extraPackages = with pkgs; [
      shellcheck
      bash-language-server
    ];
  };

  config.specMods = lib.mkMerge [
    {
      options.extraPackages = lib.mkOption {
        type = lib.types.listOf wlib.types.stringable;
        default = [];
        description = "a extraPackages spec field to put packages to suffix to the PATH";
      };
    }
    # Makes enable be false by default if minimal is set.
    (lib.mkIf config.settings.minimal (
      {parentSpec, ...}: {
        config.enable = lib.mkOverride 1400 (parentSpec.enable or false); # 1400 is 100 higher than mkOptionDefault (1500)
      }
    ))
  ];

  config.extraPackages = config.specCollect (acc: v: acc ++ (v.extraPackages or [])) [];
  # Inform our lua of which top level specs are enabled
  options.settings.cats = lib.mkOption {
    readOnly = true;
    type = lib.types.attrsOf lib.types.bool;
    default = builtins.mapAttrs (_: v: v.enable) config.specs;
  };
  # build plugins from inputs set
  options.nvim-lib.pluginsFromPrefix = lib.mkOption {
    type = lib.types.raw;
    readOnly = true;
    default = prefix: inputs:
      lib.pipe inputs [
        builtins.attrNames
        (builtins.filter (s: lib.hasPrefix prefix s))
        (map (
          input: let
            name = lib.removePrefix prefix input;
          in {
            inherit name;
            value = config.nvim-lib.mkPlugin name inputs.${input};
          }
        ))
        builtins.listToAttrs
      ];
  };
}
