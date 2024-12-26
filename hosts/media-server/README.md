# media server

This server runs a variatie of tasks focussed on providing services like pinchflat, jellyfin

## tasks to solve
Currently the containers have not really managed journal logs, pinchflat had 4 gb of logging.

Cleanup logs
```
sudo du -hs /var/lib/nixos-containers/pinchflat/var/log/journal/* | sort -rh | head -5
```