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

      helpScript = scripts: "${pkgs.writeShellScript "help" ''
        echo
        echo 🦾 Useful project scripts:
        echo 🦾
        ${pkgs.gnused}/bin/sed -e 's| |••|g' -e 's|=| |' <<EOF | ${pkgs.util-linuxMinimal}/bin/column -t | ${pkgs.gnused}/bin/sed -e 's|^|🦾 |' -e 's|••| |g'
        ${lib.generators.toKeyValue {} (lib.mapAttrs (_: value: value.description) scripts)}
        EOF
        echo
      ''}";
    };
  };
}
