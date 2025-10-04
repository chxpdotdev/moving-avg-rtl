{
  description = "Sliding-window moving average project using Verilog";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";

    nix-eda.url = "github:fossi-foundation/nix-eda/5.5.0";

    openxc7.url = "github:openXC7/toolchain-nix";
    openxc7.inputs.nixpkgs.follows = "nixpkgs";
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
    openxc7,
    ...
  }: let
    systems = ["x86_64-linux"];
    forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f (import nixpkgs {inherit system;}));
  in {
    devShells = forAllSystems (
      pkgs: let
        eda = nix-eda.packages.${pkgs.system};
        openxc7Pkgs = openxc7.packages.${pkgs.system};

        qtnextpnr-xilinx = openxc7Pkgs.nextpnr-xilinx.overrideAttrs (old: {
          nativeBuildInputs = (old.nativeBuildInputs or []) ++ [pkgs.libsForQt5.wrapQtAppsHook];
          buildInputs = (old.buildInputs or []) ++ [pkgs.libsForQt5.qtbase];
          cmakeFlags = (old.cmakeFlags or []) ++ ["-DBUILD_GUI=ON"];
          postFixup = ''
            wrapQtApp $out/bin/nextpnr-xilinx
          '';
        });
      in {
        default = pkgs.mkShell {
          buildInputs =
            (with openxc7Pkgs; [
              fasm
              fpga-assembler
              prjxray
              qtnextpnr-xilinx
            ])
            ++ (with pkgs; [
              yosys
              ghdl
              yosys-ghdl
              openfpgaloader
              pypy310
              python312Packages.pyyaml
              python312Packages.textx
              python312Packages.simplejson
              python312Packages.intervaltree
            ]);

          packages = [
            eda.iverilog
            eda.verilator
            eda.yosysFull

            pkgs.gtkwave
            pkgs.octaveFull
            pkgs.gnuplot
            pkgs.ghostscript
            pkgs.graphicsmagick
            pkgs.openfpgaloader
	          pkgs.graphviz

            openxc7Pkgs.prjxray
            openxc7Pkgs.fasm
            openxc7Pkgs.fpga-assembler

            qtnextpnr-xilinx
            pkgs.qt5.qtwayland
          ];

           shellHook =
            let pyPkgPath = "/lib/python3.12/site-packages/:";
            in pkgs.lib.concatStrings [
              "export FAMILY=artix7\n"
              "export CHIPDB=" openxc7Pkgs.nextpnr-xilinx-chipdb.artix7.outPath "/xc7a100tcsg324.bin\n"
              "export NEXTPNR_XILINX_DIR=" qtnextpnr-xilinx.outPath "\n"
              "export NEXTPNR_XILINX_PYTHON_DIR=" qtnextpnr-xilinx.outPath "/share/nextpnr/python/\n"
              "export PRJXRAY_DB_DIR=" qtnextpnr-xilinx.outPath "/share/nextpnr/external/prjxray-db\n"
              "export PRJXRAY_PYTHON_DIR=" openxc7Pkgs.prjxray.outPath "/usr/share/python3/\n"
              ''export PYTHONPATH=''$PYTHONPATH:''$PRJXRAY_PYTHON_DIR:'' 
                openxc7Pkgs.fasm.outPath pyPkgPath
                pkgs.python312Packages.textx.outPath pyPkgPath
                pkgs.python312Packages.arpeggio.outPath pyPkgPath
                pkgs.python312Packages.pyyaml.outPath pyPkgPath
                pkgs.python312Packages.simplejson.outPath pyPkgPath
                pkgs.python312Packages.intervaltree.outPath pyPkgPath
                pkgs.python312Packages.sortedcontainers.outPath pyPkgPath
                "\n"
              "export PYPY3=" pkgs.pypy310.outPath "/bin/pypy3.10"
            ];
        };
      }
    );
  };
}
