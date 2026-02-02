# k3s-extras

A NixOS module that enables NVIDIA container runtime and nix-snapshotter for k3s.

Example usage with your NixOS configuration with k3s-extras:

```nix
{
  inputs = {
    nixpkgs = { };
    k3s-extras = {
      url = "github:bglgwyng/k3s-extras";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs =
    { k3s-extras, ... }:
    {
      nixosModules.default =
        { lib, config, pkgs, ... }:
        {

          imports = [ k3s-extras.nixosModules.default ]; # Just import k3s-extras!

          hardware.nvidia-container-toolkit = {
            enable = true;
          };

          hardware.graphics = {
            enable = true;
            enable32Bit = true;
          };

          services.xserver.videoDrivers = [ "nvidia" ];

          hardware.nvidia.open = false;

          networking = {
            firewall = {
              allowedTCPPorts = [ 6443 ];
              allowedUDPPorts = [ 8472 ];
            };
          };

          services.k3s = {
            enable = true;
            role = "server";
            clusterInit = true;
          };
        };
    };
}
```
