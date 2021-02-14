#!/bin/bash
wget -q https://github.com/prometheus/node_exporter/releases/download/v1.1.1/node_exporter-1.1.1.linux-amd64.tar.gz;echo $?
sleep 1
mkdir /opt/node_exporter;echo $?
tar -xzvf node_exporter-1.1.1.linux-amd64.tar.gz -C /opt/node_exporter --strip-components=1;echo $?
rm -rf node_exporter-1.1.1.linux-amd64.tar.gz;echo $?
cat <<EOF >>/etc/passwd
node_exporter:x:1504:1504:node_exporter:/home/node_exporter:/sbin/nologin
EOF
cat <<EOF >>/etc/group
node_exporter:x:1504:node_exporter
EOF
chown --recursive node_exporter:node_exporter /opt/node_exporter;echo $?
ln -s  /opt/node_exporter/node_exporter /usr/local/bin/node_exporter;echo $?
cat <<EOF >/usr/lib/systemd/system/node_exporter.service
[Unit]
Description=Prometheus Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/opt/node_exporter/node_exporter \
        --web.listen-address=0.0.0.0:9100 \
        --web.disable-exporter-metrics \
        --collector.ntp \
        --collector.tcpstat \
        --collector.processes \
        --collector.interrupts \
        --no-collector.zfs \
        --no-collector.arp \
        --no-collector.nfs \
        --no-collector.ipvs \
        --no-collector.nfsd \
        --no-collector.wifi \
        --no-collector.edac \
        --no-collector.mdadm \
        --no-collector.hwmon \
        --no-collector.timex \
        --no-collector.logind \
        --no-collector.bcache \
        --no-collector.bonding \
        --no-collector.textfile \
        --no-collector.conntrack \
        --no-collector.infiniband \
        --collector.systemd.unit-whitelist=(grafana-server|prometheus|alertmanager|node_exporter|blackbox_exporter|sshd|crond|ntpd)\\.service \
        --log.level=debug \
        --log.format=json \

SyslogIdentifier=node_exporter
Restart=always

ExecReload=/bin/kill -HUP $MAINPID
TimeoutStopSec=10s
SendSIGKILL=no

[Install]
WantedBy=multi-user.target
EOF
systemctl enable node_exporter;systemctl restart node_exporter;systemctl status node_exporter
sleep 1
curl -s -i 'http://localhost:9100/metrics';echo $?
exit;echo $?
