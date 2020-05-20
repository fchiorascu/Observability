#!/bin/bash
wget -q https://github.com/prometheus/prometheus/releases/download/v2.18.1/prometheus-2.18.1.linux-amd64.tar.gz;echo $?
sleep 1
mkdir /opt/prometheus;echo $?
cat <<EOF >/opt/prometheus/rules.yml
groups:
- name: HEARTBEAT
  rules:
  - alert: DeadMansSwitch
    expr: vector(1)
    for: 5m
    labels:
      severity: informational
    annotations:
      description: "This is a DeadMansSwitch meant to ensure that the entire Alerting pipeline is functional."
      summary: "Alerting DeadMansSwitch."
#virtual machines
- name: VMs
  rules:
#node_exporter scrape_time
  - alert: node_exporter_scrape_time
    expr: sum(irate(node_scrape_collector_duration_seconds[5m])) by (alias,env) > 15
    for: 5m
    labels:
      severity: warning
    annotations:
      description: "node_exporter scraped time for host: {{ $labels.job }} >15s.\nValue: {{ humanizeDuration $value }}."
      summary: "node_exporter scraped time for host: {{ $labels.job }} >15s."
#endpoints
  - alert: node_endpoint_down
    expr: up == 0
    for: 5m
    labels:
      severity: critical
    annotations:
      description: "Endpoint =DOWN on host: {{ $labels.job }}, instance: {{ $labels.instance }} and needs attention.\nValue: {{ $value }}\nLabels: {{ $labels }}."
      summary: "Endpoint =DOWN on host: {{ $labels.job }}."
      runbook: "Value for DOWN = 0 and UP = 1."
#reboot
  - alert: node_rebooted
    expr: (node_time_seconds - node_boot_time_seconds) / 60 < 1
    for: 30s
    labels:
      severity: critical
    annotations:
      description: "VM: {{ $labels.job }} was rebooted.\nValue: {{ humanizeDuration $value }}."
      summary: "VM: {{ $labels.job }} was rebooted."
#load
  - alert: node_load
    expr: (node_load5 / count(node_cpu_seconds_total{mode="idle"}) without(cpu,mode)) > 1.75
    for: 5m
    labels:
      severity: critical
    annotations:
      description: "On host: {{ $labels.job }} load is too high.\nValue: {{ $value }}."
      summary: "Load is too high for host: {{ $labels.job }}."
#cpu
  - alert: node_cpu_threshold_exceeded
    expr: 1 - (avg by (env,job) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 1) > 0.85
    for: 5m
    labels:
      severity: critical
    annotations:
      description: "CPU usage has exceeded >85% for host: {{ $labels.job }}.\nValue: {{ humanizePercentage $value }}."
      summary: "CPU usage is dangerously high for host: {{ $labels.job }}."
#memory
  - alert: node_memory_threshold_exceeded
    expr: ((node_memory_MemTotal_bytes - node_memory_MemFree_bytes - node_memory_Cached_bytes) / (node_memory_MemTotal_bytes)) > 0.85
    for: 5m
    labels:
      severity: critical
    annotations:
      description: "Memory usage has exceeded >85% for host: {{ $labels.job }}.\nValue: {{ humanizePercentage $value }}."
      summary: "Memory usage is dangerously high for host: {{ $labels.job }}."
#swap
  - alert: node_swap_threshold_exceeded
    expr: ((node_memory_SwapTotal_bytes - node_memory_SwapFree_bytes) / node_memory_SwapTotal_bytes) > 0.85
    for: 5m
    labels:
      severity: critical
    annotations:
      description: "Swap usage has exceeded >85% for host: {{ $labels.job }}.\nValue: {{ humanizePercentage $value }}."
      summary: "Swap usage is dangerously high for host: {{ $labels.job }}."
#filesystem
  - alert: node_filesystem_threshold_exceeded
    expr: (node_filesystem_avail_bytes / node_filesystem_size_bytes) * 100 < 15
    for: 5m
    labels:
      severity: critical
    annotations: 
      description: "Filesystem usage has exceeded >85% for host: {{ $labels.job }} with device: {{ $labels.device }}, mountpoint: {{ $labels.mountpoint }}, fstype: {{ $labels.fstype }}.\nValue: {{ $value }}."
      summary: "Filesystem usage is dangerously high for host: {{ $labels.job }}."
