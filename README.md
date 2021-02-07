# Observability Pillars: monitoring, visualization, alerting. <a name="top"></a>
Observability is a measure of how well internal states of a system can be inferred by knowledge of its external outputs.


## Components

<hr/>

| APP | Version |
| :--- | ---: |
| Prometheus | [2.24.1](https://prometheus.io/download/#prometheus "Download") |
| Alertmanager | [0.21.0](https://prometheus.io/download/#alertmanager "Download") |
| blackbox_exporter | [0.18.0](https://prometheus.io/download/#blackbox_exporter "Download") |

<hr/>

- [ ] **Monitoring**
- Prometheus collects metrics from monitored targets by scraping metrics HTTP endpoints on these targets.
- [ ] **Alerting**
Alerting rules in Prometheus servers send alerts to an Alertmanager. The Alertmanager then manages those alerts, including silencing, inhibition, aggregation and sending out notifications via methods such as email, on-call notification systems, and chat platforms.
- [ ] **Probing**
- The blackbox exporter allows blackbox probing of endpoints over HTTP, HTTPS, DNS, TCP and ICMP.


## RUN
To run the application locally below are the commands and arguments used in CLI.

*blackbox_exporter:*
> /opt/blackbox_exporter/blackbox_exporter --config.file /opt/blackbox_exporter/blackbox.yml --log.level=debug --log.format=json
> /bin/blackbox_exporter --config.check | grep -i "Config file is ok exiting..."

*grafana:*
> /usr/share/grafana/bin/grafana-server restart
		
*prometheus:*
> /opt/prometheus/prometheus--config.file /opt/prometheus/prometheus.yml --storage.tsdb.path=/data/prometheus --web.console.templates=/opt/prometheus/consoles --web.console.libraries=/opt/prometheus/console_libraries --web.enable-lifecycle --web.config.file=/etc/prometheus/web-config.yml --storage.tsdb.retention.time=31d --storage.tsdb.max-block-duration=12h --storage.tsdb.min-block-duration=2h --log.level=debug --log.format=json

*alertmanager:*
> /opt/alertmanager/alertmanager --config.file /opt/alertmanager/alertmanager.yml --storage.path=/opt/alertmanager/data/ --data.retention=120h --log.level=debug --log.format=json

*node_exporter:*
> /opt/node_exporter/node_exporter --web.listen-address=0.0.0.0:9100 --web.disable-exporter-metrics --collector.ntp --collector.systemd --collector.tcpstat --collector.processes--collector.interrupts --no-collector.zfs --no-collector.arp --no-collector.nfs --no-collector.ipvs --no-collector.nfsd --no-collector.wifi --no-collector.edac --no-collector.mdadm --no-collector.hwmon --no-collector.timex --no-collector.logind --no-collector.bcache --no-collector.bonding --no-collector.textfile --no-collector.conntrack --no-collector.infiniband --collector.systemd.unit-whitelist=(grafana-server|prometheus|alertmanager|node_exporter|sshd|crond|ntpd)\\.service --log.level=debug --log.format=json


## Check configuration
To check the application configuration with below commands and arguments used in CLI.


*prometheus:*
> /opt/prometheus/promtool check config /opt/prometheus/prometheus.yml
> /opt/prometheus/promtool check web-config /opt/prometheus/web-config.yml

- curl -s -i 'http://localhost:9090/-/ready'
*#readiness*
- curl -s -i 'http://localhost:9090/-/healthy'
*#health*
- curl -s -i 'http://localhost:9090/-/reload'
*#reload*
- curl -s -i 'http://localhost:9090/status'
*#status page*
- curl -s -i 'http://localhost:9090/metrics'
*#internal metrics*
- curl -s -i 'http://localhost:9090/metrics' | /opt/prometheus/promtool check metrics
*#internal metrics correctness*


*alertmanager:*
> /opt/alertmanager/amtool --alertmanager.url=http://localhost:9093 check-config /opt/alertmanager/alertmanager.yml

- curl -s -i 'http://localhost:9093/metrics'
*#internal metrics*
- curl -s -i 'http://localhost:9093/api/v2/status'
*#status page*
- curl -s -i 'http://localhost:9093/-/ready'
*#readiness*
- curl -s -i 'http://localhost:9093/-/healthy'
*#health*
- curl -s -i 'http://localhost:9093/-/reload'
*#reload*


*blackbox_exporter:*
> /opt/blackbox_exporter/blackbox_exporter --config.check | grep -i "Config file is ok exiting..."

- curl -s -i 'http://localhost:9115/metrics'
*#internal metrics*
- curl -s -i 'http://localhost:9115/probe?target=https://www.google.com&module=http_2xx&debug=true'
*#probe target metrics example*
- curl -s -i 'http://localhost:9115/-/reload'
*#reload*


*node_exporter:*

- curl -s -i 'http://localhost:9100/metrics'
*#internal metrics*
- curl -s -i 'http://localhost:9100/-/reload'
*#reload*


*grafana:*

- curl -s -i 'http://localhost:3000/metrics'
*#internal metrics*


## Dashboards (Grafana)
- https://grafana.com/grafana/dashboards/9096
