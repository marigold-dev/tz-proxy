
{ pkgs, tzproxy }:

let
  baseImage = pkgs.dockerTools.pullImage {
    imageName = "debian";
    imageDigest = "sha256:e25b64a9cf82c72080074d6b1bba7329cdd752d51574971fd37731ed164f3345";
    sha256 = "sha256-Ql7LWpMyRxL3biq3WujAyRJhr80Zy1lFKV2yP8LK/q4=";
    };

in pkgs.dockerTools.buildImage {
  name = "ghcr.io/marigold-dev/tz-proxy";
  tag = "latest";

  fromImage = baseImage;

  contents = [ tzproxy ];

  config = {
    author = "marigold.dev";
    WorkingDir = "/app";
    Entrypoint = [ "${tzproxy}/bin/tzproxy" ];
  };
}
