# Nginx config for HA masters

## Update firewalld!

```sh
firewall-cmd --add-port=6443/tcp --permanent --zone=LAN
systemctl restart firewalld
```

## Update Nginx

```sh
nano /etc/nginx/nginx.conf
```
```properties
# enable stream module (at top of conf)
load_module /usr/lib64/nginx/modules/ngx_stream_module.so;

# include .stream configs
stream {
    # log format

    # logging
    error_log   /var/log/nginx/k8s-apiserver/stream_error.log;

    # includes
    include /etc/nginx/conf.d/*.stream;
}
```
```sh
mkdir -p /var/log/nginx/k8s-apiserver/
nano k8s-ha-apiserver.stream
```
```properties
upstream k8s_api_server {
    least_conn;
    server 10.66.66.5:6443;
    server 10.66.66.6:6443;
    server 10.66.66.7:6443;
}

server {
    listen 6443;

    # logging
    error_log   /var/log/nginx/k8s-apiserver/stream_error.log;

    proxy_pass k8s_api_server;
    proxy_timeout 3s;
    proxy_connect_timeout 1s;
}
```