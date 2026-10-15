{
  lib,
  nix-update-script,
  fetchFromGitHub,
  buildGoModule,
  curl,
  lsof,
  steady,
}:

buildGoModule (finalAttrs: {
  pname = "ant-cli";
  version = "1.40.0";

  __structuredAttrs = true;

  src = fetchFromGitHub {
    owner = "anthropics";
    repo = "anthropic-cli";
    tag = "v${finalAttrs.version}";
    hash = "sha256-QSLnddizdaSSnhaI7y9M+6BPYjTT0DEGlFVzpSm7d/U=";
  };

  vendorHash = "sha256-P14dv/e/6HEZH84x9SFrNZRqBGI4rlLyRWyxKETiPIM=";

  postPatch = ''
    # Use the packaged mock server instead of downloading it through npm.
    mockCommand='npm exec --package=@stdy/cli@[0-9.]+ -- steady'
    for script in scripts/mock scripts/test; do
      grep -qE "$mockCommand" "$script"
      sed -E -i "s|$mockCommand|steady|g" "$script"
    done
    patchShebangs scripts/mock scripts/test
  '';

  nativeCheckInputs = [
    curl
    lsof
    steady
  ];

  __darwinAllowLocalNetworking = true;

  checkPhase = ''
    runHook preCheck
    # The mock tests locate cmd/ant relative to their Go source files.
    export GOFLAGS=''${GOFLAGS//-trimpath/}
    ./scripts/test -p "$NIX_BUILD_CORES" -vet=off $checkFlags
    runHook postCheck
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "The CLI for the Claude API";
    homepage = "https://github.com/anthropics/anthropic-cli";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ munksgaard ];
    mainProgram = "ant";
  };
})
