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
  name = "connectiq-sdkmanager-env";

  # Several packages are inter-related, so exclusively using legacy packages is simpler
  targetPkgs = pkgs: with legacyPkgs; [
    stdenv.cc.cc.lib
    libgcc
    zlib
    curl
    libsecret
    expat
    libxkbcommon
    xorg.libXext
    xorg.libX11
    xorg.libXxf86vm
    xorg.libSM
    libpng
    libjpeg8
    freetype
    fontconfig
    glib
    gdk-pixbuf
    cairo
    pango
    at-spi2-atk
    gtk3

    # Explicitly insecure packages
    libsoup
    webkitgtk_4_0
  ];

  profile = ''
    # 1. Clear system conflicts (GVFS)
    unset GIO_EXTRA_MODULES
    unset GDK_PIXBUF_MODULE_FILE

    # 2. Add legacy glib networking back in
    export GIO_EXTRA_MODULES="${legacyPkgs.glib-networking}/lib/gio/modules"
    
    # 3. Add our dependencies to the LD_LIBRARY_PATH
    export LD_LIBRARY_PATH="$NIX_LD_LIBRARY_PATH:$LD_LIBRARY_PATH"

    # 4. Explicitly point to the AMD/Mesa DRI drivers path - fixes "EGL_BAD_PARAMETER"
    export __EGL_VENDOR_LIBRARY_FILENAMES="${legacyPkgs.mesa.drivers}/share/glvnd/egl_vendor.d/50_mesa.json"

    echo "Garmin SDK Manager Environment Ready: run \`bin/sdkmanager\` to launch the manager"
  '';
}).env