#disk
  - alert: node_disk_device_error
    expr: node_filesystem_device_error > 0
    for: 5m
    labels:
      severity: warning
    annotations:
      description: "Disk device error for host: {{ $labels.job }} with device: {{ $labels.device }}, mountpoint: {{ $labels.mountpoint }}, fstype: {{ $labels.fstype }}.\nValue: {{ $value }}."
      summary: "Disk device error for host: {{ $labels.job }}."
      runbook: "Value for OK = 0 and NOK != 0"

  - alert: node_predictive_disk_space
    expr: predict_linear(node_filesystem_free_bytes[1h], 4 * 3600) < 0
    for: 30m
    labels:
      severity: warning
    annotations:
      description: "Based on recent sampling, the disk is likely to will fill within the next 4 hours on host: {{ $labels.job }} with device: {{ $labels.device }}, mountpoint: {{ $labels.mountpoint }}, fstype: {{ $labels.fstype }}.\nValue: {{ humanize1024 $value }}."
      summary: "Disk is likely to will fill within the next 4 hours for host: {{ $labels.job }}."

  - alert: node_disk_space
    expr: ((node_filesystem_size_bytes - node_filesystem_free_bytes) / node_filesystem_size_bytes) > 0.85
    for: 5m
    labels:
      severity: warning
    annotations:
      description: "Disk space on host: {{ $labels.job }}, device: {{ $labels.device }}, mountpoint: {{ $labels.mountpoint }}, fstype: {{ $labels.fstype }} >85%.\nValue: {{ humanizePercentage $value }}."
      summary: "Disk space on host: {{ $labels.job }} >85%."

  - alert: node_disk_iops_system
    expr: sum(rate(node_disk_reads_completed_total{device!~"vdb|xvdb|dm.*"}[5m]) + rate(node_disk_writes_completed_total{device!~"vdb|xvdb|dm.*"}[5m])) by (alias) > 800
    for: 5m
    labels:
      severity: warning
    annotations:
      description: "Disk IOPs for host: {{ $labels.alias }} >800 I/O ops/sec (IOPs).\nValue: {{ humanize $value }}."
      summary: "Disk IOPs for host: {{ $labels.alias }} >800 I/O ops/sec (IOPs)."

  - alert: node_disk_iops_data
    expr: sum(rate(node_disk_reads_completed_total{device!~"vda|xvda"}[5m]) + rate(node_disk_writes_completed_total{device!~"vda|xvda"}[5m])) by (alias) > 2400
    for: 5m
    labels:
      severity: warning
    annotations:
      description: "Disk IOPs for host: {{ $labels.alias }} >2400 I/O ops/sec (IOPs).\nValue: {{ humanize $value }}."
      summary: "Disk IOPs for host: {{ $labels.alias }} >2400 I/O ops/sec (IOPs)."

  - alert: node_disk_inodes
    expr: (node_filesystem_files_free /node_filesystem_files) > 85
    for: 5m
    labels:
      severity: warning
    annotations:
      description: "Disk Inodes usage on host: {{ $labels.job }} >85% (IUse %), device: {{ $labels.device }}, fstype: {{ $labels.fstype }}, mountpoint: {{ $labels.mountpoint }}.\nValue: {{ humanize $value }}."
      summary: "Disk Inodes usage on host: {{ $labels.job }} >85% (IUse %)."

  - alert: node_disk_read_latency
    expr: (rate(node_disk_read_time_seconds_total[5m]) / rate(node_disk_reads_completed_total[5m])) > 0.050
    for: 5m
    labels:
      severity: warning
    annotations:
      description: "High read latency on host: {{ $labels.alias }}, device: {{ $labels.device }}.\nValue: {{ humanizeDuration $value }}."
      summary: "High read latency on host: {{ $labels.alias }}, device: {{ $labels.device }}."
      runbook: "The average value of the avg. Disk sec/read performance counter should be under 10 milliseconds and the maximum value of the avg. Disk sec/read performance counter should not exceed 50 milliseconds - databases."

  - alert: node_disk_write_latency
    expr: (rate(node_disk_write_time_seconds_total[5m]) / rate(node_disk_writes_completed_total[5m])) > 0.050
    for: 5m
    labels:
      severity: warning
    annotations:
      description: "High write latency on host: {{ $labels.alias }}, device: {{ $labels.device }}.\nValue: {{ humanizeDuration $value }}."
      summary: "High write latency on host: {{ $labels.alias }}, device: {{ $labels.device }}."
#entropy
  - alert: node_entropy
    expr: (node_entropy_available_bits) < 500
    for: 5m
    labels:
      severity: critical
    annotations:
      description: "Entropy <500 on host: {{ $labels.job }}.\nValue: {{ $value }}."
      summary: "Entropy is too low on host: {{ $labels.job }}."
