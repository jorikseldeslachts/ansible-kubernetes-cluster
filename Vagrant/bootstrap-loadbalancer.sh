#!/bin/sh

# This script will configure the loadbalancer with nginx to proxy traffic between all nodes.


# open firewall ports
firewall-cmd --permanent --add-port=80/tcp
firewall-cmd --permanent --add-port=443/tcp
firewall-cmd --permanent --add-port=6443/tcp
systemctl restart firewalld

# install nginx
yum install -y nginx

# start service
systemctl enable nginx
systemctl restart nginx

# create logging directories
mkdir -p /var/log/nginx/{k8s-apiserver,milkywaygalaxy.be}

# generate ssl testing certificate
mkdir /etc/ssl/private
chmod 700 /etc/ssl/private
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/ssl/private/nginx-selfsigned.key \
    -out /etc/ssl/certs/nginx-selfsigned.crt \
    -subj "/C=AU/ST=NSW/L=Sydney/O=Nginx/OU=server/CN=`hostname -f`/emailAddress=admin@test.com"

# configure nginx service
cat <<EOT > /etc/nginx/nginx.conf
# user and pid file
# user nginx;
user root;
pid /var/run/nginx.pid;

# Set to number of CPU cores
worker_processes 1;

events {
    # set to number op CPU cores X 1024
    worker_connections 1024;
}

# http settings
http {
    # auto indexing order
    index index.htm index.html index.php;

    # log format
    log_format main
                '\$remote_addr - \$remote_user [\$time_local] "\$request" '
                '\$status \$body_bytes_sent "\$http_referer" '
                '"\$http_user_agent" "\$http_x_forwarded_for"';

    # logging
    access_log /var/log/nginx/access.log main;
    error_log /var/log/nginx/error.log;

    # prevent nginx from leaking its version on error pages
    server_tokens off;

    # better packet transmitting
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;

    # other settings
    keepalive_timeout 65;
    default_type application/octet-stream;
    types_hash_max_size 2048;
    server_names_hash_bucket_size 64;
    # server_name_in_redirect off;

    # catch all because otherwise nginx always servers first server block for all undefined domains
    server {
        return 404;
    }

    # includes
    include /etc/nginx/mime.types;
    include /etc/nginx/fastcgi.conf;
    # include /etc/nginx/proxy.conf;
    include /etc/nginx/conf.d/*.conf;
}
EOT

# configure LB proxy on Kubernetes API
cat <<EOT > /etc/nginx/conf.d/k8s-ha-apiserver.stream
upstream k8s_api_server {
    #   least_conn;
EOT
for i in $K8S_MASTERS ; do
    echo "    server $i:6443;" >> /etc/nginx/conf.d/k8s-ha-apiserver.stream
done
cat <<EOT >> /etc/nginx/conf.d/k8s-ha-apiserver.stream
}

server {
EOT
echo "    listen $IP_ADDRESS:6443;" >> /etc/nginx/conf.d/k8s-ha-apiserver.stream
cat <<EOT >> /etc/nginx/conf.d/k8s-ha-apiserver.stream
    # logging
    error_log   /var/log/nginx/k8s-apiserver/stream_error.log;

    proxy_pass k8s_api_server;
#    proxy_timeout 3s;
#    proxy_connect_timeout 1s;
}

server {
    listen k8s.milkywaygalaxy.be:6443;

    # logging
    error_log   /var/log/nginx/k8s-apiserver/stream_error.log;

    proxy_pass k8s_api_server;
}
EOT

# configure LB proxy on Kubernetes Ingress
cat <<EOT > /etc/nginx/conf.d/01-k8s-loadbalancer.conf
######################## k8s upstream ############################
upstream k8s_nodes_http {
    # proxy to the upstream with the least amount of connections
    least_conn;

    # weight 3 means 3 times as much traffic
EOT
for i in $K8S_MASTERS ; do
    echo "    server $i:30080 max_fails=1 fail_timeout=30s;" >> /etc/nginx/conf.d/01-k8s-loadbalancer.conf
done
cat <<EOT >> /etc/nginx/conf.d/01-k8s-loadbalancer.conf
}
################### http to https redirects ######################
server {
    listen 80;
    server_name *.milkywaygalaxy.be;

    # logging
    access_log  /var/log/nginx/milkywaygalaxy.be/access.log   main;
    error_log   /var/log/nginx/milkywaygalaxy.be/error.log    error;

    location / {
        # return 301 https://\$server_name\$request_uri; # gives https://%2A.domain.com
        return 301 https://\$host\$request_uri;
    }
}
####################### SSL all domains ##########################
server {
    # listen ssl
    listen 443 ssl;
    ssl on;
    server_name *.milkywaygalaxy.be;

    # SSL/TLS
    ssl_certificate     /etc/ssl/certs/nginx-selfsigned.crt;
    ssl_certificate_key /etc/ssl/private/nginx-selfsigned.key;
    ssl_protocols TLSv1.2;
    ssl_prefer_server_ciphers on;
    ssl_ciphers 'EECDH+AESGCM:EDH+AESGCM:AES256+EECDH:AES256+EDH';

    # logging
    access_log  /var/log/nginx/milkywaygalaxy.be/access.log   main;
    error_log   /var/log/nginx/milkywaygalaxy.be/error.log    error;

    location / {
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;

        proxy_set_header X-provider Vagrant;
        proxy_set_header Host \$host;
        proxy_pass http://k8s_nodes_http;
    }
}
EOT

# restart nginx
systemctl restart nginx