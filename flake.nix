# SPDX-FileCopyrightText: Copyright (c) 2022 by Rivos Inc.
# SPDX-FileCopyrightText: Copyright (c) 2003-2022 Eelco Dolstra and the Nixpkgs/NixOS contributors
# Licensed under the MIT License, see LICENSE for details.
# SPDX-License-Identifier: MIT
{
  description = "postgresql";

  nixConfig = {
    extra-substituters = ["https://rivosinc.cachix.org"];
    extra-trusted-public-keys = ["rivosinc.cachix.org-1:GukvLG5z5jPxRuDu9xLyul0vue1gD1wSChJjljiwpf0="];
  };

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
        final,
        pkgs,
        inputs',
        lib,
        ...
      }: rec {
        packages = rec {
          inherit (inputs.gem5.overlays.default final pkgs) m5ops;
          inherit (inputs.papi.overlays.default final pkgs) papi;
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
          postgresql-papi = postgresql.override { enablePapi = true; };
          postgresql-m5ops = postgresql.override { enableM5ops = true; };
          default = postgresql;
        };
        overlayAttrs = packages;
      };
    };
}