#ntp
  - alert: node_ntp_sanity
    expr: node_ntp_sanity != 1
    for: 5m
    labels:
      severity: critical
    annotations:
      description: "NTP health is affected on host: {{ $labels.job }}, where 0 - Unhealthy and 1 - Healthy.\nValue: {{ $value }}."
      summary: "NTP health is affected on host: {{ $labels.job }} ."
      runbook: "https://github.com/prometheus/node_exporter/blob/master/docs/TIME.md"

  - alert: node_ntp_leap_seconds
    expr: node_ntp_leap > 0
    for: 5m
    labels:
      severity: warning
    annotations:
      description: "NTP leap seconds >0 on host: {{ $labels.job }}.\nValue: {{ $value }}."
      summary: "Where 0 – OK, 1 – add leap second at UTC midnight, 2 – delete leap second at UTC midnight, 3 – unsynchronised."
      runbook: "https://github.com/prometheus/node_exporter/blob/master/docs/TIME.md"

  - alert: node_ntp_offset
    expr: node_ntp_offset_seconds > 1
    for: 5m
    labels:
      severity: critical
    annotations:
      description: "NTP offset between local time and ntpd time is different on host: {{ $labels.job }} .\nValue: {{ humanizeDuration $value }}."
      summary: "NTP offset is >1s on host: {{ $labels.job }}."
      runbook: "https://github.com/prometheus/node_exporter/blob/master/docs/TIME.md"
#systemd
  - alert: node_systemd_unit_inactive
    expr: node_systemd_unit_state{name=~"sshd.service|crond.service|cloud-init.service|network.service|blackbox_exporter.service|node_exporter.service|prometheus.service|alertmanager.service|grafana-server.service",state="active"} == 0
    for: 1m
    labels:
      severity: critical
    annotations:
      description: "Service is not running: {{ $labels.name }}, with state: {{ $labels.state }} for host: {{ $labels.job }}.\nValue: {{ $value }}."
      summary: "Service is not running: {{ $labels.name }}, with state: {{ $labels.state }} for host: {{ $labels.job }}."
      runbook: "Value for DOWN = 0 and UP = 1."

  - alert: node_systemd_unit_ntpd_chronyd
    expr: node_systemd_unit_state{name="ntpd.service",state="active"} == 0 or node_systemd_unit_state{name="chronyd.service",state="active"} == 1
    for: 1m
    labels:
      severity: critical
    annotations:
      description: "Service is not running: {{ $labels.name }}, with state: {{ $labels.state }} for host: {{ $labels.job }}.\nValue: {{ $value }}."
      summary: "Service is not running: {{ $labels.name }}, with state: {{ $labels.state }} for host: {{ $labels.job }}."
      runbook: "Keep ntpd running and chronyd stopped, where value for DOWN = 0 and UP = 1."

  - alert: node_systemd_unit_flapping
    expr: changes(node_systemd_unit_state{state="active"}[5m]) > 5 or (changes(node_systemd_unit_state{state="active"}[60m]) > 15 unless changes(node_systemd_unit_state{state="active"}[30m]) < 7)
    labels:
      severity: critical
    annotations:
      description: "Systemd unit state is flapping on host: {{ $labels.job }}, for service: {{ $labels.name }} with state: {{ $labels.state }}.\nValue: {{ $value }}."
      summary: "Systemd unit state is flapping on host: {{ $labels.job }}."

  - alert: node_systemd_unit_failed
    expr: node_systemd_unit_state{state="failed"} > 0
    for: 5m
    labels:
      severity: critical
    annotations:
      description: "Systemd unit failed on host: {{ $labels.job }}, for service: {{ $labels.name }} with state: {{ $labels.state }}.\nValue: {{ $value }}."
      summary: "Systemd unit failed on host: {{ $labels.job }}."
      runbook: "Check with: systemctl --failed and correct with: systemctl reset-failed."
