# iSponsorBlockTV 

Currently installed as running docker container.

https://github.com/dmunozv04/iSponsorBlockTV/wiki/Installation

Sit at the TV, and link a device to create the configuration:

```
docker run --rm -it -v /mnt/isponsorblocktv:/app/data --net=host ghcr.io/dmunozv04/isponsorblocktv --setup-cli
```

```
docker run -d --name iSponsorBlockTV1 --restart=unless-stopped -v /mnt/isponsortv:/app/data ghcr.io/dmunozv04/isponsorblocktv
```
