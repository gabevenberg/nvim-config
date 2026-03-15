# Neovim module

A wrapper around nvim that includes the plugins I use day to day.

to use with home manager or nixos, pass this flake as an input, and then in your config,
```nix
imports = [
inputs.nvim-config.nixosModules.neovim
]
```
(replace `nixosModules` with `homeModules` for home manager).

Then, you can just do `wrappers.neovim.enable=true;` to enable nvim.
To enable an option, such as minimal mode (no LSPs), do `wrappers.neovim.settings.minimal = true;`.
