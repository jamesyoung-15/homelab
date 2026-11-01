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

        # Real commands rather than shell functions, so they also exist when the
        # shell is loaded by direnv (which only carries over env vars, not functions)
        envWrapper = name: script: env: pkgs.writeShellScriptBin name ''
          exec "$HOMELAB_ROOT/scripts/${script}" ${env} "$@"
        '';
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

            (envWrapper "ansible-lab" "ansible-env.sh" "lab")
            (envWrapper "ansible-prod" "ansible-env.sh" "prod")
            (envWrapper "tofu-lab" "tofu-env.sh" "lab")
            (envWrapper "tofu-prod" "tofu-env.sh" "prod")
          ];
          shellHook = ''
            repo_root="$(git rev-parse --show-toplevel)"
            export HOMELAB_ROOT="$repo_root"

            # Only takes effect under `nix develop`; direnv can't carry completions
            complete -F _command ansible-lab ansible-prod tofu-lab tofu-prod

            export ANSIBLE_CONFIG="$repo_root/iac/ansible/ansible.cfg"
            export UV_PYTHON_DOWNLOADS=never
            export UV_PYTHON_PREFERENCE=only-system
        '';
        };
      }
    );
}
