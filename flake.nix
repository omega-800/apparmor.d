{
  description = "Full set of AppArmor profiles";

  inputs.nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      goVersion = 22;
      systems = [ "x86_64-linux" "aarch64-linux" "i686-linux" ];
    in
    {

      overlays.default = final: prev: {
        go = final."go_1_${toString goVersion}";
      };

      devShells = nixpkgs.lib.genAttrs systems (system: rec {
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
