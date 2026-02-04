# Iptables Sentinel Kill Switch for WireGuard and OpenVPN
## How to Install

```bash
sudo chmod +x kill_s.sh kill_s kill_s_local kill_s_local.sh kill_s_qubes kill_s_qubes.sh
```

## Execute

With any example file:
```bash
sudo ./kill_s.sh
```
or
```bash
sudo cp -r kill_s /bin
```
Then just type `kill_s` from anywhere in the terminal.

## What Each Script Does

### `kill_s.sh` / `kill_s`
This can be configured for a local connection as well as for forwarding. It’s ideal for users who use a device exclusively for themselves. The PC or NetVM can maintain a local connection while simultaneously sharing or forwarding that connection to other devices (gateway, router, or another NetVM in Qubes). An additional option enables a kill‑switch mode that allows only local connections, prevents the device from acting as a gateway, and blocks any forwarding.


### `kill_s_qubes` / `kill_s_qubes.sh`
This is a kill switch specific to Qubes OS for local connection and forwarding. It performs the same functions as `kill_s.sh` but simplifies configuration and does not require the user to specify the main network interface of the AppVMs in Qubes (default `eth0`) and the standard `tun0` VPN connections in the AppVMs.

## Other Features of This Program
1) Enable Kill Switch for Wireguard or Openvpn
2) USB RJ45 Kill Switch
3) Hard nmcli restart
4) Clean iptables rules
5) List firewall rules
6) Bulk configuration of WireGuard .conf files
7) Bulk configuration of OpenVPN .ovpn files
8) Clean all wireguard connections
9) Clean all openvpn connections
10) Kernel Hardening Rules Just for Local Connections (forward block)
11) Kernel Hardening Using Forward netVM or PC as Gateway Using USB RJ45 Netcard
12) Default Kernel Rules (Commonly Found in Most Linux Distributions)
13) IP Forwarding Configuration for netVM or PC as Gateway Using USB RJ45 Network Card
14) Remove IP Forwarding Configuration for Option 14
15) Configure VPN with kill switch for netVM in /rw/config in Qubes OS (local and forward kill switch)
16) Configure VPN with kill switch for netVM in /rw/config in Qubes OS (just forward kill switch)
17) Exit

```
# Doe monero para nos ajudar: (donate XMR)

    87JGuuwXzoMGwQAcSD7cvS7D7iacPpN2f5bVqETbUvCgdEmrPZa12gh5DSiKKRgdU7c5n5x1UvZLj8PQ7AAJSso5CQxgjak
