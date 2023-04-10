# SPDX-FileCopyrightText: Copyright (c) 2022 by Rivos Inc.
# SPDX-FileCopyrightText: Copyright (c) 2003-2022 Eelco Dolstra and the Nixpkgs/NixOS contributors
# Licensed under the MIT License, see LICENSE for details.
# SPDX-License-Identifier: MIT
{
  description = "postgresql";

  inputs = {
    nixpkgs.url = "github:rivosinc/nixpkgs/rivos/nixos-22.11?allRefs=1";
    flake-parts.url = "github:hercules-ci/flake-parts";

    gem5.url = "github:picostove/gem5";
    gem5.inputs.nixpkgs.follows = "nixpkgs";

    papi.url = "github:picostove/papi";
    papi.inputs.nixpkgs.follows = "nixpkgs";

    crosspkgs.url = "github:rivosinc/crosspkgs";
    crosspkgs.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs @ {
    crosspkgs,
    flake-parts,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;}
    {
      imports = [
        crosspkgs.flakeModules.default
        flake-parts.flakeModules.easyOverlay
      ];
      perSystem = {
        pkgs,
        inputs',
        lib,
        ...
      }: rec {
        packages = rec {
          postgresql_14 = (import ./rivos/nix pkgs inputs.self).postgresql_14.override {
            enableSystemd = false;
            glibcLocales = pkgs.glibcLocales.override {
              allLocales = false;
              locales = ["en_US.UTF-8/UTF-8" "C.UTF-8/UTF-8"];
            };
            
            libxml2 = pkgs.libxml2.override {
              pythonSupport = false;
            };
          };
          postgresql = postgresql_14;
          default = postgresql;
        };
        overlayAttrs = packages;
      };
    };
}
