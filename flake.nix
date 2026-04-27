{
    description = "Dev shell with duckdb and nodejs";

    inputs = {
        nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    };

    outputs = { self, nixpkgs }:
        let
            systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
            forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f {
                pkgs = import nixpkgs { inherit system; };
            });
        in
        {
            devShells = forAllSystems ({ pkgs }: {
                default = pkgs.mkShell {
                    packages = [
                        pkgs.duckdb
                        pkgs.nodejs
                    ];
                };
            });
        };
}