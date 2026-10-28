{
  description = "Homelab Dev Shell";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      with pkgs;
      {
        devShells.default = mkShell {
          packages = [
            python314
            python314Packages.ansible-core
            python314Packages.uv

            age
            ansible-lint
            diffutils
            git
            gitleaks
            opentofu
            jq
            pre-commit
            sops
            tflint
            tofu-ls
            wrangler
            yamllint
            yq
            zensical
          ];
          shellHook = ''
            repo_root="$(git rev-parse --show-toplevel)"
            tofu-lab() {
              "$repo_root/scripts/tofu-env.sh" lab "$@"
            }
            tofu-prod() {
              "$repo_root/scripts/tofu-env.sh" prod "$@"
            }

            ansible-lab() {
              "$repo_root/scripts/ansible-env.sh" lab "$@"
            }

            ansible-prod() {
              "$repo_root/scripts/ansible-env.sh" prod "$@"
            }

            export UV_PYTHON_DOWNLOADS=never
            export UV_PYTHON_PREFERENCE=only-system

        '';
        };
      }
    );
}
