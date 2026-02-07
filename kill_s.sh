#!/bin/bash

# Check if the script is run as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run this script as root or use sudo."
    sleep 3
    exit 1
fi

# Check if iptables is installed
if ! command -v iptables &> /dev/null; then
    echo "iptables is not installed. Exiting..."
    sleep 3
    exit 1
fi

# Check if nmcli is installed
if ! command -v nmcli &> /dev/null; then
    echo "Network Manager (nmcli) is not installed. Exiting..."
    sleep 3
    exit 1
fi

# Check if OpenVPN is installed
if ! command -v openvpn &> /dev/null; then
    echo "OpenVPN is not installed. Exiting..."
    sleep 3
    exit 1
fi


usb_rj45_conf()
{

block_scan
nmcli_hard_restart
block_input_usbrj45
#variables
#default network for external interface
rede="10.42.0.0/24";


echo "USB Network Adapter - Forward Mode";
echo "Checking modules for external interface";
echo "lsmod | grep r8152";
lsmod | grep r8152
echo "";
echo "Activating modules for external interface r8152";
echo "sudo modprobe r8152";
sudo modprobe r8152
echo "";
echo "Checking if your external interface is recognized";
echo "lsusb";
lsusb


echo "";
# Ask the user if they want to proceed or exit
echo "-----------------------------------------------------------------------------------------------------------------------------";
echo "Check if your interface is visible above..."
echo "For the best configuration, just connect the Ethernet cable to your USB adapter after completing all configurations here..."
echo "Do you want to continue or exit? (c for continue, e for exit)"
echo "-----------------------------------------------------------------------------------------------------------------------------";
read choice

# Check the user's choice
if [ "$choice" == "c" ]; then
    echo "Continuing the program..."
    echo "";
    # Add further commands to continue the program
    # Example: 
    # lsusb
    # or any other logic to proceed with the program
elif [ "$choice" == "e" ]; then
    echo "Exiting the program..."
    exit 0
    echo "";
else
    echo "Invalid input, please enter 'c' to continue or 'e' to exit."
    # Optionally, loop the question or terminate
    exit 1
    echo "";
fi



echo "List of network interfaces, bridges, vlans etc... and connections with uuid";

# Listing all network interfaces using the ip command
echo "-----------------------------------------------";
interfaces=$(ip link show | grep -oP '^\d+: \K\w+')

# Displaying the interfaces in a single line
echo "$interfaces"
echo;
echo "nmcli connection show";
nmcli connection show
echo "-----------------------------------------------";
echo;

# Ask if the desired interface connection exists
echo "Does the connection for the desired interface exist?"
read -rp "Do you want to create a connection and set up a forward mode for the device? (yes/no): " create_connection

if [[ "$create_connection" == "yes" ]]; then
    # Ask for the connection name
    read -rp "Enter the connection name: " con_name
    echo "The chosen connection name is: $con_name"
    read -rp "Enter the name of your interface: " interface
    echo "The chosen interface is: $interface"
    
    # Create the connection with shared IPv4 method
    echo "Creating connection with the name $con_name and setting IPv4 method to shared..."
    echo "sudo nmcli connection add type ethernet con-name "$con_name" ifname "$interface" ipv4.method shared";
    sudo nmcli connection add type ethernet con-name "$con_name" ifname "$interface" ipv4.method shared ipv4.address "$rede";

else
    # If the connection already exists, configure the interface directly
    echo "You chose not to create a new connection."
    
    # Ask for the external interface name
    read -rp "Enter the name of UUID of your USB external interface: " uuid
    echo "The chosen interface is: $uuid"
    read -rp "Enter the name of your interface: " interface
    echo "The chosen interface is: $interface"
    
    # Configuring the external interface for forwarding
    echo "Configuring the external interface $uuid to forward connection to the outside (FORWARD)..."
    echo "sudo nmcli connection modify "$uuid" ipv4.method shared"
    sudo nmcli connection modify "$uuid" ipv4.method shared ipv4.address "$rede";
fi


echo "";
echo "Enable IP forwarding by writing '1' to the /proc/sys/net/ipv4/ip_forward and /proc/sys/net/ipv4/conf/all/forwarding";
sudo echo 1 > /proc/sys/net/ipv4/ip_forward
sudo echo 1 > /proc/sys/net/ipv4/conf/all/forwarding
echo "cat /proc/sys/net/ipv4/ip_forward";
cat /proc/sys/net/ipv4/ip_forward
echo "cat /proc/sys/net/ipv4/conf/all/forwarding";
cat /proc/sys/net/ipv4/conf/all/forwarding;
echo;


# Check if IP forwarding is enabled in /etc/sysctl.conf and
# Check if /etc/sysctl.conf.bak already exists
if [ -f "/etc/sysctl.conf.bak" ]; then
    # If the backup file exists, no action is needed
    echo "Backup /etc/sysctl.conf.bak already exists. No need to create a new one."
else
    # If the backup file does not exist, create the backup
    echo "Backing up /etc/sysctl.conf"
    sudo cp -r /etc/sysctl.conf /etc/sysctl.conf.bak
    echo "Backup created as /etc/sysctl.conf.bak"
    echo;
fi

# Check if the necessary lines exist (commented or uncommented) and remove them if they do
echo "Ensuring IP forwarding is properly configured in /etc/sysctl.conf"
echo "options"
echo "net.ipv4.ip_forward = 1";
echo "net/ipv4/conf/all/forwarding = 1";
echo "must be activated... see below...";

# Remove any existing lines related to ip_forward and forwarding (commented or uncommented)
sudo sed -i '/^\s*#\?\s*net.ipv4.ip_forward = 1/d' /etc/sysctl.conf
sudo sed -i '/^\s*#\?\s*net.ipv4.conf.all.forwarding = 1/d' /etc/sysctl.conf

# Add the necessary lines with comments explaining them
echo ""
echo "# Enabling IP forwarding for IPv4. This allows the system to forward packets between network interfaces." | sudo tee -a /etc/sysctl.conf > /dev/null
echo "net.ipv4.ip_forward = 1" | sudo tee -a /etc/sysctl.conf > /dev/null
echo ""

echo "# Enabling packet forwarding for all interfaces. This setting applies to all network interfaces for packet forwarding." | sudo tee -a /etc/sysctl.conf > /dev/null
echo "net.ipv4.conf.all.forwarding = 1" | sudo tee -a /etc/sysctl.conf > /dev/null
echo ""

# Apply the changes to sysctl immediately without reboot
sudo sysctl -p
echo "IP forwarding has been enabled and configured."
echo;

echo "Verify the network type you're using!"
echo "ip route";
ip route
echo

rede_now=($(ip route | grep -oP '\d+\.\d+\.\d+\.\d+/[0-9]+'))
rede_now1="${rede_now[0]}"
rede_now2="${rede_now[1]}"
echo "Network found: $rede_now1"
echo "Network found: $rede_now2"
echo;

# Check if the current network is the same as the default network and display a warning.
if [[ "$rede_now1" == "$rede" || "$rede_now2" == "$rede" ]]; then
    echo "Warning: The default network $rede is the same as your current network."
    echo "Please change the network to avoid conflicts!"
    echo;
# Force the user to select a different network.
    echo "Examples of networks: 192.168.0.0/24, 10.0.0.0/24, 172.16.0.0/24"
    read -rp "Enter the network address for the USB network adapter: " rede
    echo "You chose the network: $rede"
    echo;
    echo "uuid of the connections and interfaces";
    echo "-----------------------------------------------";
interfaces=$(ip link show | grep -oP '^\d+: \K\w+')

# Displaying the interfaces in a single line
echo "$interfaces"
echo;
echo "nmcli connection show";
nmcli connection show
echo "-----------------------------------------------";
        
    read -rp "Enter the uuid of connection USB network adapter: " uuid
    echo "You chose the network: $uuid"
    echo;
    echo "sudo nmcli con modify "$uuid" ipv4.method shared ipv4.address "$rede";";
    sudo nmcli con modify "$uuid" ipv4.method shared ipv4.address "$rede";
    nmcli;
    nmcli connection show;
    
    else
    echo "Do you want to use the default network $rede or choose another network address?"
echo "Press 1 for the default network"
echo "Press 2 to choose another network"
read -rp "Enter your choice: " choice

if [[ "$choice" == "1" ]]; then
echo;
    echo "You chose the default network."
    
elif [[ "$choice" == "2" ]]; then
echo;
     echo "Examples of networks: 192.168.0.0/24, 10.0.0.0/24, 172.16.0.0/24"
    read -rp "Enter the network address for the USB network adapter: " rede
    echo "You chose the network: $rede"
    echo;
    echo "uuid of the connections and interfaces";
echo "-----------------------------------------------";
interfaces=$(ip link show | grep -oP '^\d+: \K\w+')

# Displaying the interfaces in a single line
echo "$interfaces"
echo;
echo "nmcli connection show";
nmcli connection show
echo "-----------------------------------------------";
        
    read -rp "Enter the uuid of connection USB network adapter: " uuid
    echo "You chose the network: $uuid"
    echo;
    echo "sudo nmcli con modify "$uuid" ipv4.method shared ipv4.address "$rede";";
    sudo nmcli con modify "$uuid" ipv4.method shared ipv4.address "$rede";
    echo;
echo "-----------------------------------------------";
interfaces=$(ip link show | grep -oP '^\d+: \K\w+')

# Displaying the interfaces in a single line
echo "$interfaces"
echo;
echo "nmcli connection show";
nmcli connection show
echo "-----------------------------------------------";
   
else
echo;
    echo "Invalid choice. Please run the script again and choose either 1 or 2. Finishing the script in 20 seconds"
    sleep 20;
    exit 1
    
fi
fi
echo "Your USB RJ45 network interface has been configured in the Network Manager to share internet with other devices";
echo;
}


