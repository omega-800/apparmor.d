{
  description = "Full set of AppArmor profiles";

  inputs.nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      goVersion = 22;
      systems = [ "x86_64-linux" "aarch64-linux" "i686-linux" ];
      forEachSystem = fun: nixpkgs.lib.genAttrs systems fun;
    in
    {
      packages = forEachSystem (system: rec {
        apparmor-d =
          let
            pkgs = import nixpkgs {
              inherit system;
              overlays = [ self.overlays.default ];
            };
            inherit (pkgs) lib go stdenv gnused;
          in
          stdenv.mkDerivation {
            inherit system;
            pname = "apparmor-d";
            version = "0.0.1";

            src = ./.;

            nativeBuildInputs = [ go ];

            patches = [ ./nixos.patch ];

            buildPhase = # bash
              ''
                HOME="$(pwd)" make 
              '';

            installPhase = # bash
              ''
                DESTDIR="$out" PKGNAME="apparmor-d" make install
              '';

            meta = {
              homepage = "https://apparmor.pujol.io";
              description = "Collection of apparmor profiles";
              licenses = with lib.licenses; [ gpl2 gpl2Only ];
              maintainers = [{
                github = "omega-800";
                githubId = 50942480;
                name = "omega";
              }];
              platforms = lib.platforms.linux;
            };
          };

        default = apparmor-d;
      });

      overlays.default = final: prev: {
        go = final."go_1_${toString goVersion}";
      };

      devShells = forEachSystem (system: rec {
        apparmor-d =
          let
            pkgs = import nixpkgs {
              inherit system;
              overlays = [ self.overlays.default ];
            };
          in
          pkgs.mkShell {
            packages = with pkgs; [
              # go (version is specified by overlay)
              go
              # goimports, godoc, etc.
              gotools
              # https://github.com/golangci/golangci-lint
              golangci-lint
            ];
          };

        default = apparmor-d;
      });
    };
}
