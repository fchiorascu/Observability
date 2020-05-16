#!/bin/bash
wget -q https://github.com/prometheus/blackbox_exporter/releases/download/v0.16.0/blackbox_exporter-0.16.0.linux-amd64.tar.gz;echo $?
sleep 1
mkdir /opt/blackbox_exporter;echo $?
tar -xzvf blackbox_exporter-0.16.0.linux-amd64.tar.gz -C /opt/blackbox_exporter --strip-components=1;echo $?
rm -rf blackbox_exporter-0.16.0.linux-amd64.tar.gz;echo $?
cat <<EOF >>/etc/passwd
blackbox_exporter:x:1503:1503:blackbox_exporter:/home/blackbox_exporter:/sbin/nologin
EOF
cat <<EOF >>/etc/group
blackbox_exporter:x:1503:blackbox_exporter
EOF
cp -p /opt/blackbox_exporter/blackbox.yml /opt/blackbox_exporter/blackbox.yml.backup;echo $?
cat <<EOF >/opt/blackbox_exporter/blackbox.yml
modules:
  http_2xx:
    prober: http
    timeout: 10s
    http:
      valid_http_versions: ["HTTP/1.1", "HTTP/2"]
     #proxy_url: "http://xxx.xxx.xx.x:3128"
      valid_status_codes: [200] # defaults to 2xx
      method: GET
      no_follow_redirects: false
      fail_if_ssl: false
      preferred_ip_protocol: "ip4" # defaults to "ip6"
      tls_config:
        insecure_skip_verify: true
  http_2xx_success:
    prober: http
    timeout: 10s
    http:
      valid_http_versions: ["HTTP/1.1","HTTP/2"]
      valid_status_codes: [200]  # defaults to 2xx
      method: GET
      no_follow_redirects: false
      fail_if_ssl: false
      headers:
        Content-Type: application/json
      fail_if_body_not_matches_regexp:
      - '"status": "success"'
EOF
chown --recursive blackbox_exporter:blackbox_exporter /opt/blackbox_exporter;echo $?
ln -s /opt/blackbox_exporter/blackbox_exporter /usr/local/bin/blackbox_exporter;echo $?
/opt/blackbox_exporter/blackbox_exporter --config.check | grep -i "Config file is ok exiting...";echo $?
cat <<EOF >/usr/lib/systemd/system/blackbox_exporter.service
[Unit]
Description=Prometheus Blackbox Exporter
Documentation=https://github.com/prometheus/blackbox_exporter
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
User=blackbox_exporter
Group=blackbox_exporter

ExecStart=/opt/blackbox_exporter/blackbox_exporter \
        --config.file /opt/blackbox_exporter/blackbox.yml \
        --log.level=debug \
        --log.format=json \

SyslogIdentifier=prometheus_blackbox_exporter
Restart=always

ExecReload=/bin/kill -HUP $MAINPID
TimeoutStopSec=10s
SendSIGKILL=no

[Install]
WantedBy=multi-user.target
EOF
systemctl enable blackbox_exporter;systemctl restart blackbox_exporter;systemctl status blackbox_exporter
sleep 1
curl -s -i 'http://localhost:9115/metrics';echo $?
curl -s -i 'http://localhost:9115/probe?target=https://www.google.com&module=http_2xx&debug=true';echo $?
curl -s -i 'http://localhost:9115/probe?target=http://localhost:9090/api/v1/rules&module=http_2xx_success&debug=true';echo $?
curl -s -i 'http://localhost:9115/probe?target=http://localhost:9090/api/v1/alertmanagers&module=http_2xx_success&debug=true';echo $?
exit;echo $?
