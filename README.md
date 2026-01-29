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
This is a kill switch that configures for local connection as well as forwarding. The PC or netVM can use a local connection while simultaneously sharing or forwarding the connection with other devices (gateway, router, or netVM in Qubes).

### `kill_s_local` / `kill_s_local.sh`
This is a kill switch solely for local connections and prohibits operating as a gateway and blocks forwarding. Ideal for users who only use a device for themselves!

### `kill_s_qubes` / `kill_s_qubes.sh`
This is a kill switch specific to Qubes OS for local connection and forwarding. It performs the same functions as `kill_s.sh` but simplifies configuration and does not require the user to specify the main network interface of the AppVMs in Qubes (default `eth0`) and the standard `tun0` VPN connections in the AppVMs.

## Other Features of This Program
1. Enable Kill Switch for WireGuard
2. Enable Kill Switch for OpenVPN
3. Simple Forward Kill Switch
4. Hard `nmcli` restart
5. Clean iptables rules
6. List firewall rules
7. Bulk configuration of WireGuard `.conf` files
8. Bulk configuration of OpenVPN `.ovpn` files
9. Clean all WireGuard connections
10. Clean all OpenVPN connections
11. Kernel Hardening Rules Just for Local Connections (forward block)
12. Kernel Hardening Using Forward netVM or PC as Gateway Using USB RJ45 Network Card
13. Default Kernel Rules (Commonly Found in Most Linux Distributions)
14. IP Forwarding Configuration for netVM or PC as Gateway Using USB RJ45 Network Card
15. Remove IP Forwarding Configuration for Option 14
16. Configure VPN with kill switch for netVM in `/rw/config` in Qubes OS
17. Exit
```
# Doe monero para nos ajudar: (donate XMR)

    87JGuuwXzoMGwQAcSD7cvS7D7iacPpN2f5bVqETbUvCgdEmrPZa12gh5DSiKKRgdU7c5n5x1UvZLj8PQ7AAJSso5CQxgjak
