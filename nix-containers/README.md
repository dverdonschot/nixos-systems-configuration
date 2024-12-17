# Nix Containers with Tailscale

Tailscale is a programmable network that allows you to connect hosts all over the worl in a flat network, and it's free for up to 100 hosts.
It also allows you to get a free HTTPS certificate with every tailscale connection you make.
But that is only 1 certificate per host, with Nixos Containers we can create containers that have a individual hostnames.
We configure [Caddy](https://caddyserver.com/) to use the port hosted by the app or docker container and open a reverse proxy on port 443 with HTTPS.
Now every service we run automaticly gets a nice hostname, a certificate and is running on https with port 443.

You can run both normal nix configuration, and docker containers (configured with nix) inside [Nixos Containers](https://nixos.wiki/wiki/NixOS_Containers)

Because I don't want to leave any secrets around you just have to login to the container and login to Tailscale the first time.
In tailscale you can configure the key to not expire.


```bash
# search is the name of this nixos container in all examples.
sudo nixos-container root-login search
tailscale login
```

After you login the tailscale connection should be up almost instantly, but the https certificate needs to be generated and can take up to a few minutes.

The `nixos-container` is also available as a `systemd` service:

```bash
sudo systemctl status container@search.service
```

## nix-container modules

In  the `nix-containers` folder I created all my containers that I like to run.
I build them like nixos modules with a number of parameters, like tailNet.
These modules can then be imported in the main config and configured.

## Network dependencies needed in main Nixos host

The nixos-containers are running in a NAT network, this network needs to be configured on the Nixos host.

```nix
  # Enable networking
  networking = {
    networkmanager = {
      enable = true;
      # added for nixos containers
      unmanaged = ["interface-name:ve-*"];
    };

    # added for nixos containers
    nat = {
      enable = true;
      internalInterfaces = ["ve-+"];
      externalInterface = "wlan0";
      enableIPv6 = false;
    };
  };
```

## How to import on main Nixos host

Import the container module `search-container.nix`

```nix
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      <home-manager/nixos>
      ../../nix-containers/search-container.nix
    ];
```

Now use the service:

```
  services.search-container = {
    enable = true;
    tailNet = "tail5bbc4.ts.net";
    ipAddress = "192.168.100.25";
  };
```

## usage of nixos-container command

```bash
sudo nixos-container root-login search
sudo nixos-container stop search
sudo nixos-container start search

# Destroy a container including its file system
sudo nixos-container destroy search
```

## Preformance implications

I am running docker containers inside systemd nspawn containers. So far I have not really noticed a performance issue running 6 or 7 containers on a Odroid H3+. Hosted apps are blazingly fast and very stable. 

## Alternatives

[TSDProxy](https://nixos.wiki/wiki/NixOS_Containers) allows you to create docker containers and get https certificates, in a very similar way with docker labels.
If setup correctly it will automaticly add and remove docker containers to your tailscale network and setup the HTTPS connection.
However I had problems with containers that had multiple ports, maybe those are fixed by now, it was still very new.