block_scan()
{
# Turn off the network, clean iptables rules, add POLICE BLOCK ALL, and turn on the network again to set new rules safe to connect VPN.
# Safe against scanning attacks during VPN connection while cleaning iptables rules and with the firewall accepting all.
# Use the rules of the block_input() method from Leandro Ibov.
# After the VPN is connected, these rules can be erased for new firewall rules to complete the kill switch process.
echo "Turn off network"
sudo nmcli networking off
clean_iptables #method to clean iptables rules
echo "DROP input, forward, and output policies for all iptables applied."
sudo iptables -P INPUT DROP   
sudo iptables -P FORWARD DROP
sudo iptables -P OUTPUT DROP
echo "Turn on network and waiting 7 seconds"
sudo nmcli networking on
sleep 7
}

#if is not in qubes, need $network variabel be used
# User needs nmcli to show that the USB RJ45 interface is turned off, and nmcli connection show does not allow it.
block_input_usbrj45()
{
echo "Anti-scan iptables rules added to protect the VPN connection and usbrj45 in unsafe networks."
echo "-----------------------------------------------";
interfaces=$(ip link show | grep -oP '^\d+: \K\w+')

# Displaying the interfaces in a single line
echo "$interfaces"
echo;
echo "nmcli connection show";
nmcli connection show
echo "-----------------------------------------------";
echo
read -p "Enter the name of the primary network interface (Getting Network type for anti‑scan firewall): " network
sudo iptables -P INPUT DROP
sudo iptables -P FORWARD ACCEPT
sudo iptables -P OUTPUT ACCEPT
sudo iptables -A INPUT -i lo -j ACCEPT
sudo iptables -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
# Get the IP address and netmask of the network interface (assuming eth0, adjust if needed)
ip_info=$(ip addr show $network | grep 'inet ' | awk '{print $2}')
ip="${ip_info%%/*}"         # Extract the IP address (e.g., 192.168.0.10)
mask="${ip_info##*/}"       # Extract the netmask (e.g., 24)

# Calculate the network address based on the mask
IFS='.' read -r i1 i2 i3 i4 <<< "$ip"

# Determine the network address based on the mask
if [ "$mask" -eq 24 ]; then
    network="${i1}.${i2}.${i3}.0/24"
elif [ "$mask" -eq 16 ]; then
    network="${i1}.${i2}.0.0/16"
elif [ "$mask" -eq 8 ]; then
    network="${i1}.0.0.0/8"
else
    # For other masks, still using the original IP with mask
    network="$ip/$mask"
fi
sudo iptables -A INPUT -p tcp --syn -s "$network" -j ACCEPT
sudo iptables -A INPUT -p tcp -m tcp --tcp-flags FIN,SYN,RST,ACK SYN -j DROP
}


#about line: 
#ip_info=$(ip addr show $network | grep 'inet ' | awk '{print $2}')
#Is necessary get primary interface for $network to work
block_input()
{
echo "Anti-scan iptables rules added to protect the VPN connection in unsafe networks."
nmcli connection show
echo
read -p "Enter the name of the primary network interface (Getting Network type for anti‑scan firewall): " network
# Setting default policies
######################
sudo iptables -P INPUT DROP   # Set the default policy of the INPUT chain to DROP everything
sudo iptables -P FORWARD DROP
sudo iptables -P OUTPUT ACCEPT

# Allowing Loopback
####################
sudo iptables -A INPUT -i lo -j ACCEPT
sudo iptables -A FORWARD -i lo -j DROP

## Internet security rules and access
## Replace ethx with the appropriate interface, check using ifconfig
#####################################
sudo iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
sudo iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j DROP

# Blocking new connections and invalid connections after an established connection
sudo iptables -A INPUT -m state --state INVALID -j DROP
sudo iptables -A FORWARD -m state --state INVALID -j DROP
sudo iptables -A INPUT -m state --state NEW -j DROP

# Get the IP address and netmask of the network interface (assuming eth0, adjust if needed)
ip_info=$(ip addr show $network | grep 'inet ' | awk '{print $2}')
ip="${ip_info%%/*}"         # Extract the IP address (e.g., 192.168.0.10)
mask="${ip_info##*/}"       # Extract the netmask (e.g., 24)

# Calculate the network address based on the mask
IFS='.' read -r i1 i2 i3 i4 <<< "$ip"

# Determine the network address based on the mask
if [ "$mask" -eq 24 ]; then
    network="${i1}.${i2}.${i3}.0/24"
elif [ "$mask" -eq 16 ]; then
    network="${i1}.${i2}.0.0/16"
elif [ "$mask" -eq 8 ]; then
    network="${i1}.0.0.0/8"
else
    # For other masks, still using the original IP with mask
    network="$ip/$mask"
fi

# Add the rule to iptables
sudo iptables -A INPUT -p tcp --syn -s "$network" -j ACCEPT
#echo "Rule added for network: $network/255.255.255.0"
sudo iptables -A INPUT -p tcp --syn -j DROP;
sudo iptables -A INPUT -i ppp0 -p udp --dport 0:30000 -j DROP;
}


erase_block_input_rules()
{
echo "Erasing anti-scan rules after safe VPN connection.";
# Delete the rule that allows established and related connections in the INPUT chain
sudo iptables -D INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Delete the rule that allows established and related connections in the FORWARD chain
sudo iptables -D FORWARD -m state --state ESTABLISHED,RELATED -j DROP

# Delete the rule that allows loopback traffic in the INPUT chain
sudo iptables -D INPUT -i lo -j ACCEPT

# Delete the rule that drops loopback traffic in the FORWARD chain
sudo iptables -D FORWARD -i lo -j DROP

# Delete the rule that blocks new invalid connections in the INPUT chain
sudo iptables -D INPUT -m state --state INVALID -j DROP

# Delete the rule that blocks new invalid connections in the FORWARD chain
sudo iptables -D FORWARD -m state --state INVALID -j DROP

# Delete the rule that blocks new connections in the INPUT chain
sudo iptables -D INPUT -m state --state NEW -j DROP

# Delete the rule that blocks all SYN packets (unsolicited)
sudo iptables -D INPUT -p tcp --syn -j DROP

# Delete the rule that drops UDP traffic on ppp0 for ports 0 to 30000
sudo iptables -D INPUT -i ppp0 -p udp --dport 0:30000 -j DROP

# Get the IP address and netmask of the network interface (assuming eth0, adjust if needed)
ip_info=$(ip addr show eth0 | grep 'inet ' | awk '{print $2}')
ip="${ip_info%%/*}"         # Extract the IP address (e.g., 192.168.0.10)
mask="${ip_info##*/}"       # Extract the netmask (e.g., 24)

# Calculate the network address based on the mask
IFS='.' read -r i1 i2 i3 i4 <<< "$ip"

# Determine the network address based on the mask
if [ "$mask" -eq 24 ]; then
    network="${i1}.${i2}.${i3}.0/24"
elif [ "$mask" -eq 16 ]; then
    network="${i1}.${i2}.0.0/16"
elif [ "$mask" -eq 8 ]; then
    network="${i1}.0.0.0/8"
else
    # For other masks, still using the original IP with mask
    network="$ip/$mask"
fi
# Delete the rule that allows SYN packets from a specific network
sudo iptables -D INPUT -p tcp --syn -s "$network" -j ACCEPT
}


