{
  lib,
  stdenv,
  fetchFromGitHub,
  postgresql,
  arrow-cpp,
}:
stdenv.mkDerivation rec {
  pname = "parquet_fdw";
  version = "unstable-2022-12-06";

  buildInputs = [
    arrow-cpp
    postgresql
  ];

  src = fetchFromGitHub {
    owner = "adjust";
    repo = "parquet_fdw";
    rev = "365710ba977cd05fd1ea31cec208956fa9352800";
    hash = "sha256-bkBF1WDLk7EaI+zq90JbigM23xuSFU/4SdkgIPXRpsk";
  };

  installPhase = ''
    mkdir -p $out/{lib,share/postgresql/extension}

    cp *.so      $out/lib
    cp *.sql     $out/share/postgresql/extension
    cp *.control $out/share/postgresql/extension
  '';

  meta = with lib; {
    description = "Read-only Apache Parquet foreign data wrapper for PostgreSQL";
    homepage = "https://github.com/adjust/parquet_fdw";
    platforms = postgresql.meta.platforms;
    license = licenses.postgresql;
  };
}