#network
  - alert: node_network_IN_low_bandwith_usage
    expr: irate(node_network_receive_bytes_total{device="eth0"}[1m]) == 0
    for: 1m
    labels:
      severity: critical
    annotations:
      description: "Unusually LOW bandwidth (IN) for host: {{ $labels.job }}, interface: {{ $labels.device }}.\nValue: {{ humanize1024 $value }}."
      summary: "Unusually LOW bandwidth (IN) for host: {{ $labels.job }}, interface: {{ $labels.device }}."

  - alert: node_network_OUT_low_bandwith_usage
    expr: irate(node_network_transmit_bytes_total{device="eth0"}[1m]) == 0
    for: 1m
    labels:
      severity: critical
    annotations:
      description: "Unusually LOW bandwidth (OUT) for host: {{ $labels.job }}, interface: {{ $labels.device }}.\nValue: {{ humanize1024 $value }}."
      summary: "Unusually LOW bandwidth (OUT) for host: {{ $labels.job }}, interface: {{ $labels.device }}."

  - alert: node_network_OUT_high_bandwith_usage
    expr: rate(node_network_transmit_bytes_total{device="eth0"}[1m]) > 0.95*1e+09
    for: 1m
    labels:
      severity: critical
    annotations:
      description: "Unusually HIGH bandwidth (OUT) for host: {{ $labels.job }}, interface: {{ $labels.device }}.\nValue: {{ humanize1024 $value }}."
      summary: "Unusually HIGH bandwidth (OUT) for host: {{ $labels.job }}, interface: {{ $labels.device }}."

  - alert: node_network_IN_high_bandwith_usage
    expr: rate(node_network_receive_bytes_total{device="eth0"}[1m]) > 0.95*1e+09
    for: 1m
    labels:
      severity: critical
    annotations:
      description: "Unusually HIGH bandwidth (IN) for host: {{ $labels.job }}, interface: {{ $labels.device }}.\nValue: {{ humanize1024 $value }}."
      summary: "Unusually HIGH bandwidth (IN) for host: {{ $labels.job }}, interface: {{ $labels.device }}."

  - alert: node_network_IN_drops
    expr: rate(node_network_receive_drop_total{device="eth0"}[1m]) > 0
    for: 1m
    labels:
      severity: warning
    annotations:
      description: "Network drops on host: {{ $labels.job }}, interface: {{ $labels.device }}.\nValue: {{ $value }}."
      summary: "Network drops >0."

  - alert: node_network_OUT_drops
    expr: rate(node_network_transmit_drop_total{device="eth0"}[1m]) > 0
    for: 1m
    labels:
      severity: warning
    annotations:
      description: "Network drops on host: {{ $labels.job }}, interface: {{ $labels.device }}.\nValue: {{ $value }}."
      summary: "Network drops >0."

  - alert: node_network_IN_errors
    expr: rate(node_network_receive_errs_total{device="eth0"}[1m]) > 0
    for: 1m
    labels:
      severity: warning
    annotations:
      description: "Network errors on host: {{ $labels.job }}, interface: {{ $labels.device }}.\nValue: {{ $value }}."
      summary: "Network errors on >0."

  - alert: node_network_OUT_errors
    expr: rate(node_network_transmit_errs_total{device="eth0"}[1m]) > 0
    for: 1m
    labels:
      severity: warning
    annotations:
      description: "Network errors on host: {{ $labels.job }}, interface: {{ $labels.device }}.\nValue: {{ $value }}."
      summary: "Network errors >0."

  - alert: node_network_interface_status
    expr: node_network_up{device!~"lo|docker0"} < 1
    for: 5m
    labels:
      severity: critical
    annotations:
      description: "Interface status =DOWN on host: {{ $labels.alias }}, interface: {{ $labels.interface }}, status: {{ $labels.operstate }}.\nValue: {{ $value }}."
      summary: "Interface status =DOWN."
      runbook: "Value for DOWN = 0 and UP = 1."
#blocks_xfs
  - alert: node_xfs_block_allocation_high
    expr: (node_xfs_extent_allocation_blocks_allocated_total / (node_xfs_extent_allocation_blocks_freed_total + node_xfs_extent_allocation_blocks_allocated_total)) > 0.85
    for: 5m
    labels:
      severity: warning
    annotations:
      description: "xfs allocation blocks >85% on host:{{ $labels.alias }}, device: {{ $labels.device }}.\nValue: {{ humanizePercentage $value }}."
      summary: "xfs allocation blocks >85%."
#file, processes handlers
  - alert: node_file_handlers
    expr: (node_filefd_allocated / node_filefd_maximum) < 0.85
    for: 30s
    labels:
      severity: critical
    annotations:
      description: "File handlers usage >85% on host: {{ $labels.job }}.\nValue: {{ humanizePercentage $value }}."
      summary: "File handlers usage >85%."

  - alert: node_process_handlers
    expr: (process_open_fds / process_max_fds) > 0.85
    for: 5m
    labels:
      severity: critical
    annotations:
      description: "Process handlers usage >85% on host: {{ $labels.job }}.\nValue: {{ humanizePercentage $value }}."
      summary: "Process handlers usage >85%."
