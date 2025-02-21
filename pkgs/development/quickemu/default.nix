{ lib
, fetchFromGitHub
, stdenv
, makeWrapper
, qemu
, gnugrep
, gnused
, lsb-release
, jq
, procps
, python3
, cdrtools
, usbutils
, util-linux
, socat
, spice-gtk
, swtpm
, unzip
, wget
, xdg-user-dirs
, xrandr
, zsync
, OVMF
, OVMFFull
, quickemu
, testers
, installShellFiles
, fetchpatch
}:
let
  runtimePaths = [
    qemu
    gnugrep
    gnused
    jq
    lsb-release
    procps
    python3
    cdrtools
    usbutils
    util-linux
    unzip
    socat
    swtpm
    wget
    xdg-user-dirs
    xrandr
    zsync
  ];
in

stdenv.mkDerivation rec {
  pname = "quickemu";
  version = "4.9";

  src = fetchFromGitHub {
    owner = "quickemu-project";
    repo = "quickemu";
    rev = version;
    hash = "sha256-ZCHGZb4mdtnNfFBcSqZJRW7fmkTBrWrVko3iwEhO1RY=";
  };

  patches = [
    # https://github.com/quickemu-project/quickemu/pull/815
    (fetchpatch {
      url = "https://github.com/quickemu-project/quickemu/commit/2b9d95a746fd85be0cea48e5544b18dc3ae18d27.patch";
      hash = "sha256-fTJEd3o7LznT1mGwfxXWlW8XM1BmIeId+j8pGjIfIcE=";
    })
  ];

  postPatch = ''
    sed -i \
      -e '/OVMF_CODE_4M.secboot.fd/s|ovmfs=(|ovmfs=("${OVMFFull.fd}/FV/OVMF_CODE.fd","${OVMFFull.fd}/FV/OVMF_VARS.fd" |' \
      -e '/OVMF_CODE_4M.fd/s|ovmfs=(|ovmfs=("${OVMF.fd}/FV/OVMF_CODE.fd","${OVMF.fd}/FV/OVMF_VARS.fd" |' \
      -e '/cp "''${VARS_IN}" "''${VARS_OUT}"/a chmod +w "''${VARS_OUT}"' \
      -e 's/Icon=.*qemu.svg/Icon=qemu/' \
      quickemu
  '';

  nativeBuildInputs = [ makeWrapper installShellFiles ];

  installPhase = ''
    runHook preInstall

    installManPage docs/quickget.1 docs/quickemu.1 docs/quickemu_conf.1
    install -Dm755 -t "$out/bin" macrecovery quickemu quickget windowskey

    # spice-gtk needs to be put in suffix so that when virtualisation.spiceUSBRedirection
    # is enabled, the wrapped spice-client-glib-usb-acl-helper is used
    for f in macrecovery quickget quickemu windowskey; do
      wrapProgram $out/bin/$f \
        --prefix PATH : "${lib.makeBinPath runtimePaths}" \
        --suffix PATH : "${lib.makeBinPath [ spice-gtk ]}"
    done

    runHook postInstall
  '';

  passthru.tests = testers.testVersion { package = quickemu; };

  meta = with lib; {
    description = "Quickly create and run optimised Windows, macOS and Linux desktop virtual machines";
    homepage = "https://github.com/quickemu-project/quickemu";
    license = licenses.mit;
    maintainers = with maintainers; [ fedx-sudo ];
  };
}
