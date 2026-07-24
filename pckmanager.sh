#!/bin/bash

# author: saba
# version: v1.0
# date: 6.22.2026

# Initialize variables
instance=$(uuidgen)
instance_ID=$instance
c_user=$(whoami)
c_loc=$(pwd)
c_script_file="pckmanager.sh"
bashrc="$HOME/.bashrc"

# Add alias if not exists
starter='alias pckmanager="$c_loc/pckmanager.sh"'
if grep -q "$starter" "$bashrc"; then
    :
else
    echo "$starter" >> "$bashrc"
fi

# Get date
date_str=$(date +"%Y%m%d-%H%M%S")
hostname=$(hostname)

# Collect system info
os_description=$(lsb_release -d | awk -F ':' '{print $2}' | xargs)
os_release=$(lsb_release -r | awk -F ':' '{print $2}' | xargs)
os_codename=$(lsb_release -c | awk -F ':' '{print $2}' | xargs)

# CPU info
cpu_vendor=$(lscpu | awk '/Vendor ID/ {print $3}')
if echo "$cpu_vendor" | grep -iq "intel"; then
    cpu_vendor="Intel"
else
    cpu_vendor="AMD"
fi
cpu_name=$(lscpu | awk '/Model name/ {for(i=4;i<=NF;i++) printf "%s ", $i; print ""}')
cpu_cores=$(lscpu | awk '/Core(s) per socket/ {print $4}')
cpu_threads_percore=$(lscpu | awk '/Thread(s) per core/ {print $4}')
# Calculate total threads
cpu_threads=$((cpu_cores * cpu_threads_percore))
cpu_min=$(lscpu | awk '/CPU MHz/ {print $4}')
cpu_max=$(lscpu | awk '/CPU max MHz/ {print $4}')
cpu_cache1=$(lscpu | awk '/L1d cache/ {print $3}')
cpu_cache2=$(lscpu | awk '/L2 cache/ {print $3}')
cpu_cache3=$(lscpu | awk '/L3 cache/ {print $3}')

# RAM info
total_ram=$(free -h | awk '/Mem/ {print $2}')
used_ram=$(free -h | awk '/Mem/ {print $3}')
free_ram=$(free -h | awk '/Mem/ {print $4}')

# Disk info
disk_info=$(df -h)

# detect package managers
declare -a pm_list=()
detect_package_managers() {
    if command -v apt &> /dev/null; then pm_list+=("apt"); fi
    if command -v dpkg &> /dev/null; then pm_list+=("dpkg"); fi
    if command -v rpm &> /dev/null; then pm_list+=("rpm"); fi
    if command -v dnf &> /dev/null; then pm_list+=("dnf"); fi
    if command -v yum &> /dev/null; then pm_list+=("yum"); fi
    if command -v pacman &> /dev/null; then pm_list+=("pacman"); fi
    if command -v zypper &> /dev/null; then pm_list+=("zypper"); fi
    if command -v flatpak &> /dev/null; then pm_list+=("flatpak"); fi
    if command -v snap &> /dev/null; then pm_list+=("snap"); fi
    if command -v nix &> /dev/null; then pm_list+=("nix"); fi
    if command -v conda &> /dev/null; then pm_list+=("conda"); fi
}
detect_package_managers

# collect package lists
declare -A package_data
get_packages() {
    for pm in "${pm_list[@]}"; do
        case "$pm" in
            "apt")
                pkgs=$(apt-mark showmanual)
                ;;
            "dpkg")
                pkgs=$(dpkg-query -W -f='${Package}\n' 2>/dev/null)
                ;;
            "rpm")
                pkgs=$(rpm -qa --qf '%{NAME}\n' 2>/dev/null)
                ;;
            "dnf")
                pkgs=$(dnf list installed | awk 'NR>1 {print $1}')
                ;;
            "yum")
                pkgs=$(yum list installed | awk 'NR>1 {print $1}')
                ;;
            "pacman")
                pkgs=$(pacman -Qq)
                ;;
            "zypper")
                pkgs=$(zypper se --installed-only | awk 'NR>4 {print $2}')
                ;;
            "flatpak")
                pkgs=$(flatpak list --app --columns=name)
                ;;
            "snap")
                pkgs=$(snap list | awk 'NR>1 {print $1}')
                ;;
            "nix")
                pkgs=$(nix-env -q --installed)
                ;;
            "conda")
                pkgs=$(conda list --name base --explicit | awk 'NR>3 {print $1}')
                ;;
            *)
                pkgs=""
                ;;
        esac
        key="${pm}_${hostname}"
        package_data["$key"]="$pkgs"
    done
}
get_packages

# Build output
output="System Information:
OS Description: $os_description
OS Release: $os_release
OS Codename: $os_codename

CPU:
Vendor: $cpu_vendor
Name: $cpu_name
Cores: $cpu_cores
Threads per Core: $cpu_threads_percore
Total Threads: $cpu_threads
Min MHz: $cpu_min
Max MHz: $cpu_max
L1 Cache: $cpu_cache1
L2 Cache: $cpu_cache2
L3 Cache: $cpu_cache3

Memory:
Total RAM: $total_ram
Used RAM: $used_ram
Free RAM: $free_ram

Disk Info:
$disk_info

Package Lists:
"

for key in "${!package_data[@]}"; do
    output+="\nPackage list for $key:\n"
    output+="${package_data[$key]}\n"
done

# Save to file
filename="${hostname}-packagelist-plus-${date_str}-${uuid}.txt"
# Save the output, overwrite if exists
echo "$output" > "$c_loc/$filename"

echo "Data saved to $c_loc/$filename"