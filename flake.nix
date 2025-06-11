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
        set -xueo pipefail
        export ORIGINAL_DIR=$(pwd)
        cd $DEVENV_ROOT
        ${script}
        cd $ORIGINAL_DIR
      ''} \"$@\" ";

      writeShellScriptSameDir = name: script: "${pkgs.writeShellScript name ''
        set -xueo pipefail
        ${script}
      ''} \"$@\" ";

      listScripts = scripts: "${pkgs.writeShellScript "help" ''
        echo
        echo 🦾 Useful project scripts:
        echo 🦾
        ${pkgs.gnused}/bin/sed -e 's| |••|g' -e 's|=| |' <<EOF | ${pkgs.util-linuxMinimal}/bin/column -t | ${pkgs.gnused}/bin/sed -e 's|^|🦾 |' -e 's|••| |g'
        ${lib.generators.toKeyValue {} (lib.mapAttrs (_: value: value.description) scripts)}
        EOF
        echo
      ''}";

      # This needs to be sourced, otherwise the eval of exports won't work.
      infisicalEnvLoad = path: "${pkgs.writeShellScript "infisical-env-load" ''
        if [ -n "$ATRO_INFISICAL_TOKEN_PATH" ] && [ -n "$ATRO_INFISICAL_PROJECT_ID_PATH" ]; then
            TOKEN=$(cat "$ATRO_INFISICAL_TOKEN_PATH")
            PROJECT_ID=$(cat "$ATRO_INFISICAL_PROJECT_ID_PATH")
            eval "$(infisical export --format=dotenv-export --token="$TOKEN" --projectId="$PROJECT_ID" --env=local --path="${path}" --silent --telemetry=false)"
        else
            echo "Infisical token or projectId not found. Skipping Infisical environment load."
        fi
      ''}";

      goTest = self.lib.writeShellScript "go-test" ''
        ${pkgs.gotestsum}/bin/gotestsum --  ./... -race -coverprofile=coverage.out -covermode=atomic
      '';

      pyTest = self.lib.writeShellScript "py-test" ''
        ${pkgs.uv}/bin/uv run pytest --cov=./ --cov-report=xml --cache-clear --new-first --failed-first --verbose
      '';

      runMkdocs = mkDocsDir:
        self.lib.writeShellScript "run-mkdocs" ''
          cd ${mkDocsDir}
          ${pkgs.uv}/bin/uv run mkdocs serve --dev-addr 0.0.0.0:8000
        '';

      buildMkdocs = mkDocsDir:
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

          runDocs = mkDocsDir: {
            exec = self.lib.runMkdocs mkDocsDir;
            description = "Run mkdocs server";
          };

          buildDocs = mkDocsDir: {
            exec = self.lib.buildMkdocs mkDocsDir;
            description = "Build mkdocs site";
          };
        };
      };
    };
  };
}
