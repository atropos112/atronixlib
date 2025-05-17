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
      writeShellScript = name: script: "${pkgs.writeShellScript name ''
        set -xeuo pipefail
        ORIGINAL_DIR=$(pwd)
        cd $DEVENV_ROOT
        ${script}
        cd $ORIGINAL_DIR
      ''}";

      listScripts = scripts: "${pkgs.writeShellScript "help" ''
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

      runMkdocs = {mkDocsDir ? "."}:
        self.lib.writeShellScript "run-mkdocs" ''
          cd ${mkDocsDir}
          ${pkgs.uv}/bin/uv run mkdocs serve --dev-addr 0.0.0.0:8000
        '';

      buildMkdocs = {mkDocsDir ? "."}:
        self.lib.writeShellScript "build-mkdocs" ''
          cd ${mkDocsDir}
          ${pkgs.uv}/bin/uv run mkdocs build --strict
        '';

      # INFO: These are convinience wrappers for the functions above for devenv only purposes.
      devenv = {
        git-hooks.hooks = {
          gitleaks = {
            enable = true;
            name = "gitleaks";
            entry = self.lib.writeShellScript "gitleaks" "${pkgs.gitleaks}/bin/gitleaks protect --verbose --redact --staged";
          };

          markdownlint = {
            enable = true;
            settings.configuration = {
              MD045 = false; # no-alt-line
              MD033 = {
                allowed_elements = [
                  "p"
                  "img"
                ];
              };
              MD013 = {
                line_length = 360;
              };
            };
          };
        };
        scripts = {
          help = scripts: {
            exec = self.lib.listScripts scripts;
            description = "Show this help message";
          };

          runDocs = {mkDocsDir ? "."}: {
            exec = self.lib.runMkdocs {inherit mkDocsDir;};
            description = "Run mkdocs server";
          };

          buildDocs = {mkDocsDir ? "."}: {
            exec = self.lib.buildMkdocs {inherit mkDocsDir;};
            description = "Build mkdocs site";
          };
        };
      };
    };
  };
}
