{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    opam-nix = {
      url = "github:tweag/opam-nix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
        opam-repository.follows = "opam-repository";
      };
    };

    opam-repository = {
      url = "github:ocaml/opam-repository";
      flake = false;
    };
  };

  outputs = {
    self,
    flake-utils,
    opam-nix,
    nixpkgs,
    opam-repository,
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
          # test and doc dependencies of this project
          # (resolveArgs.with-test/with-doc would also pull in test deps of
          # every dependency, e.g. ocaml-lsp-server's pinned ocamlformat,
          # which conflicts with recent dune versions)
          alcotest = "*";
          eio_main = "*";
          odoc = "*";
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
            # opam-nix's ocaml overlay requires the ocaml-config package in
            # the scope, but recent opam-repository removed the dependency of
            # the ocaml virtual package on ocaml-config
            ocaml-config = "*";
          };
        scope =
          on.buildOpamProject' {}
          ./.
          query;
        overlay = final: prev:
          (
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
          )
          // {
            utop = prev.utop.overrideAttrs (previousAttrs: {
              # cf. https://github.com/tweag/opam-nix/issues/112#issuecomment-2693392340
              sourceRoot = ".";
            });
          };
        scope' = scope.overrideScope overlay;
        # Packages from devPackagesQuery
        devPackages = builtins.attrValues (pkgs.lib.getAttrs (builtins.attrNames devPackagesQuery) scope');
        # Packages in this workspace
        packages = pkgs.lib.getAttrs (builtins.attrNames localPackagesQuery) scope';
      in {
        formatter = pkgs.alejandra;

        legacyPackages = scope';

        packages = packages // {default = packages.yume;};

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
