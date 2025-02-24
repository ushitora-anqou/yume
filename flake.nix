{
  inputs = {
    opam-nix.url = "github:tweag/opam-nix";
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.follows = "opam-nix/nixpkgs";
  };
  outputs = {
    self,
    flake-utils,
    opam-nix,
    nixpkgs,
  } @ inputs:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};
        lib = nixpkgs.lib;
        on = opam-nix.lib.${system};
        localPackagesQuery = builtins.mapAttrs (_: pkgs.lib.last) (on.listRepo (on.makeOpamRepo ./.));
        devPackagesQuery = {
          ocaml-lsp-server = "*";
          utop = "*";
          ocamlformat = let
            # read .ocamlformat
            # cf. https://nymphium.github.io/2023/05/06/purely-functioinal-ocaml-development.html
            ocamlformatConfig = lib.strings.splitString "\n" (builtins.readFile ./.ocamlformat);
            re = builtins.match "version[[:space:]]*=[[:space:]]*([^[:space:]]*)[[:space:]]*$";
            versionLine =
              lib.lists.findFirst
              (l: builtins.isList (re l))
              (throw "no version specified in .ocamlformat")
              ocamlformatConfig;
            version = builtins.elemAt (re versionLine) 0;
          in
            version;
        };
        query =
          devPackagesQuery
          // {
            ocaml-system = "*";
          };
        scope =
          on.buildOpamProject' {
            resolveArgs = {
              with-test = true;
              with-doc = true;
            };
          }
          ./.
          query;
        overlay = final: prev: (
          # disable library's test and doc
          # cf. https://nymphium.github.io/2023/05/06/purely-functioinal-ocaml-development.html
          with builtins;
            mapAttrs
            (p: _:
              if hasAttr "passthru" prev.${p} && hasAttr "pkgdef" prev.${p}.passthru
              then
                prev.${p}.overrideAttrs (_: {
                  opam__with_test = "false";
                  opam__with_doc = "false";
                })
              else prev.${p})
            prev
        );
        scope' = scope.overrideScope overlay;
        # Packages from devPackagesQuery
        devPackages = builtins.attrValues (pkgs.lib.getAttrs (builtins.attrNames devPackagesQuery) scope');
        # Packages in this workspace
        packages = pkgs.lib.getAttrs (builtins.attrNames localPackagesQuery) scope';
      in {
        formatter = pkgs.alejandra;

        legacyPackages = scope';

        packages = packages // { default = packages.yume; };

        devShells.default = pkgs.mkShell {
          inputsFrom = builtins.attrValues packages;
          buildInputs =
            devPackages
            ++ [
              # You can add packages from nixpkgs here
            ];
        };
      }
    );
}
