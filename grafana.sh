#!/bin/bash
yum install -y initscripts urw-fonts wget curl ntp haveged.x86_64;echo $?
systemctl enable ntpd haveged;echo $?
systemctl restart ntpd haveged;echo $?
systemctl status ntpd haveged;echo $?
#wget -q --show-progress https://dl.grafana.com/oss/release/grafana-7.0.0-beta3.x86_64.rpm;echo $?
wget -q https://dl.grafana.com/oss/release/grafana-6.7.3-1.x86_64.rpm;echo $?
sleep 1
rpm -ivh grafana-6.7.3-1.x86_64.rpm;echo $?
rm -rf grafana-6.7.3-1.x86_64.rpm;echo $?
cat <<EOF >/etc/sysconfig/grafana-server
no_proxy=internal.domain,127.0.0.1
GRAFANA_USER=grafana
GRAFANA_GROUP=grafana
GRAFANA_HOME=/usr/share/grafana
LOG_DIR=/var/log/grafana
DATA_DIR=/var/lib/grafana
MAX_OPEN_FILES=10000
CONF_DIR=/etc/grafana
CONF_FILE=/etc/grafana/grafana.ini
RESTART_ON_UPGRADE=true
PLUGINS_DIR=/var/lib/grafana/plugins
PROVISIONING_CFG_DIR=/etc/grafana/provisioning
# Only used on systemd systems
PID_FILE_DIR=/var/run/grafana
EOF
grafana-cli plugins install grafana-worldmap-panel;echo $?
grafana-cli plugins install jdbranham-diagram-panel;echo $?
grafana-cli plugins install grafana-piechart-panel;echo $?
grafana-cli plugins install grafana-clock-panel;echo $?
grafana-cli plugins install agenty-flowcharting-panel;echo $?
systemctl enable grafana-server;systemctl restart grafana-server;systemctl status grafana-server
/usr/sbin/grafana-cli plugins ls;echo $?
/usr/sbin/grafana-cli admin reset-admin-password observability;echo $?
sleep 1
curl -s -i 'http://localhost:3000/metrics';echo $?
exit;echo $?