{
  description = "atroflake";

  outputs = {
    self,
    nixpkgs,
  }: {
    lib = {
      writeShellScript = name: script: ''
        set -xeuo pipefail
        ORIGINAL_DIR=$(pwd)
        cd $DEVENV_ROOT
        ${script}
        cd $ORIGINAL_DIR
      '';

      testScript = self.lib.writeShellScript "test" "go test ./... -race -coverprofile=coverage.out -covermode=atomic";

      helpScript = nixpkgs.writeShellScript "help" ''
        echo
        echo Useful project scripts:
        echo
        ${nixpkgs.gnused}/bin/sed -e 's| |••|g' -e 's|=| |' <<EOF | ${nixpkgs.util-linuxMinimal}/bin/column -t | ${nixpkgs.gnused}/bin/sed -e 's|^| |' -e 's|••| |g'
        ${nixpkgs.lib.generators.toKeyValue {} (nixpkgs.lib.mapAttrs (_: value: value.description) {
          test = {description = "Run tests";};
          help = {description = "Show help";};
        })}
        EOF
        echo
      '';

      go = "${nixpkgs.go}/bin/go";
      golangci-lint = "${nixpkgs.golangci-lint}/bin/golangci-lint";
      kubectl = "${nixpkgs.kubectl}/bin/kubectl";
      ctrlgen = "${nixpkgs.kubernetes-controller-tools}/bin/controller-gen";
      kustomize = "${nixpkgs.kustomize}/bin/kustomize";
    };
  };
}
