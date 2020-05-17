# Observability Stack <a name="top"></a>
Observability is a measure of how well internal states of a system can be inferred by knowledge of its external outputs.


## Components
- [ ] **Visualisation**
- Grafana is the open source analytics & monitoring solution for every database.
- [ ] **Monitoring**
- Prometheus collects metrics from monitored targets by scraping metrics HTTP endpoints on these targets.
- node_exporter: collects metrics from node/system/os/vm.
- exporters: colects metrics from different applications.
- [ ] **Alerting**
Alerting rules in Prometheus servers send alerts to an Alertmanager. The Alertmanager then manages those alerts, including silencing, inhibition, aggregation and sending out notifications via methods such as email, on-call notification systems, and chat platforms.


## RUN
To run the application locally below are the commands and arguments used in CLI.

*blackbox_exporter:*
> /opt/blackbox_exporter/blackbox_exporter --config.file /opt/blackbox_exporter/blackbox.yml --log.level=debug --log.format=json

*grafana:*
> /usr/share/grafana/bin/grafana-cli plugins install jdbranham-diagram-panel && /usr/share/grafana/bin/grafana-cli plugins install grafana-worldmap-panel && /usr/share/grafana/bin/grafana-cli plugins install grafana-piechart-panel && /usr/share/grafana/bin/grafana-server restart
		
*prometheus:*
> /opt/prometheus/prometheus--config.file /opt/prometheus/prometheus.yml --storage.tsdb.path=/data/prometheus --web.console.templates=/opt/prometheus/consoles --web.console.libraries=/opt/prometheus/console_libraries --web.enable-lifecycle --storage.tsdb.retention.time=31d --storage.tsdb.max-block-duration=72h --storage.tsdb.min-block-duration=2h --log.level=debug --log.format=json

*alertmanager:*
> /opt/alertmanager/alertmanager --config.file /opt/alertmanager/alertmanager.yml --storage.path=/opt/alertmanager/data/ --data.retention=120h --log.level=debug --log.format=json

*node_exporter:*
> /opt/node_exporter/node_exporter --web.listen-address=0.0.0.0:9100 --web.disable-exporter-metrics --collector.ntp --collector.systemd --collector.tcpstat --collector.processes--collector.interrupts --no-collector.zfs --no-collector.arp --no-collector.nfs --no-collector.ipvs --no-collector.nfsd --no-collector.wifi --no-collector.edac --no-collector.mdadm --no-collector.hwmon --no-collector.timex --no-collector.logind --no-collector.bcache --no-collector.bonding --no-collector.textfile --no-collector.conntrack --no-collector.infiniband --collector.systemd.unit-whitelist=(grafana-server|prometheus|alertmanager|node_exporter|sshd|crond|ntpd)\\.service --log.level=debug --log.format=logger:stdout?json=true


## Check configuration
To check the application configuration with below commands and arguments used in CLI.

*blackbox_exporter:*
> /opt/blackbox_exporter/blackbox_exporter --config.check | grep -i "Config file is ok exiting..."

*grafana:*
> /usr/share/grafana/bin/grafana-cli plugins install jdbranham-diagram-panel && /usr/share/grafana/bin/grafana-cli plugins install grafana-worldmap-panel && /usr/share/grafana/bin/grafana-cli plugins install grafana-piechart-panel && /usr/share/grafana/bin/grafana-server restart
		
*prometheus:*
> /opt/prometheus/promtool check config /opt/prometheus/prometheus.yml

- curl -s -i 'http://localhost:9090/-/ready';echo $?
*#readiness*
- curl -s -i 'http://localhost:9090/-/healthy';echo $?
*#health*
- curl -s -i 'http://localhost:9090/status';echo $?
*#status page*
- curl -s -i 'http://localhost:9090/metrics';echo $?
*#internal metrics*
- curl -s -i 'http://localhost:9090/metrics' | /opt/prometheus/promtool check metrics;echo $?
*#internal metrics correctness*

*alertmanager:*
> /opt/alertmanager/amtool --alertmanager.url=http://localhost:9093 check-config /opt/alertmanager/alertmanager.yml

- curl -s -i 'http://localhost:9093/metrics';echo $?  
*#internal metrics*
- curl -s -i 'http://localhost:9093/api/v2/status';echo $?
*#status page*
- curl -s -i 'http://localhost:9093/-/ready';echo $?
*#readiness*
- curl -s -i 'http://localhost:9093/-/healthy';echo $?
*#health*

*blackbox_exporter:*
> /opt/blackbox_exporter/blackbox_exporter --config.check | grep -i "Config file is ok exiting..."

- curl -s -i 'http://localhost:9115/metrics';echo $?
*#internal metrics*
- curl -s -i 'http://localhost:9115/probe?target=https://www.google.com&module=http_2xx&debug=true';echo $?
*#probe target metrics example*

*node_exporter:*

- curl -s -i 'http://localhost:9100/metrics';echo $?
*#internal metrics*


## Dashboards (Grafana)
- https://grafana.com/grafana/dashboards/9096
