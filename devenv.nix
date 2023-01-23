{ pkgs, inputs, ... }:
{
#  languages.ruby.enable = true; # we override it via nixpkgs-ruby
  env.FREEDESKTOP_MIME_TYPES_PATH = "${pkgs.shared-mime-info}/share/mime/packages/freedesktop.org.xml";
  env.RUBY_YJIT_ENABLE = "1";

  packages = [ pkgs.libyaml pkgs.jq 
  inputs.nixpkgs-ruby.packages.${pkgs.system}."ruby-3.2.0" 
  pkgs.pkg-config pkgs.imagemagick pkgs.postgresql pkgs.gcc pkgs.gnumake ];
  pre-commit.hooks.shellcheck.enable = true;
  enterShell = ''
    echo 'Making sure the basics for native compilation are available:'
    gcc --version
    make --version
    ruby -v
  '';
}