netcard_conn()
{
# List network interfaces and prompt user for input
echo
echo "Available network interfaces:"
#netcard=$(nmcli device status | awk '$3 == "connected" {print $1}')
#echo "$netcard"
nmcli connection show

read -p "Enter the name of the primary network interface: " netcard

# List WireGuard or OpenVPN connections and prompt user for input
echo
echo "Available connections:"
#conn=$(nmcli connection show | awk '{print $1}' | tail -n +2)
#echo "$conn"
nmcli connection show
read -p "Enter the name of VPN connection: " conn
echo

}

kill_s_usbrj45()
{
# Loop until a valid choice is made
echo
while true; do
    # Ask the user to configure USB RJ45 interface or not
    echo "1. Do you want to configure your USB RJ45 or other interfaces in the Network Manager (nmcli)?"
    echo "2. You do not want to configure, as you've already done it and wish to proceed."
    read -p "Please enter your choice (1 or 2): " choice

    if [[ "$choice" == "1" ]]; then
        usb_rj45_conf  # Call the function to configure the USB RJ45 interface
        break  # Exit the loop after a valid choice

    elif [[ "$choice" == "2" ]]; then
        echo "Proceeding with the setup..."
        break  # Exit the loop after a valid choice

    else
        echo "Invalid choice. Please select either 1 or 2."
    fi
done


# Loop until a valid choice is made
echo
while true; do
    # Ask the user for the type of firewall choice
    echo "Do you want a kill switch with a firewall for insecure networks or a clean firewall for testing or other purposes in secure networks?"
    echo "1. With anti-scan firewall"
    echo "2. Clean firewall without rules"
    read -p "Please enter your choice (1 or 2): " choice

    if [[ "$choice" == "1" ]]; then
        block_scan      # Call the function to block scans
        nmcli_hard_restart  # Restart the Network Manager
        block_input_usbrj45  # Block input for the USB RJ45
        break  # Exit the loop after executing the functions

    elif [[ "$choice" == "2" ]]; then
        clean_iptables  # Call the function to clean iptables
        break  # Exit the loop after executing the function

    else
        echo "Invalid choice. Please select either 1 or 2."
    fi
done

# List network interfaces and prompt user for input
echo
echo "Available network interfaces:"
#netcard=$(nmcli connection show)
#echo "$netcard"
nmcli connection show
read -p "Enter the name of the primary network interface: " netcard

echo
echo "Check VPN connections to initiate a connection:"
nmcli connection show
read -p "Enter the name of the VPN connection: " conn_vpn
nmcli connection up "$conn_vpn"

#função_erase_aqui

# List WireGuard or OpenVPN connections and prompt user for input
echo
echo "Checking the status of the USB RJ45 interface:"
nmcli connection show
# Prompt user to check the status of the USB RJ45 interface
echo
echo "Have you checked if your USB RJ45 interface is down? Do you want to bring it up? (y/n)"
read user_response

if [[ "$user_response" == "y" ]]; then
    echo "Please enter the name of the interface:"
    read conn
    nmcli connection up "$conn"
    # Check the exit status of the last command
if [[ $? -ne 0 ]]; then
    echo "The network interface is not active or there was an error recognizing the interface."
else
    echo "The network interface is now active."
fi

else
    echo "Continuing without bringing up the interface. Remember, the kill switch will only work if it is up!"
fi

echo
# Check public IP address after connecting to VPN
echo "Your public IP address is:"
curl -s https://api.ipify.org
echo;
echo;
# Ask if the user wants to proceed
read -p "Do you want to proceed with the kill switch to USB RJ45? The VPN must be working (y/n).: " user_response

if [[ "$user_response" == "y" ]]; then
    echo "Activating kill switch..."
    
    # Activate the kill switch using iptables
    sudo iptables -I FORWARD -o "$netcard" -j DROP
    sudo iptables -I FORWARD -i "$netcard" -j DROP
    sudo ip6tables -I FORWARD -o "$netcard" -j DROP
    sudo ip6tables -I FORWARD -i "$netcard" -j DROP
    
    echo "Kill switch activated."
else
echo "Kill switch with iptables not activated."
fi
echo
}

#network manager hard restart
nmcli_hard_restart()
{
echo "Hard nmcli Restarting network"
sudo systemctl stop NetworkManager;
sudo systemctl disable NetworkManager;
sudo systemctl enable NetworkManager;
sudo systemctl start NetworkManager;
echo
}


clean_iptables()
{
echo "Clean all iptables rules"
sudo iptables -F  
sudo iptables -X  
sudo iptables -Z  

sudo iptables -P INPUT ACCEPT;
sudo iptables -P FORWARD ACCEPT;
sudo iptables -P OUTPUT ACCEPT;

sudo iptables -t filter -F;
sudo iptables -t filter -X;
sudo iptables -t filter -Z;

sudo iptables -t nat -F;
sudo iptables -t nat -X;
sudo iptables -t nat -Z;

sudo iptables -t mangle -F;
sudo iptables -t mangle -X;
sudo iptables -t mangle -Z;


sudo iptables -t raw -F;
sudo iptables -t raw -X;
sudo iptables -t raw -Z;
}


# Function to set up kill switch for wireguard
kill_s() 
{
    local conn="$1"
    local netcard="$2"

# List active WireGuard or OpenVPN connections
active_connections=$(nmcli connection show --active | grep -E 'wireguard|openvpn' | awk '{print $1}')

if [[ -z "$active_connections" ]]; then
    echo "No active connections found."
fi

# Display active connections
echo "Active connections:"
echo "$active_connections"

# Loop through the active connections and disconnect them
for conn in $active_connections; do
    echo "Disconnecting: $conn"
    nmcli connection down "$conn"
done

echo "All active connections have been disabled."
echo;


nmcli_hard_restart
sleep 5
netcard_conn

    echo "Configuring kill switch for connection: $conn on interface: $netcard..."


    # Reset and connect WireGuard or OpenVPN
    sleep 2
block_scan
block_input
    nmcli connection up "$conn"
    sleep 7

    # Default policy to drop everything
    iptables -P INPUT DROP
    iptables -P FORWARD DROP
    iptables -P OUTPUT DROP

erase_block_input_rules

    # Allow loopback traffic
    iptables -A INPUT -i lo -j ACCEPT
    iptables -A OUTPUT -o lo -j ACCEPT

    # Allow established/related connections
    iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
    iptables -A OUTPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

    # Permit all traffic through the connection interface
    iptables -A OUTPUT -o "$conn" -j ACCEPT
    iptables -A INPUT -i "$conn" -j ACCEPT

    # Reject traffic that tries to leave via the physical NIC
    iptables -A OUTPUT -o "$netcard" -j REJECT --reject-with icmp-host-unreachable
    iptables -A INPUT -i "$netcard" -j REJECT --reject-with icmp-host-unreachable

    # Allow forwarding for the tun VPN connection
    iptables -I FORWARD -o "$conn" -j ACCEPT
    iptables -I FORWARD -i "$conn" -j ACCEPT
    ip6tables -I FORWARD -o "$conn" -j ACCEPT
    ip6tables -I FORWARD -i "$conn" -j ACCEPT
echo
}

