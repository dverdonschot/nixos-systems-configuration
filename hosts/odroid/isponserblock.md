# iSponsorBlockTV 

Currently installed as running docker container.

https://github.com/dmunozv04/iSponsorBlockTV/wiki/Installation

Sit at the TV, and link a device to create the configuration:

```
sudo docker run --rm -it -v /mnt/data/isponsorblocktv:/app/data --net=host ghcr.io/dmunozv04/isponsorblocktv --setup-cli
```

```
sudo docker run -d --name iSponsorBlockTV1 --restart=unless-stopped -v /mnt/data/isponsorblocktv:/app/data ghcr.io/dmunozv04/isponsorblocktv
```
