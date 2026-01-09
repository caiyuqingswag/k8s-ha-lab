#!/bin/bash
set -e

#!/bin/bash
set -e

read -p "是否以这台服务器为 Keepalived MASTER？是请输入 yes: " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
    echo "未确认 MASTER，脚本退出。"
    exit 1
fi


VIP="172.16.15.50/24"
INTERFACE="ens3"   # ⚠️ 改成你真实网卡名


MASTER1="172.16.15.51"
MASTER2="172.16.15.52"
MASTER3="172.16.15.53"

echo "==> Install epel-release"
yum install -y epel-release

echo "==> Install nginx, keepalived"
yum install -y nginx keepalived nginx-mod-stream

#######################################
# nginx.conf
#######################################
cat >/etc/nginx/nginx.conf <<EOF
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log;
pid /run/nginx.pid;

include /usr/share/nginx/modules/*.conf;

events {
    worker_connections 1024;
}

stream {

    log_format  main  '\$remote_addr \$upstream_addr - [\$time_local] \$status \$upstream_bytes_sent';
    access_log  /var/log/nginx/k8s-access.log  main;

    upstream k8s-apiserver {
        server ${MASTER1}:6443 weight=5 max_fails=3 fail_timeout=30s;
        server ${MASTER2}:6443 weight=5 max_fails=3 fail_timeout=30s;
        server ${MASTER3}:6443 weight=5 max_fails=3 fail_timeout=30s;
    }

    server {
        listen 16443;
        proxy_pass k8s-apiserver;
    }
}

http {
    log_format  main  '\$remote_addr - \$remote_user [\$time_local] "\$request" '
                      '\$status \$body_bytes_sent "\$http_referer" '
                      '"\$http_user_agent" "\$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;

    sendfile            on;
    tcp_nopush          on;
    tcp_nodelay         on;
    keepalive_timeout   65;
    types_hash_max_size 2048;

    include             /etc/nginx/mime.types;
    default_type        application/octet-stream;

    server {
        listen       80 default_server;
        server_name  _;
        location / {}
    }
}
EOF

#######################################
# keepalived.conf (MASTER)
#######################################
cat >/etc/keepalived/keepalived.conf <<EOF
global_defs {
   notification_email {
     acassen@firewall.loc
     failover@firewall.loc
     sysadmin@firewall.loc
   }
   notification_email_from Alexandre.Cassen@firewall.loc
   smtp_server 127.0.0.1
   smtp_connect_timeout 30
   router_id NGINX_MASTER
}

vrrp_script check_nginx {
    script "/etc/keepalived/check_nginx.sh"
}


vrrp_instance VI_1 {
    state MASTER
    interface ${INTERFACE}
    virtual_router_id 51
    priority 100
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass 1111
    }

    virtual_ipaddress {
        ${VIP}
    }

    track_script {
        check_nginx
    }
}
EOF

#######################################
# check_nginx.sh
#######################################
cat >/etc/keepalived/check_nginx.sh <<'EOF'
#!/bin/bash
counter=$(ps -ef |grep nginx | grep sbin | egrep -cv "grep|$$")
if [ $counter -eq 0 ]; then
    systemctl start nginx
    sleep 2
    counter=$(ps -ef |grep nginx | grep sbin | egrep -cv "grep|$$")
    if [ $counter -eq 0 ]; then
        systemctl stop keepalived
    fi
fi
EOF

chmod +x /etc/keepalived/check_nginx.sh

#######################################
# 启动服务
#######################################
systemctl daemon-reload
systemctl enable --now nginx
systemctl enable --now keepalived

echo "========================================"
echo " Nginx + Keepalived MASTER 部署完成"
echo " VIP: ${VIP}"
echo "========================================"
