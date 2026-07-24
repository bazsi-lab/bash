# Display Linux Standard Base and distribution info
lsb_release -a

# Show detailed info about your OS from release files
cat /etc/*-release

# Show kernel version and system info
uname -a

# Show only kernel version
uname -r

# Show hostname and related info
hostnamectl

# Display hardware architecture and CPU info
lscpu

# Show total, used, and free memory
free -h

# List PCI devices, including graphics card info
lspci

# List block devices and disks
lsblk

# Show detailed CPU info
cat /proc/cpuinfo

# Show detailed memory info
cat /proc/meminfo

# Show mounted filesystems
mount

# Display network interfaces and IP addresses
ip addr show

# Show active network connections
ss -tuln

# Get system uptime
uptime

# Show system load averages
cat /proc/loadavg

# Show system logs (useful for troubleshooting)
dmesg | less

# Show battery status (if applicable)
upower -i /org/freedesktop/UPower/devices/battery_BAT0

# List USB devices
lsusb