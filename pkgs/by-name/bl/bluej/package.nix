{ lib, stdenv, fetchurl, openjdk21, openjfx21, glib, dpkg, wrapGAppsHook3 }:
let
  openjdk = openjdk21.override {
    enableJavaFX = true;
    openjfx_jdk = openjfx21.override { withWebKit = true; };
  };
in
stdenv.mkDerivation rec {
  pname = "bluej";
  version = "5.4.1";

  src = fetchurl {
    # We use the deb here. First instinct might be to go for the "generic" JAR
    # download, but that is actually a graphical installer that is much harder
    # to unpack than the deb.
    url = "https://www.bluej.org/download/files/BlueJ-linux-x64-${builtins.replaceStrings ["."] [""] version}.deb";
    sha256 = "sha256-YpFm/CJrZf+tflBqnvda0+opnI+rFjFzVG7v7J/0GJg=";
  };

  nativeBuildInputs = [ dpkg wrapGAppsHook3 ];
  buildInputs = [ glib ];

  dontWrapGApps = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -r usr/* $out

    rm -r $out/share/bluej/jdk
    rm -r $out/share/bluej/javafx
    rm -r $out/share/bluej/javafx-*.jar

    makeWrapper ${openjdk}/bin/java $out/bin/bluej \
      "''${gappsWrapperArgs[@]}" \
      --add-flags "-Dawt.useSystemAAFontSettings=on -Xmx512M \
                   --add-opens javafx.graphics/com.sun.glass.ui=ALL-UNNAMED \
                   -cp $out/share/bluej/boot.jar bluej.Boot"

    runHook postInstall
  '';

  meta = {
    description = "Simple integrated development environment for Java";
    homepage = "https://www.bluej.org/";
    sourceProvenance = with lib.sourceTypes; [ binaryBytecode ];
    license = lib.licenses.gpl2ClasspathPlus;
    mainProgram = "bluej";
    maintainers = with lib.maintainers; [ chvp ];
    platforms = lib.platforms.linux;
  };
}