#Function to set kill switch for openvpn .ovpn
kill_s_ovpn() 
{

    local conn="$1"
    local netcard="$2"

# List active WireGuard or OpenVPN connections
active_connections=$(nmcli connection show --active | grep -E 'wireguard|openvpn' | awk '{print $1}')

if [[ -z "$active_connections" ]]; then
    echo "No active connections found."
fi

# Display active connections
echo "Active connections:"
echo "$active_connections"

# Loop through the active connections and disconnect them
for conn in $active_connections; do
    echo "Disconnecting: $conn"
    nmcli connection down "$conn"
done

echo "All active connections have been disabled."
echo;


nmcli_hard_restart
sleep 5
netcard_conn

    echo "Configuring kill switch for connection: $conn on interface: $netcard..."

    # Reset and connect WireGuard or OpenVPN
    sleep 2
block_scan
block_input
    nmcli connection up "$conn"
    sleep 7

    # Default policy to drop everything
    iptables -P INPUT DROP
    iptables -P FORWARD DROP
    iptables -P OUTPUT DROP

erase_block_input_rules

    # Allow loopback traffic
    iptables -A INPUT -i lo -j ACCEPT
    iptables -A OUTPUT -o lo -j ACCEPT

    # Allow established/related connections
    iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
    iptables -A OUTPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

    # Permit all traffic through the connection interface - not necessary, works without it
    #iptables -A OUTPUT -o "$conn" -j ACCEPT
    #iptables -A INPUT -i "$conn" -j ACCEPT

    # Reject traffic that tries to leave via the physical NIC
    iptables -A OUTPUT -o "$netcard" -j REJECT --reject-with icmp-host-unreachable
    iptables -A INPUT -i "$netcard" -j REJECT --reject-with icmp-host-unreachable

    # Allow forwarding for the VPN connection - not necessary, works without it
    #iptables -I FORWARD -o "$conn" -j ACCEPT
    #iptables -I FORWARD -i "$conn" -j ACCEPT
    #ip6tables -I FORWARD -o "$conn" -j ACCEPT
    #ip6tables -I FORWARD -i "$conn" -j ACCEPT

    #treating openvpn tun connection for kill switch
echo
echo "Choosing virtual network interface to kill switch (tun0, tun1, tun2...):"
#conn=$(nmcli connection show | awk '{print $1}' | tail -n +2)
#echo "$conn"
nmcli connection show
read -p "Enter the name of virtual network interface (tun0, tun1, tun2 etc...): " conn

    # Permit all traffic through the tun interface for local user
    iptables -A OUTPUT -o "$conn" -j ACCEPT
    iptables -A INPUT -i "$conn" -j ACCEPT

    # Allow forwarding for tun VPN connection
    iptables -I FORWARD -o "$conn" -j ACCEPT
    iptables -I FORWARD -i "$conn" -j ACCEPT
    ip6tables -I FORWARD -o "$conn" -j ACCEPT
    ip6tables -I FORWARD -i "$conn" -j ACCEPT
echo
}

local_kill_s_ovpn() 
{

    local conn="$1"
    local netcard="$2"

# List active WireGuard or OpenVPN connections
active_connections=$(nmcli connection show --active | grep -E 'wireguard|openvpn' | awk '{print $1}')

if [[ -z "$active_connections" ]]; then
    echo "No active WireGuard connections found."
fi

# Display active connections
echo "Active WireGuard connections:"
echo "$active_connections"

# Loop through the active connections and disconnect them
for conn in $active_connections; do
    echo "Disconnecting: $conn"
    nmcli connection down "$conn"
done

echo "All active connections have been disabled."
echo;


nmcli_hard_restart
sleep 5
netcard_conn

    echo "Configuring kill switch for connection: $conn on interface: $netcard..."

    # Reset and connect WireGuard or OpenVPN
    sleep 2
block_scan
block_input
    nmcli connection up "$conn"
    sleep 7

    # Default policy to drop everything
    iptables -P INPUT DROP
    iptables -P FORWARD DROP
    iptables -P OUTPUT DROP

erase_block_input_rules

    # Allow loopback traffic
    iptables -A INPUT -i lo -j ACCEPT
    iptables -A OUTPUT -o lo -j ACCEPT

    # Allow established/related connections
    iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
    iptables -A OUTPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

    # Permit all traffic through the connection interface - not necessary, works without it
    #iptables -A OUTPUT -o "$conn" -j ACCEPT
    #iptables -A INPUT -i "$conn" -j ACCEPT

    # Reject traffic that tries to leave via the physical NIC
    iptables -A OUTPUT -o "$netcard" -j REJECT --reject-with icmp-host-unreachable
    iptables -A INPUT -i "$netcard" -j REJECT --reject-with icmp-host-unreachable

    # Allow forwarding for the VPN connection - not necessary, works without it
    #iptables -I FORWARD -o "$conn" -j ACCEPT
    #iptables -I FORWARD -i "$conn" -j ACCEPT
    #ip6tables -I FORWARD -o "$conn" -j ACCEPT
    #ip6tables -I FORWARD -i "$conn" -j ACCEPT

    #treating openvpn tun connection for kill switch
echo
echo "Choosing virtual network interface to kill switch (tun0, tun1, tun2...):"
#conn=$(nmcli connection show | awk '{print $1}' | tail -n +2)
#echo "$conn"
nmcli connection show
read -p "Enter the name of virtual network interface (tun0, tun1, tun2 etc...): " conn

    # Permit all traffic through the tun interface for local user
    iptables -A OUTPUT -o "$conn" -j ACCEPT
    iptables -A INPUT -i "$conn" -j ACCEPT

# It is a local kill switch; it is not necessary to allow forwarding for the kill switch.
    # Allow forwarding for tun VPN connection
    #iptables -I FORWARD -o "$conn" -j ACCEPT
    #iptables -I FORWARD -i "$conn" -j ACCEPT
    #ip6tables -I FORWARD -o "$conn" -j ACCEPT
    #ip6tables -I FORWARD -i "$conn" -j ACCEPT
echo
}

local_kill_s() 
{
    local conn="$1"
    local netcard="$2"

# List active WireGuard or OpenVPN connections
active_connections=$(nmcli connection show --active | grep -E 'wireguard|openvpn' | awk '{print $1}')

if [[ -z "$active_connections" ]]; then
    echo "No active WireGuard connections found."
fi

# Display active connections
echo "Active WireGuard connections:"
echo "$active_connections"

# Loop through the active connections and disconnect them
for conn in $active_connections; do
    echo "Disconnecting: $conn"
    nmcli connection down "$conn"
done

echo "All active connections have been disabled."
echo;


nmcli_hard_restart
sleep 5
netcard_conn

    echo "Configuring kill switch for connection: $conn on interface: $netcard..."


    # Reset and connect WireGuard or OpenVPN
    sleep 2
block_scan
block_input
    nmcli connection up "$conn"
    sleep 7

    # Default policy to drop everything
    iptables -P INPUT DROP
    iptables -P FORWARD DROP
    iptables -P OUTPUT DROP

erase_block_input_rules

    # Allow loopback traffic
    iptables -A INPUT -i lo -j ACCEPT
    iptables -A OUTPUT -o lo -j ACCEPT

    # Allow established/related connections
    iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
    iptables -A OUTPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

    # Permit all traffic through the connection interface
    iptables -A OUTPUT -o "$conn" -j ACCEPT
    iptables -A INPUT -i "$conn" -j ACCEPT

    # Reject traffic that tries to leave via the physical NIC
    iptables -A OUTPUT -o "$netcard" -j REJECT --reject-with icmp-host-unreachable
    iptables -A INPUT -i "$netcard" -j REJECT --reject-with icmp-host-unreachable

# It is a local kill switch; it is not necessary to allow forwarding for the kill switch.
    # Allow forwarding for the tun VPN connection
    #iptables -I FORWARD -o "$conn" -j ACCEPT
    #iptables -I FORWARD -i "$conn" -j ACCEPT
    #ip6tables -I FORWARD -o "$conn" -j ACCEPT
    #ip6tables -I FORWARD -i "$conn" -j ACCEPT
echo
}

