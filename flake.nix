# SPDX-FileCopyrightText: Copyright (c) 2022 by Rivos Inc.
# SPDX-FileCopyrightText: Copyright (c) 2003-2022 Eelco Dolstra and the Nixpkgs/NixOS contributors
# Licensed under the MIT License, see LICENSE for details.
# SPDX-License-Identifier: MIT
{
  description = "postgresql";

  inputs.nixpkgs.url = "nixpkgs/nixos-unstable";

  inputs.gem5.url = "github:picostove/gem5";
  inputs.gem5.inputs.nixpkgs.follows = "nixpkgs";

  inputs.papi.url = "github:picostove/papi";
  inputs.papi.inputs.nixpkgs.follows = "nixpkgs";

  outputs = {
    self,
    nixpkgs,
    gem5,
    papi,
  }: let
    # to work with older version of flakes
    lastModifiedDate = self.lastModifiedDate or self.lastModified or "19700101";

    # Generate a user-friendly version number.
    version = builtins.substring 0 8 lastModifiedDate;

    # System types to support.
    supportedSystems = [
      "riscv64-linux"
      "x86_64-linux"
    ];

    # Helper function to generate an attrset '{ x86_64-linux = f "x86_64-linux"; ... }'.
    forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

    # Nixpkgs instantiated for supported system types.
    nixpkgsFor = forAllSystems (system:
      import nixpkgs {
        inherit system;

        overlays = [
          self.overlays.default
          self.overlays.rivosAdapters
          gem5.overlays.default
          papi.overlays.default
        ];
      });

    riscv64PkgsFor = forAllSystems (system:
      import nixpkgs {
        inherit system;
        overlays = [
          self.overlays.default
          gem5.overlays.default
          papi.overlays.default
        ];
        crossOverlays = [
          self.overlays.rivosAdapters
        ];
        crossSystem = {
          config = "riscv64-unknown-linux-gnu";
          gcc.arch = "rv64gc_zba_zbb_zbc_zbs";
          system = "riscv64-linux";
        };
      });

    x86PkgsFor = forAllSystems (system:
      import nixpkgs {
        inherit system;
        overlays = [
          self.overlays.default
          gem5.overlays.default
          papi.overlays.default
        ];
        crossOverlays = [
          self.overlays.rivosAdapters
        ];
        crossSystem = {
          config = "x86_64-unknown-linux-gnu";
          gcc.tune = "icelake";
          system = "x86_64-linux";
        };
      });
  in {
    overlays.default = final: prev: let
      postgresql_14 = (import ./rivos/nix final self).postgresql_14.override {
        #stdenv = rivosAdapters.modifyStdenv final.stdenv [ rivosAdapters.embedDebugInfo ];
      };
    in rec {
      inherit postgresql_14;
      postgresql = postgresql_14.override {this = postgresql;};
      postgresqlPackages = final.recurseIntoAttrs postgresql.pkgs;
      postgresql14Packages = postgresqlPackages;
    };
    overlays.rivosAdapters = final: prev: {
      rivosAdapters = import ./rivos/nix/stdenv-adapters.nix {
        inherit (final) lib config;
        inherit nixpkgs;
        pkgs = final;
      };
    };

    packages = forAllSystems (system: let
      papi = (nixpkgsFor.${system}).papi;
      postgresql = (nixpkgsFor.${system}).postgresql;
      postgresql-riscv64 = (riscv64PkgsFor.${system}).postgresql;
      postgresql-x86_64 = (x86PkgsFor.${system}).postgresql;
      postgresql-riscv64-m5ops = postgresql-riscv64.override {enableM5ops = true;};
    in {
      inherit postgresql postgresql-riscv64 postgresql-riscv64-m5ops postgresql-x86_64;
      inherit papi;
      default = postgresql;
    });
  };
}
