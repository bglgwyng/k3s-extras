{
  description = "Example GPU pod using nix-snapshotter";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nix-snapshotter = {
      url = "github:bglgwyng/nix-snapshotter?ref=deprecate-patch-k3s-embedded-containerd";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, nix-snapshotter, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = [ nix-snapshotter.overlays.default ];
      };

      name = "cuda-hello";

      cuda-hello = pkgs.stdenv.mkDerivation {
        pname = "cuda-hello";
        version = "0.1.0";
        src = ./src;
        nativeBuildInputs = [
          pkgs.cudaPackages.cuda_nvcc
          pkgs.autoAddDriverRunpath
        ];
        buildInputs = [ pkgs.cudaPackages.cuda_cudart ];
        buildPhase = ''
          nvcc -o cuda-hello main.cu
        '';
        installPhase = ''
          mkdir -p $out/bin
          cp cuda-hello $out/bin/
        '';
      };

      image = pkgs.nix-snapshotter.buildImage {
        inherit name;
        resolvedByNix = true;
        config = {
          entrypoint = [ "${cuda-hello}/bin/cuda-hello" ];
          env = [
            "NVIDIA_VISIBLE_DEVICES=all"
            "NVIDIA_DRIVER_CAPABILITIES=compute,utility"
          ];
        };
      };

      pod-manifest = pkgs.writeText "${name}-pod.json" (
        builtins.toJSON {
          apiVersion = "v1";
          kind = "Pod";
          metadata = {
            inherit name;
            labels = { inherit name; };
          };
          spec = {
            runtimeClassName = "nvidia";
            restartPolicy = "Never";
            containers = [
              {
                inherit name;
                image = "nix:0${image}";
              }
            ];
          };
        }
      );
    in
    {
      packages.${system} = {
        default = pod-manifest;
        inherit cuda-hello image pod-manifest;
      };

      apps.${system}.deploy-pod = {
        type = "app";
        program = toString (
          pkgs.writeShellScript "deploy-pod" ''
            ${pkgs.k3s}/bin/kubectl apply -f ${pod-manifest}
          ''
        );
      };
    };
}