local_or_local_forward()
{
echo
while true; do
    # Ask the user to configure local or local and forward kill switch
    echo "1. Local Kill Switch for OpenVPN"
    echo "2. Local Kill Switch for WireGuard"
    echo "3. Local and Forward Kill Switch for OpenVPN (Qubes netVM/Virtual Interfaces)"
    echo "4. Local and Forward Kill Switch for WireGuard (Qubes netVM/Virtual Interfaces)"
    read -p "Please enter your choice (1, 2, 3 or 4): " choice

    if [[ "$choice" == "1" ]]; then
        local_kill_s_ovpn
break  # Exit the loop after a valid choice

    elif [[ "$choice" == "2" ]]; then
        local_kill_s
break  # Exit the loop after a valid choice

    elif [[ "$choice" == "3" ]]; then
        kill_s_ovpn
        break  # Exit the loop after a valid choice

    elif [[ "$choice" == "4" ]]; then
        kill_s
        break  # Exit the loop after a valid choice

    else
        echo "Invalid choice. Please select either 1 or 2."
    fi
done
}

#bonus methods
clean_all_wireguards()
{
echo
# Command to save wireguard connections to a temporary file
sudo nmcli connection show | grep wireguard > /dev/shm/list.txt

# Read each line from the list.txt
while IFS= read -r line
do
    # Extract the first field (VPN wireguard name)
    vpn_name=$(echo "$line" | awk '{print $1}')

    # Check if vpn_name wireguard is not empty
    if [ -n "$vpn_name" ]; then
        # Execute the delete command
        echo "Deleting connection: $vpn_name"
        if sudo nmcli connection delete "$vpn_name"; then
            echo "Successfully deleted: $vpn_name"
        else
            echo "Failed to delete: $vpn_name"
        fi
    fi
done < /dev/shm/list.txt
sudo rm -rf /dev/shm/list.txt
echo
}



clean_all_openvpn()
{
echo
# Command to save VPN connections to a temporary file
sudo nmcli connection show | grep vpn > /dev/shm/list.txt

# Read each line from the list.txt
while IFS= read -r line
do
    # Extract the first field (VPN name)
    vpn_name=$(echo "$line" | awk '{print $1}')

    # Check if vpn_name is not empty
    if [ -n "$vpn_name" ]; then
        # Execute the delete command
        echo "Deleting connection: $vpn_name"
        if sudo nmcli connection delete "$vpn_name"; then
            echo "Successfully deleted: $vpn_name"
        else
            echo "Failed to delete: $vpn_name"
        fi
    fi
done < /dev/shm/list.txt
sudo rm -rf /dev/shm/list.txt
echo
}

