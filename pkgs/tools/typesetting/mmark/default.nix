{ lib, buildGoModule, fetchFromGitHub, testers, mmark }:

buildGoModule rec {
  pname = "mmark";
  version = "2.2.32";

  src = fetchFromGitHub {
    owner = "mmarkdown";
    repo = "mmark";
    rev = "v${version}";
    sha256 = "sha256-2nprmDnfFGau6BtR7nyfqFIlB5JmfzIb5rWsX8C6PK8=";
  };

  vendorHash = "sha256-GjR9cOGLB6URHQi+qcyNbP7rm0+y4wypvgUxgJzIgGQ=";

  ldflags = [ "-s" "-w" ];

  passthru.tests.version = testers.testVersion {
    package = mmark;
  };

  meta = {
    description = "A powerful markdown processor in Go geared towards the IETF";
    homepage = "https://github.com/mmarkdown/mmark";
    license = with lib.licenses; bsd2;
    maintainers = with lib.maintainers; [ yrashk ];
    platforms = lib.platforms.unix;
  };
}
