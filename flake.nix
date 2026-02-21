{
  description = "Extra k3s configuration modules";

  inputs = {
    nixpkgs = { };
    nix-snapshotter = {
      url = "github:bglgwyng/nix-snapshotter";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nix-snapshotter, ... }:
    {
      nixosModules.default =
        {
          pkgs,
          config,
          lib,
          ...
        }:
        {
          imports = [ nix-snapshotter.nixosModules.default ];

          nixpkgs.overlays = [ nix-snapshotter.overlays.default ];

          services.nix-snapshotter = {
            enable = true;
            settings.image_service.containerd_address = "/run/k3s/containerd/containerd.sock";
          };

          services.k3s = {
            snapshotter = "nix";
            moreFlags = [
              "--write-kubeconfig-mode=644"
              "--image-service-endpoint unix:///run/nix-snapshotter/nix-snapshotter.sock"
            ];

            containerdConfigTemplate = ''
              {{ template "base" . }}

              ${lib.optionalString config.hardware.nvidia-container-toolkit.enable ''
                [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.nvidia]
                  privileged_without_host_devices = false
                  runtime_engine = ""
                  runtime_root = ""
                  runtime_type = "io.containerd.runc.v2"

                [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.nvidia.options]
                  BinaryName = "${pkgs.nvidia-container-toolkit.tools}/bin/nvidia-container-runtime.cdi"
              ''}
              [[plugins."io.containerd.transfer.v1.local".unpack_config]]
                platform = "${pkgs.go.GOOS}/${pkgs.go.GOARCH}"
                snapshotter = "nix"

              [proxy_plugins.nix]
                type = "snapshot"
                address = "/run/nix-snapshotter/nix-snapshotter.sock"
            '';
          };

          systemd.services.k3s.restartTriggers = [
            config.services.k3s.containerdConfigTemplate
          ];
        };
    };
}
