#!/bin/bash

# author: saba
# version: v1.0
# date: 6.22.2026

# tinny script, to the store installed packages, to make the life easier to reisntall a your system later, or copy it
# start, choose an option, store-manage and reinstall your system packages easy
# first time, the system create an alias to execute this script
# after that you can execute it via the alias easy and simple


echo "check system dependencies"


checksumlocal=" "
instance=$(uuidgen)
instance_ID=$instance
c_user=$(whoami)
c_loc=$(pwd)
c_script_file="pckmanager.sh"
#script_alias
starter="alias pckmanager=\"$c_loc/pckmanager.sh\""
if grep -q "$starter" "$c_script_file"; then
    :
else
    echo "$starter" >> "$bashrc"
fi


# Get date
date_str=$(date +"%Y%m%d-%H%M%S")

# system_info=

# os-info

os_description=$(lsb_release | awk '/Description/ {print $2, $3, $4}')
os_release=$(lsb_release | awk '/Release/ {print $2}')
os_codename=$(lsb_release | awk '/Codename/ {print $2}')


# cpu

cpu_vendor=$(if lscpu | awk '/Vendor ID/ {print $3}' | grep -i "Intel" > /dev/null;
 then echo "Intel";
 else echo "AMD";
 fi
)
cpu_name=$(lspcu | awk '/Model/ {print $2, $3, $4, $5, $6, $7, $8}')
cpu_cores=$(lscpu | awk '/Core/ {print $4}')
cpu_threads_percore=$(lscpu | awk '/Thread/ {print $4}')
cpu_threas=$($cpu_cores * $cpu_threads_percore)
cpu_min=$(lscpu | awk '/CPU min MHz/ {print $4}')
cpu_max=$(lscpu | awk '/CPU max MHz/ {print $4}')
cpu_cache1=$(lscpu | awk '/L1d/ {print $2, $3}')
cpu_cache2=$(lscpu | awk '/L2/ {print $2, $3}')
cpu_cache3=$(lscpu | awk '/L3/ {print $2, $3}')

# ram

hostname=$(hostnamectl)
total_ram=$(free -h | awk '/Mem/ {print $2}')
used_ram=$(free -h | awk '/Mem:/ {print $3}')
free_ram=$(free -h | awk '/Mem:/ {print $4}')

# disk-info
disk_info=$(df -h)

# check package manager



pck_managers=("apt" "dpkg" "rpm" "dnf" "yum" "pacman" "zypper" "flatpak" "snap" "nix" "conda")

for cmd in "${pck_managers[@]}"; do
    if command -v $cmd &> /dev/null; then
        echo "$cmd is present"
    else
        echo "$cmd is not present"
    fi
done

# array to hold the detected package managers

declare -a pm_list

# associative array to hold package data

declare -A pacakage_data


# detect package managers

detect_package_managers() {
    if command -v apt &> /dev/null; then
        pm_list+=("apt")
    fi
    if command -v dpkg &> /dev/null; then
        pm_list+=("dpkg")
    fi
    if command -v rpm &> /dev/null; then
        pm_list+=("rpm")
    fi
    if command -v dnf &> /dev/null; then
        pm_list+=("dnf")
    fi
    if command -v yum &> /dev/null; then
        pm_list+=("yum")
    fi
    if command -v pacman &> /dev/null; then
        pm_list+=("pacman")
    fi
    if command -v zypper &> /dev/null; then
        pm_list+=("zypper")
    fi
    if command -v flatpak &> /dev/null; then
        pm_list+=("flatpak")
    fi
    if command -v snap &> /dev/null; then
        pm_list+=("snap")
    fi
    if command -v nix &> /dev/null; then
        pm_list+=("nix")
    fi
    if command -v conda &> /dev/null; then
        pm_list+=("conda")
    fi
}

# get user-installed packages for each package manager

get_packages() {
    for pm in "${pm_list[@]}"; do
        case "$pm" in
            "apt")
                # List manually installed packages
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
        # Store in the array with format: "packagemanagername_hostname"
        key="${pm}_${HOSTNAME}"
        packages_data["$key"]="$pkgs"
    done
}

# Run detection and package collection
detect_package_managers
get_packages

# Prepare final output
output="System Information:
OS Description: $os_description
OS Release: $os_release
OS Codename: $os_codename

CPU:
Vendor: $cpu_vendor
Name: $cpu_name
Cores: $cpu_cores
Threads per Core: $cpu_threads_per_core
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

for key in "${!packages_data[@]}"; do
    output+="\nPackage list for $key:\n"
    output+="${packages_data[$key]}\n"
done

# Save to file
filename="${hostname}-packagelist-plus-${date_str}-${uuid}.txt"
echo "$output" >> "$c_loc/$filename"

echo "Data saved to $c_loc/$filename"





