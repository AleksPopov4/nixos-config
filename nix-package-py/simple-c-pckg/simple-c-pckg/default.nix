{ pkgs ? import <nixpkgs> {} }:

pkgs.stdenv.mkDerivation {
  pname = "my-c-program";
  version = "1.0";
  src = ./.;

  buildInputs = [ pkgs.gcc ];

  buildPhase = ''
    gcc -o henlo main.c
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp henlo $out/bin/
  '';

  meta = with pkgs.lib; {
    description = "Prints 'henlo!'";
    license = licenses.mit;
    maintainers = [ maintainers.lex ];
  };
}
