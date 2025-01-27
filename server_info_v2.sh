#!/bin/bash

OUTPUT_FILE="server_info.txt"

{
    # System Information
    echo "===== SYSTEM INFO ====="
    uname -a
    echo -e "\n/etc/os-release:"
    cat /etc/os-release
    echo -e "\nUptime:"
    uptime

    # CPU Information
    echo -e "\n\n===== CPU INFO ====="
    lscpu
    echo -e "\nCPU Usage:"
    mpstat -P ALL
    echo -e "\nTemperature:"
    sensors | grep 'Core'

    # Memory Information
    echo -e "\n\n===== RAM INFO ====="
    free -h
    echo -e "\nDetailed Memory:"
    sudo dmidecode --type memory

    # Storage Information
    echo -e "\n\n===== STORAGE INFO ====="
    echo -e "\nBlock Devices:"
    lsblk -o NAME,SIZE,TYPE,MOUNTPOINT,FSTYPE
    echo -e "\nDisk Usage:"
    df -hT
    echo -e "\nNVMe Drives:"
    nvme list 2>/dev/null
    echo -e "\nSMART Status:"
    for disk in /dev/sd?; do
        echo -e "\n$disk:"
        sudo smartctl -a $disk | grep -E 'Model|Serial|Health'
    done

    # Network Information
    echo -e "\n\n===== NETWORK INFO ====="
    echo -e "Public IP:"
    curl -s ifconfig.me
    echo -e "\n\nPrivate IPs:"
    ip -br addr show
    echo -e "\nRouting:"
    ip route
    echo -e "\nDNS:"
    cat /etc/resolv.conf

    # Software Information
    echo -e "\n\n===== SOFTWARE INFO ====="
    echo -e "Kernel Modules:"
    lsmod | head
    echo -e "\nServices:"
    systemctl list-units --type=service --state=running | head
    echo -e "\nInstalled Packages:"
    dpkg -l | wc -l

} | tee $OUTPUT_FILE

echo -e "\nReport saved to $OUTPUT_FILE"
