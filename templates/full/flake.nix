{
  description = "A simple janet-nix project";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    janet-nix = {
      url = "github:turnerdev/janet-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, janet-nix }:
    let
      supportedSystems = [ "x86_64-linux" "x86_64-darwin" ];
      forAllSystems = f:
        nixpkgs.lib.genAttrs supportedSystems (system: f system);
      nixpkgsFor = forAllSystems (system:
        import nixpkgs {
          inherit system;
          overlays = [ self.overlay ];
        });
    in
    {
      overlay = final: prev: {
        jpm = prev.jpm.overrideAttrs (old: {
          src = builtins.fetchGit {
            url = "https://github.com/janet-lang/jpm.git";
            rev = "6771439785aea36c76c5aec7c2d7f67df83c46bb";
          };
        });
      };

      packages = forAllSystems (system: {
        my-new-program = janet-nix.packages.${system}.mkJanet {
          name = "my-new-program";
          version = "0.0.1";
          src = ./.;
          quickbin = ./init.janet;
        };
      });

      defaultPackage =
        forAllSystems (system: self.packages.${system}.my-new-program);

      devShell = forAllSystems (system:
        with nixpkgsFor.${system}; mkShell {
          packages = [ janet jpm ];
          buildInputs = [ janet ];
          shellHook = ''
            # localize jpm dependency paths
            export JANET_PATH="$PWD/.jpm"
            export JANET_TREE="$JANET_PATH/jpm_tree"
            export JANET_LIBPATH="$JANET_PATH/lib"
            export JANET_HEADERPATH="$JANET_PATH/include/janet"
            export JANET_BUILDPATH="$JANET_PATH/build"
            export PATH="$PATH:$JANET_TREE/bin"
            mkdir -p "$JANET_TREE"
            mkdir -p "$JANET_BUILDPATH"
          '';
        });
    };
}
