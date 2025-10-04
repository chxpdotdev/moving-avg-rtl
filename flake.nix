{
  description = "Sliding-window moving average project using Verilog";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    nix-eda.url = "github:fossi-foundation/nix-eda";
  };

  ## Add these to your Nix config if you want to use caches
  # nixConfig = {
  #   substituters = [
  #     "https://cache.nixos.org/"
  #     "https://nix-cache.fossi-foundation.org"
  #   ];
  #   trusted-public-keys = [
  #     "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
  #     "nix-cache.fossi-foundation.org:3+K59iFwXqKsL7BNu6Guy0v+uTlwsxYQxjspXzqLYQs="
  #   ];
  # };

  outputs = {
    self,
    nixpkgs,
    nix-eda,
    ...
  }: let
    systems = ["x86_64-linux"];
    forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f (import nixpkgs {inherit system;}));
  in {
    devShells = forAllSystems (
      pkgs: let
        eda = nix-eda.packages.${pkgs.system};
      in {
        default = pkgs.mkShell {
          packages = [
            pkgs.iverilog
            # eda.iverilog - fails to build
            eda.verilator
            pkgs.gtkwave
            pkgs.octaveFull
            pkgs.gnuplot
            pkgs.ghostscript
            pkgs.graphicsmagick
          ];
        };
      }
    );
  };
}
