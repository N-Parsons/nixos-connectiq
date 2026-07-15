{ pkgs ? import <nixpkgs> {} }:

let
  legacyPkgs = import (builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/nixos-24.11.tar.gz";
  }) {
    config = {
      permittedInsecurePackages = [
        "libsoup-2.74.3"
        "webkitgtk-4.0.37"
      ];
    };
  };
in
(pkgs.buildFHSEnv {
  name = "garmin-monkey-c-env";

  # Unlike the sdkmanager, most packages can be taken from the system
  targetPkgs = pkgs: with pkgs; [
    # Java Runtime
    openjdk17

    # VS Codium (so you can run it inside the FHS environment and it sees the tools)
    vscodium

    # SDK dependencies
    zlib
    libsecret
    expat

    libxkbcommon
    libX11
    libXext
    libXxf86vm
    libSM

    libpng
    libjpeg8
    freetype
    fontconfig

    glib
    gdk-pixbuf
    cairo
    pango
    gtk3

    atk
    udev
    libusb1

    # Legacy, insecure dependencies
    legacyPkgs.libsoup
    legacyPkgs.webkitgtk_4_0
  ];

  profile = ''
    # Point the JAVA_HOME to the FHS environment's Java
    export JAVA_HOME=${pkgs.openjdk17}
    
    # Determine the active SDK by checking the config file
    CFG_FILE="$HOME/.Garmin/ConnectIQ/current-sdk.cfg"
    
    if [ -f "$CFG_FILE" ]; then
      CURRENT_SDK=$(cat "$CFG_FILE")
      export PATH="$CURRENT_SDK/bin:$PATH"

      USING_SDK=$(basename $CURRENT_SDK)
    else
      USING_SDK="NOT FOUND"
      echo "[!] WARNING: current-sdk.cfg not found. Run the Garmin SDK Manager first."
    fi
    
    echo "=========================================================="
    echo " Using SDK: $USING_SDK"
    echo " - Run 'codium .' to launch your editor"
    echo " - Ensure you use the VSCode Monkey C extension"
    echo "=========================================================="
  '';
}).env
