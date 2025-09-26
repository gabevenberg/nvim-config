# Copyright (c) 2023 BirdeeHub and Gabriel Venberg
# Licensed under the MIT license
{
  description = "Gabes neovim config, based on NixCats";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nixCats.url = "github:BirdeeHub/nixCats-nvim";
  };

  # see :help nixCats.flake.outputs
  outputs = {
    self,
    nixpkgs,
    ...
  } @ inputs: let
    inherit (inputs.nixCats) utils;
    luaPath = ./.;
    # this is flake-utils eachSystem
    forEachSystem = utils.eachSystem nixpkgs.lib.platforms.all;
    extra_pkg_config = {
      # allowUnfree = true;
    };
    # management of the system variable is one of the harder parts of using flakes.

    # so I have done it here in an interesting way to keep it out of the way.
    # It gets resolved within the builder itself, and then passed to your
    # categoryDefinitions and packageDefinitions.

    # this allows you to use ${pkgs.system} whenever you want in those sections
    # without fear.

    # see :help nixCats.flake.outputs.overlays
    dependencyOverlays =
      /*
      (import ./overlays inputs) ++
      */
      [
        # This overlay grabs all the inputs named in the format
        # `plugins-<pluginName>`
        # Once we add this overlay to our nixpkgs, we are able to
        # use `pkgs.neovimPlugins`, which is a set of our plugins.
        (utils.standardPluginOverlay inputs)
        # add any other flake overlays here.
      ];

    # see :help nixCats.flake.outputs.categories
    # and
    # :help nixCats.flake.outputs.categoryDefinitions.scheme
    categoryDefinitions = {
      pkgs,
      settings,
      categories,
      extra,
      name,
      mkPlugin,
      ...
    } @ packageDef: let
      colorschemes = with pkgs.vimPlugins; {
        "onedark" = onedark-nvim;
        "catppuccin" = catppuccin-nvim;
        "tokyonight" = tokyonight-nvim;
        "nord" = nord-nvim;
        "gruvbox" = gruvbox-nvim;
      };
    in {
      # to define and use a new category, simply add a new list to a set here,
      # and later, you will include categoryname = true; in the set you
      # provide when you build the package using this builder function.
      # see :help nixCats.flake.outputs.packageDefinitions for info on that section.

      # lspsAndRuntimeDeps:
      # this section is for dependencies that should be available
      # at RUN TIME for plugins. Will be available to PATH within neovim terminal
      # this includes LSPs
      lspsAndRuntimeDeps = with pkgs; {
        # some categories of stuff.
        always = [
          universal-ctags
          ripgrep
          fd
          fzf
          lazygit
          zoxide
        ];
        markdown = [
          mermaid-cli
          imagemagick
          texliveSmall
        ];
        git = [
          lazygit
          git
        ];
        lsp = {
          rust = [
            rust-analyzer
            cargo
          ];
          lua = [
            lua-language-server
          ];
          nix = [
            nix-doc
            nixd
            alejandra
          ];
          python = [
            basedpyright
            ruff
          ];
          C = [
            libclang
          ];
          bash = [
            shellcheck
            bash-language-server
          ];
        };
        format = [
        ];
      };

      # This is for plugins that will load at startup without using packadd:
      startupPlugins = with pkgs.vimPlugins; {
        always = [
          lze
          lzextras
          plenary-nvim
          oil-nvim
          nvim-web-devicons
          snacks-nvim
          nvim-numbertoggle
          lualine-nvim
          which-key-nvim
          todo-comments-nvim
          marks-nvim
        ];
        lsp = {
          rust = [
            rustaceanvim
          ];
        };
        debug = [
          nvim-nio
        ];
        treesitter = [
          comment-nvim
          rainbow-delimiters-nvim
          nvim-treesitter.withAllGrammars
          treesj
        ];
        allcolorschemes = colorschemes;
        # You can retreive information from the
        # packageDefinitions of the package this was packaged with.
        # :help nixCats.flake.outputs.categoryDefinitions.scheme
        themer = builtins.getAttr (categories.colorscheme or "gruvbox") colorschemes;
        # This is obviously a fairly basic usecase for this, but still nice.
      };

      # not loaded automatically at startup.
      # use with packadd and an autocommand in config to achieve lazy loading
      # or a tool for organizing this like lze or lz.n!
      # to get the name packadd expects, use the
      # `:NixCats pawsible` command to see them all
      optionalPlugins = with pkgs.vimPlugins; {
        debug = {
          default = [
            nvim-dap
            nvim-dap-ui
            nvim-dap-virtual-text
            venn-nvim
          ];
        };
        lint = [
          nvim-lint
        ];
        format = [
          conform-nvim
        ];
        markdown = [
          markdown-preview-nvim
        ];
        lsp = {
          default = [
            trouble-nvim
            lualine-lsp-progress
            nvim-lspconfig
          ];
          zk = [
            zk-nvim
          ];
          lua = [
            lazydev-nvim
          ];
        };
        git = [
          gitsigns-nvim
        ];
        always = [
          nvim-surround
          leap-nvim
        ];
        completion = [
          luasnip
          friendly-snippets
          cmp-cmdline
          blink-cmp
          blink-emoji-nvim
          blink-compat
          colorful-menu-nvim
        ];
        extra = [
          vim-startuptime
        ];
      };

      # shared libraries to be added to LD_LIBRARY_PATH
      # variable available to nvim runtime
      sharedLibraries = {
      };

      # environmentVariables:
      # this section is for environmentVariables that should be available
      # at RUN TIME for plugins. Will be available to path within neovim terminal
      environmentVariables = {
      };

      # If you know what these are, you can provide custom ones by category here.
      # If you dont, check this link out:
      # https://github.com/NixOS/nixpkgs/blob/master/pkgs/build-support/setup-hooks/make-wrapper.sh
      extraWrapperArgs = {
      };

      # populates $LUA_PATH and $LUA_CPATH
      extraLuaPackages = {
      };

      # see :help nixCats.flake.outputs.categoryDefinitions.default_values
      # this will enable test.default and debug.default
      # if any subcategory of test or debug is enabled
      # WARNING: use of categories argument in this set will cause infinite recursion
      # The categories argument of this function is the FINAL value.
      # You may use it in any of the other sets.
      extraCats = {
        debug = [
          ["debug" "default"]
        ];
        lsp = [
          ["lsp" "default"]
        ];
      };
    };

    # packageDefinitions:

    # Now build a package with specific categories from above
    # All categories you wish to include must be marked true,
    # but false may be omitted.
    # This entire set is also passed to nixCats for querying within the lua.
    # It is directly translated to a Lua table, and a get function is defined.
    # The get function is to prevent errors when querying subcategories.

    # see :help nixCats.flake.outputs.packageDefinitions
    packageDefinitions = {
      # the name here is the name of the package
      # and also the default command name for it.
      nvim = {
        pkgs,
        name,
        ...
      } @ misc: {
        # these also recieve our pkgs variable
        # see :help nixCats.flake.outputs.packageDefinitions
        settings = {
          suffix-path = true;
          suffix-LD = true;
          # WARNING: MAKE SURE THESE DONT CONFLICT WITH OTHER INSTALLED PACKAGES ON YOUR PATH
          # That would result in a failed build, as nixos and home manager modules validate for collisions on your path
          aliases = [];

          wrapRc = true;
          configDirName = "nvim";
        };
        categories = {
          always = true;
          git = true;
          treesitter = true;
          markdown = true;
          lsp = true;
          completion = true;
          debug = true;
          lspDebugMode = false;
          allcolorschemes = true;
          colorscheme = "gruvbox";
        };
        extra = {
        };
      };
      nvim-minimal = {
        pkgs,
        name,
        ...
      } @ misc: {
        settings = {
          suffix-path = true;
          suffix-LD = true;
          # WARNING: MAKE SURE THESE DONT CONFLICT WITH OTHER INSTALLED PACKAGES ON YOUR PATH
          # That would result in a failed build, as nixos and home manager modules validate for collisions on your path
          aliases = ["vim"];
          wrapRc = true;
          configDirName = "nvim-minimal";
        };
        categories = {
          always = true;
          treesitter = true;
          completion = true;
          lspDebugMode = false;
          themer = true;
          colorscheme = "gruvbox";
        };
        extra = {
        };
      };
    };

    defaultPackageName = "nvim";
    # defaultPackageName is also passed to utils.mkNixosModules and utils.mkHomeModules
    # and it controls the name of the top level option set.
    # If you made a package named `nixCats` your default package as we did here,
    # the modules generated would be set at:
    # config.nixCats = {
    #   enable = true;
    #   packageNames = [ "nixCats" ]; # <- the packages you want installed
    #   <see :h nixCats.module for options>
    # }
    # In addition, every package exports its own module via passthru, and is overrideable.
    # so you can yourpackage.homeModule and then the namespace would be that packages name.
  in
    # see :help nixCats.flake.outputs.exports
    forEachSystem (system: let
      # and this will be our builder! it takes a name from our packageDefinitions as an argument, and builds an nvim.
      nixCatsBuilder =
        utils.baseBuilder luaPath {
          # we pass in the things to make a pkgs variable to build nvim with later
          inherit nixpkgs system dependencyOverlays extra_pkg_config;
          # and also our categoryDefinitions and packageDefinitions
        }
        categoryDefinitions
        packageDefinitions;
      # call it with our defaultPackageName
      defaultPackage = nixCatsBuilder defaultPackageName;

      # this pkgs variable is just for using utils such as pkgs.mkShell
      # within this outputs set.
      pkgs = import nixpkgs {inherit system;};
      # The one used to build neovim is resolved inside the builder
      # and is passed to our categoryDefinitions and packageDefinitions
    in {
      # these outputs will be wrapped with ${system} by utils.eachSystem

      # this will generate a set of all the packages
      # in the packageDefinitions defined above
      # from the package we give it.
      # and additionally output the original as default.
      packages = utils.mkAllWithDefault defaultPackage;

      formatter = pkgs.alejandra;

      # choose your package for devShell
      # and add whatever else you want in it.
      devShells = {
        default = pkgs.mkShell {
          name = defaultPackageName;
          packages = [defaultPackage];
          inputsFrom = [];
          shellHook = ''
          '';
        };
      };
    })
    // (let
      # we also export a nixos module to allow reconfiguration from configuration.nix
      nixosModule = utils.mkNixosModules {
        moduleNamespace = [defaultPackageName];
        inherit
          defaultPackageName
          dependencyOverlays
          luaPath
          categoryDefinitions
          packageDefinitions
          extra_pkg_config
          nixpkgs
          ;
      };
      # and the same for home manager
      homeModule = utils.mkHomeModules {
        moduleNamespace = [defaultPackageName];
        inherit
          defaultPackageName
          dependencyOverlays
          luaPath
          categoryDefinitions
          packageDefinitions
          extra_pkg_config
          nixpkgs
          ;
      };
    in {
      # these outputs will be NOT wrapped with ${system}

      # this will make an overlay out of each of the packageDefinitions defined above
      # and set the default overlay to the one named here.
      overlays =
        utils.makeOverlays luaPath {
          inherit nixpkgs dependencyOverlays extra_pkg_config;
        }
        categoryDefinitions
        packageDefinitions
        defaultPackageName;

      nixosModules.default = nixosModule;
      homeModules.default = homeModule;

      inherit utils nixosModule homeModule;
      inherit (utils) templates;
    });
}