#processes
  - alert: node_processes_zombie
    expr: node_processes_state{state="Z"} > 0
    for: 5m
    labels:
      severity: warning
    annotations:
      description: "Zombie processes on host: {{ $labels.alias }}, state: {{ $labels.state }}.\nValue: {{ $value }}."
      summary: "Zombie processes on host: {{ $labels.alias }}, state: {{ $labels.state }}."
EOF
cp -p /opt/prometheus/prometheus.yml /opt/prometheus/prometheus.yml.backup;echo $?
tar -xzvf prometheus-2.18.1.linux-amd64.tar.gz -C /opt/prometheus --strip-components=1;rm -rf prometheus-2.18.1.linux-amd64.tar.gz;echo $?
rm -rf prometheus-2.18.1.linux-amd64.tar.gz;echo $?
mkdir --parents /data/prometheus;echo $?
cat <<EOF >>/etc/passwd
prometheus:x:1501:1501:prometheus:/home/prometheus:/sbin/nologin
EOF
cat <<EOF >>/etc/group
prometheus:x:1501:prometheus
EOF
cat <<EOF >/opt/prometheus/prometheus.yml
global:
  scrape_interval: 15s
  scrape_timeout: 10s
  evaluation_interval: 15s
alerting:
  alertmanagers:
  - scheme: http
    static_configs:
    - targets:
      - localhost:9093
rule_files:
  - rules.yml
scrape_configs:
###Prometheus Job containing endpoints for Prometheus, Alertmanager and blackbox_exporter###
  - job_name: prometheus
    static_configs:
      - targets: ['localhost:9100','localhost:9115','localhost:9090','localhost:9093']
        labels:
          env: dev
          alias: prometheus
###Grafana Job###
  - job_name: grafana
    tls_config:
        insecure_skip_verify: true
    static_configs:
      - targets: ['localhost:3000']
        labels:
          env: dev
          alias: grafana
###Probing with blackbox_exporter###
  - job_name: 'probing1'
    metrics_path: /probe
    params:
      module: [http_2xx]
    scrape_interval: 1m
    static_configs:
      - targets:
        - https://www.google.com
        labels:
          env: dev
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: url
      - target_label: __address__
        replacement: 127.0.0.1:9115
  - job_name: 'probing2'
    metrics_path: /probe
    params:
      module: [http_2xx_success]
    scrape_interval: 1m
    static_configs:
      - targets:
        - http://localhost:9090/api/v1/rules
        - http://localhost:9090/api/v1/alertmanagers
        labels:
          env: dev
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: url
      - target_label: __address__
        replacement: 127.0.0.1:9115
EOF
chown --recursive prometheus:prometheus /opt/prometheus;echo $?
chown --recursive prometheus:prometheus /data/prometheus;echo $?
ln -s /opt/prometheus/promtool /usr/local/bin/promtool;echo $?
ln -s /opt/prometheus/prometheus /usr/local/bin/prometheus;echo $?
ls -ltrha /usr/local/bin/prom*
/opt/prometheus/promtool check config /opt/prometheus/prometheus.yml;echo $?
cat <<EOF >/usr/lib/systemd/system/prometheus.service
[Unit]
Description=Prometheus Server
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/opt/prometheus/prometheus \
        --config.file /opt/prometheus/prometheus.yml \
        --storage.tsdb.path=/data/prometheus \
        --web.console.templates=/opt/prometheus/consoles \
        --web.console.libraries=/opt/prometheus/console_libraries \
        --web.enable-lifecycle \
        --storage.tsdb.retention.time=31d \
        --storage.tsdb.max-block-duration=72h \
        --storage.tsdb.min-block-duration=2h \
        --log.level=debug \
        --log.format=json \

SyslogIdentifier=prometheus
Restart=always

ExecReload=/bin/kill -HUP
TimeoutStopSec=10s
SendSIGKILL=no

[Install]
WantedBy=default.target
EOF
systemctl enable prometheus;systemctl restart prometheus;systemctl status prometheus
sleep 1
curl -s -i 'http://localhost:9090/-/ready';echo $?
curl -s -i 'http://localhost:9090/-/healthy';echo $?
curl -s -i 'http://localhost:9090/status';echo $?
curl -s -i 'http://localhost:9090/metrics';echo $?
curl -s -i 'http://localhost:9090/metrics' | /opt/prometheus/promtool check metrics;echo $?
exit;echo $?
