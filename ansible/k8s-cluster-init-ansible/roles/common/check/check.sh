#!/bin/bash

echo "===== SELinux ====="
getenforce
cat /etc/selinux/config

echo "===== Firewalld ====="
systemctl is-enabled firewalld
systemctl is-active firewalld

echo "===== Kernel modules ====="
lsmod | grep br_netfilter
lsmod | grep nf_conntrack

echo "===== modules-load ====="
cat /etc/modules-load.d/k8s.conf

echo "===== nf_conntrack hashsize ====="
cat /etc/modprobe.d/nf_conntrack.conf

echo "===== sysctl ====="
sysctl net.netfilter.nf_conntrack_max
sysctl net.core.somaxconn
sysctl net.core.netdev_max_backlog
sysctl net.ipv4.tcp_tw_reuse
sysctl net.ipv4.tcp_fin_timeout
sysctl net.ipv4.tcp_keepalive_time
sysctl net.ipv4.tcp_keepalive_intvl
sysctl net.ipv4.tcp_keepalive_probes
sysctl fs.inotify.max_user_watches
sysctl fs.inotify.max_user_instances
sysctl vm.max_map_count
sysctl fs.aio-max-nr

echo "===== limits ====="
ulimit -n
cat /etc/security/limits.d/90-k8s.conf
cat /etc/systemd/system.conf.d/90-k8s-limits.conf

echo "===== chrony ====="
timedatectl
chronyc sources
