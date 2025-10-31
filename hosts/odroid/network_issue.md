# network issues 31-10-2025

For a while the nixos containers didn't have network... 
Was fixed by creating the NAT rule again with uptables:

```bash
sudo iptables -t nat -A POSTROUTING -s 192.168.100.0/24 ! -d 192.168.100.0/24 -j MASQUERADE
```
