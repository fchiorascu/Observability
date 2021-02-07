#!/bin/bash
wget -q https://github.com/prometheus/alertmanager/releases/download/v0.21.0/alertmanager-0.21.0.linux-amd64.tar.gz;echo $?
sleep 1
mkdir --parents /opt/alertmanager/data/;echo $?
tar -xzvf alertmanager-0.21.0.linux-amd64.tar.gz -C /opt/alertmanager --strip-components=1;echo $?
rm -rf alertmanager-0.21.0.linux-amd64.tar.gz;echo $?
cat <<EOF >>/etc/passwd
alertmanager:x:1502:1502:alertmanager:/home/alertmanager:/sbin/nologin
EOF
cat <<EOF >>/etc/group
alertmanager:x:1502:alertmanager
EOF
cp -p /opt/alertmanager/alertmanager.yml /opt/alertmanager/alertmanager.yml.backup;echo $?
cat <<EOF >/opt/alertmanager/alertmanager.yml
global:
 #smtp_smarthost: 'xxxx:25'
 #smtp_from: 'alertmanager@xxxx.com'
 #smtp_require_tls: false
 #slack_api_url: 'https://hooks.slack.com/services/xxxx/yyyy/zzzz'
 #http_config:
   #proxy_url: 'http://xxxx:3128'

route:
  group_by: ['env', 'alertname', 'job', 'severity', 'alias']
  group_wait: 1m
  group_interval: 3m
  repeat_interval: 1h
  receiver: 'dev'

#templates:
#- "/opt/alertmanager/email.tmpl"

receivers:
   - name: dev
     webhook_configs:
       - url: 'http://127.0.0.1:5001/'
         send_resolved: true
    #victorops_configs:
    #  - api_key: xxxx
    #    routing_key: yyyy
    #    entity_display_name: '{{ .CommonAnnotations.summary }}'
    #    send_resolved: true
    #email_configs:
    #  - to: 'xxxxxx@xxxx.com'
    #    send_resolved: true
    #slack_configs:
    #  - channel: '#prometheus'
    #    send_resolved: true
    #
    #    title: '[{{ .Status | toUpper }}{{ if eq .Status "firing" }}:{{ .Alerts.Firing | len }}{{ end }}] Monitoring Event Notification'
    #    text: >-
    #      {{ range .Alerts }}
    #        *Alert:* {{ .Annotations.summary }} - `{{ .Labels.severity }}`
    #        *Description:* {{ .Annotations.description }}
    #        *Status:* {{ .Status | toUpper }}
    #        *Starts At:* {{ .StartsAt }}
    #        *Ends at:* {{ .EndsAt }}
    #        *Graph:* <{{ .GeneratorURL }}|:chart_with_upwards_trend:>
    #        *Details:*
    #        {{ range .Labels.SortedPairs }} • *{{ .Name }}:* `{{ .Value }}`
    #        {{ end }}
    #      {{ end }}

inhibit_rules:
  - source_match:
      severity: 'critical'
    target_match:
      severity: 'warning'
    equal: ['env', 'alertname', 'job', 'severity', 'alias']
EOF
chown --recursive alertmanager:alertmanager /opt/alertmanager;echo $?
ln -s /opt/alertmanager/alertmanager /usr/local/bin/alertmanager;echo $?
ln -s /opt/alertmanager/amtool /usr/local/bin/amtool;echo $?
/opt/alertmanager/amtool --alertmanager.url=http://localhost:9093 check-config /opt/alertmanager/alertmanager.yml;echo $?
cat <<EOF >/usr/lib/systemd/system/alertmanager.service
[Unit]
Description=Prometheus Alertmanager
Wants=network-online.target
After=network-online.target

[Service]
User=alertmanager
Group=alertmanager
Type=simple
ExecStart=/opt/alertmanager/alertmanager \
        --config.file /opt/alertmanager/alertmanager.yml \
        --storage.path=/opt/alertmanager/data/ \
        --data.retention=120h \
        --log.level=debug \
        --log.format=json \

SyslogIdentifier=prometheus_alertmanager
Restart=always

ExecReload=/bin/kill -HUP $MAINPID
TimeoutStopSec=10s
SendSIGKILL=no

[Install]
WantedBy=default.target
EOF
systemctl enable alertmanager;systemctl restart alertmanager;systemctl status alertmanager
sleep 1
curl -s -i 'http://localhost:9093/metrics';echo $?
curl -s -i 'http://localhost:9093/api/v2/status';echo $?
curl -s -i 'http://localhost:9093/-/ready';echo $?
curl -s -i 'http://localhost:9093/-/healthy';echo $?
exit;echo $?
