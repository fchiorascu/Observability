#!/usr/bin/python
from prometheus_client import start_http_server, Metric, REGISTRY
from requests.packages.urllib3.exceptions import InsecureRequestWarning
from requests.exceptions import ConnectionError
import requests
import time
import json
import sys

class prometheusOnlineCollector():
    def __init__(self, endpoint, headers):
        self.endpoint = endpoint
        self.headers = headers

    def collect(self):
        try:
            prometheus_targets_response = requests.get(self.endpoint, headers = self.headers, verify=False, timeout=10)
            response_time = prometheus_targets_response.elapsed.total_seconds()
            status = prometheus_targets_response.json()['status']
            if status == 'success':
                status = 1
            else:
                status = 0
        except ConnectionError:
            status = 0
            response_time = 0

        metric = Metric('prometheus_targets','Prometheus targets success','gauge')
        metric.add_sample('prometheus_targets',value=status,labels={})
        yield metric

        metric = Metric('prometheus_targets_time','Response time from prometheus_targets','gauge')
        metric.add_sample('prometheus_targets_time',value=response_time,labels={})
        yield metric

if __name__ == '__main__':
    prometheusUrl = 'http://localhost:9090/api/v1/targets'
    prometheusHeaders = {"Content-Type": "application/json"}
    requests.packages.urllib3.disable_warnings(InsecureRequestWarning)
    REGISTRY.register(prometheusOnlineCollector(prometheusUrl, prometheusHeaders))
    start_http_server(9101)
    while True: time.sleep(1)
