{ lib
, fetchFromGitHub
, crystal
, makeWrapper
, jq
, remarshal
, nix-prefetch-git
}:

crystal.buildCrystalPackage rec {
  pname = "crystal2nix";
  inherit (lib.importJSON ./meta.json) version;

  src = ./.;

  format = "shards";

  shardsFile = ./shards.nix;

  nativeBuildInputs = [ jq makeWrapper remarshal ];

  postInstall = ''
    wrapProgram $out/bin/crystal2nix \
      --prefix PATH : ${lib.makeBinPath [ nix-prefetch-git ]}
  '';

  # temporarily off. We need the checks to execute the wrapped binary
  doCheck = false;

  doInstallCheck = true;

  meta = with lib; {
    description = "Utility to convert Crystal's shard.lock files to a Nix file";
    license = licenses.mit;
    maintainers = with maintainers; [ manveru peterhoeg ];
    mainProgram = "crystal2nix";
  };
}
