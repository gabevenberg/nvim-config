{pkgs, ...}: {
  projectRootFile = "flake.nix";
  programs.stylua.enable = true;
  programs.alejandra.enable = true;
  programs.fnlfmt.enable = true;
}
