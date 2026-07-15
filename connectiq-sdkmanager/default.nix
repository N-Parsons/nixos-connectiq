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

  desktopItem = pkgs.makeDesktopItem {
    name = "garmin-sdk-manager";
    desktopName = "Garmin ConnectIQ SDK Manager";
    genericName = "Garmin SDK Manager";
    comment = "Manage Garmin ConnectIQ SDKs and devices";
    exec = "sdkmanager";
    icon = "sdkmanager";
    startupWMClass = "sdkmanager";
    categories = [ "Development" ];
    terminal = false;
    type = "Application";
  };
in
pkgs.stdenv.mkDerivation rec {
  pname = "connectiq-sdk-manager";
  version = "1.0.16"; # Version listed in <zip-file>/share/sdkmanager/changes.html

  # Co-locate the zip file with this configuration, or update this line
  src = ./connectiq-sdk-manager-linux.zip;

  sourceRoot = ".";

  nativeBuildInputs = with pkgs; [
    unzip
    autoPatchelfHook
    makeWrapper
  ];

  # Several packages are inter-related, so exclusively using legacy packages is simpler
  buildInputs = with legacyPkgs; [
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

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    # Create the destination directory in the Nix store
    mkdir -p $out

    # Copy the extracted bin and share folders into the output
    cp -r bin share $out/

    # Register the icon globally by copying it to the pixmaps folder
    mkdir -p $out/share/pixmaps
    cp share/sdkmanager/connectiq-icon.png $out/share/pixmaps/sdkmanager.png

    # Copy the generated desktop file into the package's share directory
    mkdir -p $out/share/applications
    cp ${desktopItem}/share/applications/* $out/share/applications/

    runHook postInstall
  '';

  postFixup = ''
    # Wrap the binaries to inject necessary environment variables
    # - GIO_EXTRA_MODULES and GDK_PIXBUF_MODULE_FILE are unset to clear system conflicts (GVFS)
    # - legacy glib-networking is added
    # - __EGL_VENDOR_LIBRARY_FILENAMES is necessary to fix EGL_BAD_PARAMETER errors (on AMD/Mesa)

    for bin in $out/bin/*; do
      if [ -f "$bin" ] && [ -x "$bin" ]; then
        wrapProgram "$bin" \
          --unset GIO_EXTRA_MODULES \
          --unset GDK_PIXBUF_MODULE_FILE \
          --set GIO_EXTRA_MODULES "${legacyPkgs.glib-networking}/lib/gio/modules" \
          --set __EGL_VENDOR_LIBRARY_FILENAMES "${legacyPkgs.mesa.drivers}/share/glvnd/egl_vendor.d/50_mesa.json"
      fi
    done
  '';
}
