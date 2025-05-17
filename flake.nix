{
  description = "atroflake";

  outputs = {
    self,
    nixpkgs,
  }: let
    pkgs = import nixpkgs {
      system = "x86_64-linux";
    };
    lib = pkgs.lib;
  in {
    lib = {
      # writeShellScript here is to
      # - Add same setup to all scripts
      # - Cause treesitter to format bash scripts correctly
      writeShellScript = name: script: ''
        set -xeuo pipefail
        ORIGINAL_DIR=$(pwd)
        cd $DEVENV_ROOT
        ${script}
        cd $ORIGINAL_DIR
      '';

      list-scripts = scripts: "${pkgs.writeShellScript "help" ''
        echo
        echo 🦾 Useful project scripts:
        echo 🦾
        ${pkgs.gnused}/bin/sed -e 's| |••|g' -e 's|=| |' <<EOF | ${pkgs.util-linuxMinimal}/bin/column -t | ${pkgs.gnused}/bin/sed -e 's|^|🦾 |' -e 's|••| |g'
        ${lib.generators.toKeyValue {} (lib.mapAttrs (_: value: value.description) scripts)}
        EOF
        echo
      ''}";

      goTest = self.lib.writeShellScript "test" ''
        go test ./... -race -coverprofile=coverage.out -covermode=atomic
      '';

      run-mkdocs = {mkdocsPath ? "./mkdocs.yml"}:
        self.lib.writeShellScript "run-mkdocs" ''
          mkdocs serve --dev-addr 0.0.0.0:8000 --config-file ${mkdocsPath}
        '';

      build-mkdocs = {mkdocsPath ? "./mkdocs.yml"}:
        self.lib.writeShellScript "build-mkdocs" ''
          mkdocs build --strict --config-file ${mkdocsPath}
        '';

      # INFO: These are convinience wrappers for the functions above for devenv only purposes.
      devenv = {
        pre-commit.hooks = {
          gitleaks = {
            enable = true;
            name = "gitleaks";
            entry = self.lib.writeShellScript "gitleaks" "gitleaks protect --verbose --redact --staged";
          };
        };
        scripts = {
          help = scripts: {
            exec = self.lib.list-scripts scripts;
            description = "Show this help message";
          };

          run-docs = {mkdocsPath ? "./mkdocs.yml"}: {
            exec = self.lib.run-mkdocs {mkdocsPath = mkdocsPath;};
            description = "Run mkdocs server";
          };

          build-docs = {mkdocsPath ? "./mkdocs.yml"}: {
            exec = self.lib.build-mkdocs {mkdocsPath = mkdocsPath;};
            description = "Build mkdocs site";
          };
        };
      };
    };
  };
}
