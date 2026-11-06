{
  lib,
  buildNpmPackage,
  copyDesktopItems,
  electron_45,
  fetchFromGitHub,
  jq,
  makeDesktopItem,
  makeWrapper,
  nodejs_24,
  stdenv,
}:
let
  version = "1.0.1";
  electron = electron_45;
  description = "Unofficial desktop application for the open-source design tool, Penpot";
  icon = "penpot";
in
buildNpmPackage {
  pname = "penpot-desktop";
  inherit version;
  nodejs = nodejs_24;

  src = fetchFromGitHub {
    owner = "author-more";
    repo = "penpot-desktop";
    tag = "v${version}";
    hash = "sha256-8m3q2hSDwDKstTxVt9NVVB3y2O5kmac7RcY6oDswAmY=";
  };

  npmDepsHash = "sha256-7u5+MILiIHybHsEgYg+GDGPujlxgaOTxaZ3MKdb3wWU=";
  makeCacheWritable = true;
  npmFlags = [
    "--engine-strict"
    "--legacy-peer-deps"
  ];
  dontNpmBuild = true;
  env.ELECTRON_SKIP_BINARY_DOWNLOAD = "1";

  nativeBuildInputs = [
    copyDesktopItems
    jq
    makeWrapper
  ];

  preBuild = ''
    if [[ $(jq --raw-output '.devDependencies.electron' < package.json | grep -E --only-matching '\^[0-9]+' | sed -e 's/\^//') != ${lib.escapeShellArg (lib.versions.major electron.version)} ]]; then
      echo 'ERROR: electron version mismatch' >&2
      exit 1
    fi
  '';

  postBuild = ''
    npm exec electron-builder -- \
      --dir \
      --publish=never \
      --c.electronDist=${electron.dist} \
      --c.electronVersion=${electron.version}
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/opt/Penpot"
    pushd dist/linux-${lib.optionalString stdenv.hostPlatform.isAarch64 "arm64-"}unpacked
    cp -r locales resources{,.pak} "$out/opt/Penpot"
    popd

    makeWrapper '${lib.getExe electron}' "$out/bin/penpot-desktop" \
      --add-flags "$out/opt/Penpot/resources/app.asar" \
      --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations --enable-wayland-ime=true}}" \
      --set-default ELECTRON_IS_DEV 0 \
      --inherit-argv0

    install -Dm444 build/icon.png "$out/share/icons/hicolor/512x512/apps/${icon}.png"
    install -Dm444 LICENSE "$out/share/doc/penpot-desktop/LICENSE"

    runHook postInstall
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "Penpot";
      exec = "penpot-desktop %U";
      inherit icon;
      comment = description;
      desktopName = "Penpot";
      categories = [ "Graphics" ];
    })
  ];

  meta = {
    inherit description;
    homepage = "https://github.com/author-more/penpot-desktop";
    changelog = "https://github.com/author-more/penpot-desktop/releases/tag/v${version}";
    license = lib.licenses.agpl3Only;
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
    mainProgram = "penpot-desktop";
  };
}