wireguard2()
{
echo
# -----------------------------------------------------------------
# 1️⃣ Prompt the user for the directory that holds the .conf files
# -----------------------------------------------------------------
read -p "Enter the full path to the folder containing WireGuard .conf files: " WG_DIR

# Strip a trailing slash (if any) for consistency
WG_DIR="${WG_DIR%/}"

# Verify that the directory exists
if [[ ! -d "$WG_DIR" ]]; then
    echo "Error: directory \"$WG_DIR\" does not exist."
    exit 1
fi

# 4️⃣ Copy **all** files (including hidden ones) to /etc/wireguard
#    -a  → archive mode (preserves permissions, owners, timestamps, symlinks)
#    "$WG_DIR"/. → the *contents* of the directory, not the directory itself
sudo cp -a "$WG_DIR"/. /etc/wireguard/

# 5️⃣ Tighten permissions – only root may read the private keys
sudo chown root:root /etc/wireguard/*.conf
sudo chmod 600 /etc/wireguard/*.conf

# 6️⃣ Update the variable so the rest of the script can keep using $WG_DIR
WG_DIR="/etc/wireguard"

echo "All WireGuard configuration files have been copied to $WG_DIR"


# -----------------------------------------------------------------
# 2️⃣ Process each .conf file found in the supplied directory
# -----------------------------------------------------------------
shopt -s nullglob   # makes the loop skip if no .conf files exist
found_any=false

for cfg in "$WG_DIR"/*.conf; do
    found_any=true
    # Connection name = filename without the .conf extension
    conn_name="$(basename "$cfg" .conf)"

    echo "Importing \"$cfg\" as connection \"$conn_name\"..."

    # 2.1️⃣ Import the WireGuard profile
    nmcli connection import type wireguard file "$cfg"

    # 2.2️⃣ Disable autoconnect for this connection
    nmcli connection modify "$conn_name" connection.autoconnect no

    # 2.3️⃣ Ensure the connection is down (ignore errors if it wasn't up)
    nmcli connection down "$conn_name" 2>/dev/null || true

    echo "Connection \"$conn_name\" configured."
done

if ! $found_any; then
    echo "No .conf files were found in \"$WG_DIR\"."
else
    echo "All WireGuard configurations have been processed."
fi
echo
}


openvpn2()
{
echo
# -----------------------------------------------------------------
# 1️⃣ Prompt for the directory that holds the .ovpn files
# -----------------------------------------------------------------
read -p "Enter the full path to the folder containing .ovpn files: " OVPN_DIR

# Remove a possible trailing slash for consistency
OVPN_DIR="${OVPN_DIR%/}"

# Verify that the directory exists
if [[ ! -d "$OVPN_DIR" ]]; then
    echo "Error: directory \"$OVPN_DIR\" does not exist."
    exit 1
fi

# -----------------------------------------------------------------
# 2️⃣ Prompt for VPN credentials
# -----------------------------------------------------------------
read -p "Enter VPN username: " VPN_USER
read -s -p "Enter VPN password: " VPN_PASS
echo   # newline after hidden password entry

# Simple validation
if [[ -z "$VPN_USER" || -z "$VPN_PASS" ]]; then
    echo "Error: Both username and password must be provided."
    exit 1
fi

# -----------------------------------------------------------------
# 3️⃣ Process each .ovpn file in the supplied directory
# -----------------------------------------------------------------
shopt -s nullglob   # skip the loop if no .ovpn files are present
found_any=false

for cfg in "$OVPN_DIR"/*.ovpn; do
    found_any=true
    # Derive a clean connection name from the filename (strip extension)
    conn_name="$(basename "$cfg" .ovpn)"

    echo "Importing \"$cfg\" as connection \"$conn_name\"..."

    # 3.1️⃣ Import the OpenVPN profile
    nmcli connection import type openvpn file "$cfg"

    # 3.2️⃣ Ensure the connection ID matches the desired name
    nmcli connection modify "$conn_name" connection.id "$conn_name"

   # 3️⃣ Set the username (vpn.user-name) and the password (vpn.secrets)
    nmcli connection modify "$conn_name" \
       vpn.user-name "$VPN_USER" \
        +vpn.secrets "password=$VPN_PASS" \
        +vpn.data "password-flags=0"

    # 3.4️⃣ (Optional) Bring the connection down after configuration
    nmcli connection down "$conn_name" 2>/dev/null || true

    echo "Connection \"$conn_name\" configured (username + password stored)."
done

if ! $found_any; then
    echo "No .ovpn files were found in \"$OVPN_DIR\"."
else
    echo "All OpenVPN profiles have been processed successfully."
fi
echo
}

iptables_rules()
{
sudo echo "";
echo "############################ Iptables Rules ############################"
sudo echo "";
sudo echo "############################ Table Filter #########################";
sudo iptables -t filter -S;
sudo echo "";

sudo echo "############################ Table Nat ############################";
sudo iptables -t nat -S;
sudo echo "";

sudo echo "############################ Table Mangle #########################";
sudo iptables -t mangle -S;
sudo echo "";

sudo echo "############################ Table Raw ############################";
sudo iptables -t raw -S;
sudo echo "###################################################################";
sudo echo "";

}

kernel_hardening_local()
{
# Disabling traffic between the interfaces - prevents connection sharing from the PC to the external RJ45 interface or access point Wi-Fi
# Need to create an option in the script with sudo echo 1 > /proc/sys/net/ipv4/ip_forward; to allow the external interface and access point to function.
sudo echo 0 > /proc/sys/net/ipv4/ip_forward;

# Protection against ping, SYN Cookies, IP Spoofing, and kernel protections
sudo echo 1 > /proc/sys/net/ipv4/tcp_syncookies;

# Syn Flood (DoS) # Port scanners
sudo echo 1 > /proc/sys/net/ipv4/icmp_echo_ignore_broadcasts; 

# Secure packet redirection
sudo echo 1 > $i/secure_redirects; 

# Broadcast echo protection enabled.
sudo echo 0 > /proc/sys/net/ipv4/conf/all/forwarding;

# Log strange packets.
sudo echo 1 > /proc/sys/net/ipv4/conf/all/log_martians;

# Bad error message protection enabled.
sudo echo 1 > /proc/sys/net/ipv4/icmp_ignore_bogus_error_responses; 

# IP spoofing protection.
sudo echo 1 > /proc/sys/net/ipv4/conf/all/rp_filter;

# Disable ICMP redirect acceptance.
sudo echo 0 > /proc/sys/net/ipv4/conf/all/accept_redirects;
sudo echo 0 > /proc/sys/net/ipv4/conf/all/send_redirects;

# Disable source routed packets.
sudo echo 0 > /proc/sys/net/ipv4/conf/all/accept_source_route;

# No tracert and ping
sudo echo 1 > /proc/sys/net/ipv4/icmp_echo_ignore_all;
echo
echo "Disabling traffic forwarding to prevent connection sharing."
echo "sudo echo 0 > /proc/sys/net/ipv4/ip_forward"

echo ""

echo "Enabling TCP SYN cookies to protect against SYN flood attacks."
echo "sudo echo 1 > /proc/sys/net/ipv4/tcp_syncookies"

echo ""

echo "Ignoring ICMP echo broadcasts to prevent DoS attacks from port scanners."
echo "sudo echo 1 > /proc/sys/net/ipv4/icmp_echo_ignore_broadcasts"

echo ""

echo "Enabling secure packet redirection."
echo "sudo echo 1 > $i/secure_redirects"

echo ""

echo "Disabling forwarding for broadcast echo protection."
echo "sudo echo 0 > /proc/sys/net/ipv4/conf/all/forwarding"

echo ""

echo "Enabling logging for strange packets (martians)."
echo "sudo echo 1 > /proc/sys/net/ipv4/conf/all/log_martians"

echo ""

echo "Enabling protection against bogus error messages."
echo "sudo echo 1 > /proc/sys/net/ipv4/icmp_ignore_bogus_error_responses"

echo ""

echo "Enabling IP spoofing protection."
echo "sudo echo 1 > /proc/sys/net/ipv4/conf/all/rp_filter"

echo ""

echo "Disabling ICMP redirect acceptance."
echo "sudo echo 0 > /proc/sys/net/ipv4/conf/all/accept_redirects"
echo "sudo echo 0 > /proc/sys/net/ipv4/conf/all/send_redirects"

echo ""

echo "Disabling acceptance of source routed packets."
echo "sudo echo 0 > /proc/sys/net/ipv4/conf/all/accept_source_route"

echo ""

echo "Ignoring ICMP echo requests to disable tracert and ping responses."
echo "sudo echo 1 > /proc/sys/net/ipv4/icmp_echo_ignore_all"

}

kernel_hardening_forward()
{
# Alowing traffic between the interfaces to forward works in netVMs or gateways
sudo echo 1 > /proc/sys/net/ipv4/ip_forward;

# Protection against ping, SYN Cookies, IP Spoofing, and kernel protections
sudo echo 1 > /proc/sys/net/ipv4/tcp_syncookies;

# Syn Flood (DoS) # Port scanners
sudo echo 1 > /proc/sys/net/ipv4/icmp_echo_ignore_broadcasts; 

# Secure packet redirection
sudo echo 1 > $i/secure_redirects; 

# Broadcast echo protection enabled.
sudo echo 0 > /proc/sys/net/ipv4/conf/all/forwarding;

# Log strange packets.
sudo echo 1 > /proc/sys/net/ipv4/conf/all/log_martians;

# Bad error message protection enabled.
sudo echo 1 > /proc/sys/net/ipv4/icmp_ignore_bogus_error_responses; 

# IP spoofing protection.
sudo echo 1 > /proc/sys/net/ipv4/conf/all/rp_filter;

# Disable ICMP redirect acceptance.
sudo echo 0 > /proc/sys/net/ipv4/conf/all/accept_redirects;
sudo echo 0 > /proc/sys/net/ipv4/conf/all/send_redirects;

# Disable source routed packets.
sudo echo 1 > /proc/sys/net/ipv4/conf/all/accept_source_route;

# No tracert and ping
sudo echo 1 > /proc/sys/net/ipv4/icmp_echo_ignore_all;
echo
echo "Allowing traffic between interfaces to enable forwarding for netVMs or gateways."
echo "sudo echo 1 > /proc/sys/net/ipv4/ip_forward"

echo ""

echo "Enabling TCP SYN cookies for protection against SYN flood attacks."
echo "sudo echo 1 > /proc/sys/net/ipv4/tcp_syncookies"

echo ""

echo "Ignoring ICMP echo broadcasts to prevent attacks from SYN flood and port scanners."
echo "sudo echo 1 > /proc/sys/net/ipv4/icmp_echo_ignore_broadcasts"

echo ""

echo "Enabling secure packet redirection."
echo "sudo echo 1 > $i/secure_redirects"

echo ""

echo "Disabling forwarding for broadcast echo protection."
echo "sudo echo 0 > /proc/sys/net/ipv4/conf/all/forwarding"

echo ""

echo "Enabling logging for strange packets (martians)."
echo "sudo echo 1 > /proc/sys/net/ipv4/conf/all/log_martians"

echo ""

echo "Enabling protection against bogus error messages."
echo "sudo echo 1 > /proc/sys/net/ipv4/icmp_ignore_bogus_error_responses"

echo ""

echo "Enabling IP spoofing protection."
echo "sudo echo 1 > /proc/sys/net/ipv4/conf/all/rp_filter"

echo ""

echo "Disabling ICMP redirect acceptance."
echo "sudo echo 0 > /proc/sys/net/ipv4/conf/all/accept_redirects"
echo "sudo echo 0 > /proc/sys/net/ipv4/conf/all/send_redirects"

echo ""

echo "Disabling acceptance of source routed packets."
echo "sudo echo 1 > /proc/sys/net/ipv4/conf/all/accept_source_route"

echo ""

echo "Ignoring ICMP echo requests to disable tracert and ping responses."
echo "sudo echo 1 > /proc/sys/net/ipv4/icmp_echo_ignore_all"

echo
}

default_kernel_rules()
{
# Enable IP forwarding (default is usually 0, but set according to your needs)
sudo echo 0 > /proc/sys/net/ipv4/ip_forward;

# Protection against ping, SYN Cookies (default is usually 0, but commonly used as 1)
sudo echo 0 > /proc/sys/net/ipv4/tcp_syncookies;

# Syn Flood (DoS) - default is typically 1; port scanners might be ignored by default
sudo echo 0 > /proc/sys/net/ipv4/icmp_echo_ignore_broadcasts; 

# Remove secure packet redirection (this typically isn't set by default; you might not even need this line)
sudo echo 0 > /proc/sys/net/ipv4/conf/all/secure_redirects; 

# Broadcast echo protection is usually enabled by default (set to 0 to disable)
sudo echo 1 > /proc/sys/net/ipv4/conf/all/forwarding;

# Logging strange packets is often off, but can be enabled based on needs
sudo echo 0 > /proc/sys/net/ipv4/conf/all/log_martians;

# Bad error message protection disabled by default (usually set to 0)
sudo echo 0 > /proc/sys/net/ipv4/icmp_ignore_bogus_error_responses; 

# Default for IP spoofing protection is usually enabled (1)
sudo echo 1 > /proc/sys/net/ipv4/conf/all/rp_filter;

# Default for ICMP redirect acceptance is typically set to 1
sudo echo 1 > /proc/sys/net/ipv4/conf/all/accept_redirects;
sudo echo 1 > /proc/sys/net/ipv4/conf/all/send_redirects;

# Default for source routed packets is usually set to 0
sudo echo 0 > /proc/sys/net/ipv4/conf/all/accept_source_route;

# Tracert and ping responses are usually enabled by default (1)
sudo echo 0 > /proc/sys/net/ipv4/icmp_echo_ignore_all;
echo
echo "Enabling IP forwarding (default is usually 0; adjust according to your needs)."
echo "sudo echo 0 > /proc/sys/net/ipv4/ip_forward"

echo ""

echo "Setting TCP SYN cookies protection (default is usually 0; commonly used as 1)."
echo "sudo echo 0 > /proc/sys/net/ipv4/tcp_syncookies"

echo ""

echo "Disabling ICMP echo broadcasts protection against Syn Flood (default is typically 1)."
echo "sudo echo 0 > /proc/sys/net/ipv4/icmp_echo_ignore_broadcasts"

echo ""

echo "Removing secure packet redirection (typically not set by default; might be unnecessary)."
echo "sudo echo 0 > /proc/sys/net/ipv4/conf/all/secure_redirects"

echo ""

echo "Disabling broadcast echo protection (usually enabled by default)."
echo "sudo echo 1 > /proc/sys/net/ipv4/conf/all/forwarding"

echo ""

echo "Disabling logging for strange packets (often off, enable based on needs)."
echo "sudo echo 0 > /proc/sys/net/ipv4/conf/all/log_martians"

echo ""

echo "Disabling protection against bogus error messages (usually set to 0)."
echo "sudo echo 0 > /proc/sys/net/ipv4/icmp_ignore_bogus_error_responses"

echo ""

echo "Enabling IP spoofing protection (default is usually 1)."
echo "sudo echo 1 > /proc/sys/net/ipv4/conf/all/rp_filter"

echo ""

echo "Enabling ICMP redirect acceptance (typically set to 1)."
echo "sudo echo 1 > /proc/sys/net/ipv4/conf/all/accept_redirects"
echo "sudo echo 1 > /proc/sys/net/ipv4/conf/all/send_redirects"

echo ""

echo "Disabling acceptance of source routed packets (usually set to 0)."
echo "sudo echo 0 > /proc/sys/net/ipv4/conf/all/accept_source_route"

echo ""

echo "Disabling tracert and ping responses (usually enabled by default)."
echo "sudo echo 0 > /proc/sys/net/ipv4/icmp_echo_ignore_all"

echo
}

ip_forward_conf()
{
echo "";
echo "Enable IP forwarding by writing '1' to the /proc/sys/net/ipv4/ip_forward and /proc/sys/net/ipv4/conf/all/forwarding";
sudo echo 1 > /proc/sys/net/ipv4/ip_forward
sudo echo 1 > /proc/sys/net/ipv4/conf/all/forwarding
echo "cat /proc/sys/net/ipv4/ip_forward";
cat /proc/sys/net/ipv4/ip_forward
echo "cat /proc/sys/net/ipv4/conf/all/forwarding";
cat /proc/sys/net/ipv4/conf/all/forwarding;
echo;


# Check if IP forwarding is enabled in /etc/sysctl.conf and
# Check if /etc/sysctl.conf.bak already exists
if [ -f "/etc/sysctl.conf.bak" ]; then
    # If the backup file exists, no action is needed
    echo "Backup /etc/sysctl.conf.bak already exists. No need to create a new one."
else
    # If the backup file does not exist, create the backup
    echo "Backing up /etc/sysctl.conf"
    sudo cp -r /etc/sysctl.conf /etc/sysctl.conf.bak
    echo "Backup created as /etc/sysctl.conf.bak"
    echo;
fi

# Check if the necessary lines exist (commented or uncommented) and remove them if they do
echo "Ensuring IP forwarding is properly configured in /etc/sysctl.conf"
echo "options"
echo "net.ipv4.ip_forward = 1";
echo "net/ipv4/conf/all/forwarding = 1";
echo "must be activated... see below...";


# Remove any existing lines related to ip_forward and forwarding (commented or uncommented)
sudo sed -i '/^\s*#\?\s*net.ipv4.ip_forward = 1/d' /etc/sysctl.conf
sudo sed -i '/^\s*#\?\s*net.ipv4.conf.all.forwarding = 1/d' /etc/sysctl.conf

# Add the necessary lines with comments explaining them
echo ""
echo "# Enabling IP forwarding for IPv4. This allows the system to forward packets between network interfaces." | sudo tee -a /etc/sysctl.conf > /dev/null
echo "net.ipv4.ip_forward = 1" | sudo tee -a /etc/sysctl.conf > /dev/null
echo ""

echo "# Enabling packet forwarding for all interfaces. This setting applies to all network interfaces for packet forwarding." | sudo tee -a /etc/sysctl.conf > /dev/null
echo "net.ipv4.conf.all.forwarding = 1" | sudo tee -a /etc/sysctl.conf > /dev/null
echo ""

# Apply the changes to sysctl immediately without reboot
sudo sysctl -p
echo "IP forwarding has been enabled and configured."
echo "What was done here?"
echo "Enable IP forwarding by setting it to '1' in /proc/sys/net/ipv4/ip_forward and /proc/sys/net/ipv4/conf/all/forwarding."
echo "Display current values of IP forwarding and forwarding settings."
echo "Check if a backup of /etc/sysctl.conf exists; if not, create one."
echo "Ensure IP forwarding settings are correctly configured in /etc/sysctl.conf:"
echo "Remove any existing lines related to 'net.ipv4.ip_forward' and 'net.ipv4.conf.all.forwarding'."
echo "Add necessary lines to enable IP forwarding and packet forwarding for all interfaces, with explanatory comments."
echo "Apply changes to the sysctl configuration immediately."
echo
}

no_ip_forward()
{
echo
# Disable IP forwarding by writing '0' to the relevant files
echo "Disabling IP forwarding..."
sudo echo 0 > /proc/sys/net/ipv4/ip_forward
sudo echo 0 > /proc/sys/net/ipv4/conf/all/forwarding
echo "IP forwarding disabled."

# Restore sysctl configurations from backup if the backup exists
if [ -f "/etc/sysctl.conf.bak" ]; then
    echo "Restoring original /etc/sysctl.conf from backup..."
    sudo cp /etc/sysctl.conf.bak /etc/sysctl.conf
    echo "Restored original /etc/sysctl.conf."
else
    echo "No backup found. Skipping restoration of /etc/sysctl.conf."
fi

# Remove lines related to IP forwarding in /etc/sysctl.conf
echo "Removing any leftover IP forwarding configurations from /etc/sysctl.conf..."
sudo sed -i '/^\s*#\?\s*net.ipv4.ip_forward/d' /etc/sysctl.conf
sudo sed -i '/^\s*#\?\s*net.ipv4.conf.all.forwarding/d' /etc/sysctl.conf

# Apply the changes to sysctl
echo "Applying changes to sysctl..."
sudo sysctl -p
echo "Restoration complete. All configurations are set to default."

}

netvm_qubes()
{
# Create origina rc.local file as backup
sudo tee /rw/config/rc.local > /dev/null <<'EOF'
#!/bin/sh

# This script will be executed at every VM startup, you can place your own
# custom commands here. This includes overriding some configuration in /etc,
# starting services etc.
#
# Executable scripts located in /rw/config/rc.local.d with the extension
# '.rc' are executed immediately before this rc.local.
# Example:
#  /rw/config/rc.local.d/custom.rc
#
# Example for overriding the whole CUPS configuration:
#  rm -rf /etc/cups
#  ln -s /rw/config/cups /etc/cups
#  systemctl --no-block restart cups

EOF
sudo cp -r /rw/config/rc.local /rw/config/rc.local.bak

# Prompt the user to choose a connection type
echo "Choose your VPN connection type:"
echo "1) WireGuard"
echo "2) OpenVPN"
read -p "Enter choice (1 or 2): " vpn_choice

# List available connections
echo "Available connections:"
#conn=$(nmcli connection show | awk '{print $1}' | tail -n +2)
#echo "$conn"
nmcli connection show
# Check if any connections were found
#if [ -z "$conn" ]; then
#    echo "No connections found. Please add a connection manually."
#    exit 1
#fi

# Read the name of the VPN connection
read -p "Enter the name of VPN connection: " conn
echo

# Ensure the user entry is not empty
#if [ -z "$conn" ]; then
#    echo "VPN connection name cannot be empty."
#    exit 1
#fi

# Common IP tables configurations
setup_iptables() 
{
    echo "" | sudo tee -a /rw/config/rc.local
    echo "Setting up iptables..."
    {
        echo "iptables -P INPUT ACCEPT"
        echo "iptables -P FORWARD ACCEPT"
        echo "iptables -P OUTPUT ACCEPT"
        echo "iptables -t filter -F"
        echo "iptables -t nat -F"
        echo "iptables -t mangle -F"
        echo "iptables -t raw -F"
        echo "iptables -F"
        echo "iptables -X"
        echo "iptables -Z"
        echo "nmcli connection up "$conn""
        echo "sleep 3"
        echo "nmcli connection up "$conn""
        echo "sleep 3"
        echo "nmcli connection up "$conn""
        echo "sleep 3"
        echo "iptables -P INPUT DROP"
        echo "iptables -P FORWARD DROP"
        echo "iptables -P OUTPUT DROP"


        if [[ "$vpn_choice" == "1" ]]; then
            # WireGuard settings
echo "iptables -A INPUT -i lo -j ACCEPT"
echo "iptables -A OUTPUT -o lo -j ACCEPT"
echo "iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT"
echo "iptables -A OUTPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT"
echo "iptables -A OUTPUT -o $conn -j ACCEPT"
echo "iptables -A INPUT -i $conn -j ACCEPT"
echo "iptables -A OUTPUT -o eth0 -j REJECT --reject-with icmp-host-unreachable"
echo "iptables -A INPUT -i eth0 -j REJECT --reject-with icmp-host-unreachable"
echo "iptables -I FORWARD -o $conn -j ACCEPT"
echo "iptables -I FORWARD -i $conn -j ACCEPT"
echo "ip6tables -I FORWARD -o $conn -j ACCEPT"
echo "ip6tables -I FORWARD -i $conn -j ACCEPT"

        elif [[ "$vpn_choice" == "2" ]]; then
            # OpenVPN settings
echo "iptables -A INPUT -i lo -j ACCEPT"
echo "iptables -A OUTPUT -o lo -j ACCEPT"
echo "iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT"
echo "iptables -A OUTPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT"
echo "iptables -A OUTPUT -o eth0 -j REJECT --reject-with icmp-host-unreachable"
echo "iptables -A INPUT -i eth0 -j REJECT --reject-with icmp-host-unreachable"
echo "iptables -A OUTPUT -o tun0 -j ACCEPT"
echo "iptables -A INPUT -i tun0 -j ACCEPT"
echo "iptables -I FORWARD -o tun0 -j ACCEPT"
echo "iptables -I FORWARD -i tun0 -j ACCEPT"
echo "ip6tables -I FORWARD -o tun0 -j ACCEPT"
echo "ip6tables -I FORWARD -i tun0 -j ACCEPT"

        else
            echo "Invalid choice."
            exit 1
        fi
    } | sudo tee -a /rw/config/rc.local
}

setup_iptables
echo
echo "/rw/config/rc.local"
cat /rw/config/rc.local
echo
echo "/rw/config/qubes-firewall-user-script"
cat /rw/config/qubes-firewall-user-script
echo

}

netvm_qubes_just_forward()
{
# Create origina rc.local file as backup
sudo tee /rw/config/rc.local > /dev/null <<'EOF'
#!/bin/sh

# This script will be executed at every VM startup, you can place your own
# custom commands here. This includes overriding some configuration in /etc,
# starting services etc.
#
# Executable scripts located in /rw/config/rc.local.d with the extension
# '.rc' are executed immediately before this rc.local.
# Example:
#  /rw/config/rc.local.d/custom.rc
#
# Example for overriding the whole CUPS configuration:
#  rm -rf /etc/cups
#  ln -s /rw/config/cups /etc/cups
#  systemctl --no-block restart cups

EOF
sudo cp -r /rw/config/rc.local /rw/config/rc.local.bak

# List available connections
echo "Available connections:"
#conn=$(nmcli connection show | awk '{print $1}' | tail -n +2)
#echo "$conn"
nmcli connection show
# Check if any connections were found
#if [ -z "$conn" ]; then
#    echo "No connections found. Please add a connection manually."
#    exit 1
#fi

# Read the name of the VPN connection
read -p "Enter the name of VPN connection: " conn
echo

# Ensure the user entry is not empty
if [ -z "$conn" ]; then
    echo "VPN connection name cannot be empty."
    exit 1
fi

# Common IP tables configurations
setup_iptables() {
    echo "" | sudo tee -a /rw/config/rc.local
    echo "Setting up iptables..."
    {
        echo "iptables -P INPUT ACCEPT"
        echo "iptables -P FORWARD ACCEPT"
        echo "iptables -P OUTPUT ACCEPT"
        echo "iptables -t filter -F"
        echo "iptables -t nat -F"
        echo "iptables -t mangle -F"
        echo "iptables -t raw -F"
        echo "iptables -F"
        echo "iptables -X"
        echo "iptables -Z"
        echo "nmcli connection up "$conn""
        echo "sleep 3"
        echo "nmcli connection up "$conn""
        echo "sleep 3"
        echo "nmcli connection up "$conn""
        echo "sleep 3"
        #echo "sleep 15"
echo "iptables -I FORWARD -o eth0 -j DROP"
echo "iptables -I FORWARD -i eth0 -j DROP"
echo "ip6tables -I FORWARD -o eth0 -j DROP"
echo "ip6tables -I FORWARD -i eth0 -j DROP"
    } | sudo tee -a /rw/config/rc.local
}

setup_iptables
echo
echo "/rw/config/rc.local"
cat /rw/config/rc.local
echo
echo "/rw/config/qubes-firewall-user-script"
cat /rw/config/qubes-firewall-user-script
echo

}


echo;
echo "----------------------------------------------------------";
echo "Iptables Sentinel Kill Switch for WireGuard and OpenVPN"
echo "leandroibov developer";
echo "----------------------------------------------------------";


# Main Menu loop – repeats until the user chooses to exit
echo
while true; do
echo
    echo "Choose an action:"
    echo "1) Enable Kill Switch for Wireguard or Openvpn"
    echo "2) USB RJ45 Kill Switch"
    echo "3) Hard nmcli restart"
    echo "4) Clean iptables rules"
    echo "5) List firewall rules"
    echo "6) Bulk configuration of WireGuard .conf files"
    echo "7) Bulk configuration of OpenVPN .ovpn files"
    echo "8) Clean all wireguard connections"
    echo "9) Clean all openvpn connections"
    echo "10) Kernel Hardening Rules Just for Local Connections (forward block)"
    echo "11) Kernel Hardening Using Forward netVM or PC as Gateway Using USB RJ45 Netcard"
    echo "12) Default Kernel Rules (Commonly Found in Most Linux Distributions)"
    echo "13) IP Forwarding Configuration for netVM or PC as Gateway Using USB RJ45 Network Card"
    echo "14) Remove IP Forwarding Configuration for Option 14"
    echo "15) Configure VPN with kill switch for netVM in /rw/config in Qubes OS (local and forward kill switch)"
    echo "16) Configure VPN with kill switch for netVM in /rw/config in Qubes OS (just forward kill switch)"
    echo "17) Exit"
    read -p "Enter your choice (1 through 17): " choice

    case "$choice" in
        1)
            
            local_or_local_forward
            
            ;;
        
        2)
            
            kill_s_usbrj45

            
            ;;
        3)
            
            nmcli_hard_restart
            
            ;;

        4)
            
            clean_iptables
            
            ;;

        5)
            
            iptables_rules
            
            ;;       

        6)
            
            wireguard2
            
            ;; 
  
        7)
            
            openvpn2
            
            ;; 

        8)
            
            clean_all_wireguards
            
            ;; 

        9)
            
            clean_all_openvpn
            
            ;;  

        10)
            
            kernel_hardening_local
            
            ;;

        11)
            
            kernel_hardening_forward
            
            ;;

        12)
            
            default_kernel_rules
            
            ;;

        13)
            
            ip_forward_conf
            
            ;;

        14)
            
            no_ip_forward
            
            ;;

        15)
            
            netvm_qubes
            
            ;;

        16)
            
            netvm_qubes_just_forward
            
            ;;


        17)
            echo "Exiting..."
            sleep 2
            break   # leave the while loop; the script ends here
            ;;
        *)
            echo "Invalid choice. Please select 1 or 2."
            echo "Press ENTER to try again..."
            read
            ;;
    esac
done

# Optional final message before the script terminates
echo "Program terminated."
exit 1
echo




