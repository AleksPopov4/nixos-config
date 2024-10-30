{ pkgs ? import <nixpkgs> {} }:

pkgs.stdenv.mkDerivation {
  pname = "hello-python";
  version = "1.0";

  src = ./.;

  buildInputs = [ pkgs.python3 ];

  installPhase = ''
    mkdir -p $out/bin
    echo '#!/usr/bin/env python3' > $out/bin/hello
    cat ./hello.py >> $out/bin/hello
    chmod +x $out/bin/hello
  '';

  meta = with pkgs.lib; {
    description = "A simple Python program that prints 'Hello world!'";
    license = licenses.mit;
    maintainers = with maintainers; [ lex ];
  };
}
