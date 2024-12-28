#cloud-config
# yum_repos:
#   epel:  
#     name: Extra Packages for Enterprise Linux $releasever - $basearch
#     baseurl: https://download.fedoraproject.org/pub/epel/$releasever/Everything/$basearch
#     metalink: https://mirrors.fedoraproject.org/metalink?repo=epel-$releasever&arch=$basearch&infra=$infra&content=$contentdir
#     failovermethod: priority
#     enabled: 1
#     gpgcheck: 0
#   IF NAT IS NEEDED ... - iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
write_files:
  - owner: root:root
    append: true
    path: /etc/sysctl.conf
    content: |
      net.ipv4.ip_forward=1
runcmd:
  - sysctl -w net.ipv4.ip_forward=1
