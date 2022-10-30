{ pkgs, tzproxy }:

let
  baseImage = pkgs.dockerTools.pullImage {
    imageName = "debian";
    imageDigest =
      "sha256:13db79e523a13e3e55b606128a4193d7b9ae788d0c11c95d6a6de0bd30aa3a14";
    sha256 = "sha256-mfmiruXlmu5ksfI2g2AC07KOTiGNfM1vkB2X/QLV/Yg=";
    finalImageTag = "stable";
    finalImageName = "debian";
  };

in pkgs.dockerTools.buildImage {
  name = "ghcr.io/marigold-dev/tz-proxy";
  tag = "latest";

  fromImage = baseImage;

  contents = [ tzproxy ];

  config = {
    author = "marigold.dev";
    architecture = "amd64";
    os = "linux";
    WorkingDir = "/app";
    Entrypoint = [ "${tzproxy}/bin/tzproxy" ];
  };
}
