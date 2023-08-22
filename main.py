"""AWS Prometheus exporter for metrics that are not currently available in CloudWatch"""

from datetime import datetime
import logging
import os
import re
import threading
from wsgiref.simple_server import make_server
from prometheus_client import make_wsgi_app, Gauge
import prometheus_client
import boto3

prometheus_client.REGISTRY.unregister(prometheus_client.GC_COLLECTOR)
prometheus_client.REGISTRY.unregister(prometheus_client.PLATFORM_COLLECTOR)
prometheus_client.REGISTRY.unregister(prometheus_client.PROCESS_COLLECTOR)

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class AwsExporter:
    """
    Representation of Prometheus metrics and loop to fetch and transform
    application metrics into Prometheus metrics.
    """

    def __init__(self):
        # Get configuration from environment variables
        self.region = os.getenv("AWS_REGION", "eu-central-1")
        self.job = os.getenv("JOB", "aws_vpc_subnet")
        self.instance = os.getenv("INSTANCE", "0")
        self.polling_interval_seconds = int(os.getenv("SCRAPE_INTERVAL", "60"))

        common_labels = ["vpc", "subnet", "name"]

        # Prometheus metrics to collect
        self.available_ip_addresses = Gauge(
            "aws_vpc_subnet_available_ip_address_count",
            "Number of available IPs per subnet",
            common_labels,
        )
        self.total_ip_addresses = Gauge(
            "aws_vpc_subnet_total_ip_address_count",
            "Total number of IPs per subnet",
            common_labels,
        )

    def get_metrics_periodically(self):
        # Invoke itself after 'self.polling_interval_seconds' to keep the loop ongoing
        threading.Timer(
            self.polling_interval_seconds, self.get_metrics_periodically
        ).start()
        self.expose_subnets_metrics()

    @staticmethod
    def aws_tags_to_dict(tags):
        """
        Convert the tags array of Key/Value pairs in a dict. Example from
        tags = [
            {"Key": "some_key_name", "Value": "value of some_key_name"},
            {"Key": "other_key_name", "Value": "value of other_key_name"},
        ]
        returns
        {
            "some_key_name": "value of some_key_name",
            "other_key_name": "value of other_key_name"
        }
        """
        tags_dict = {}
        for tag in tags:
            if ("Key" in tag) and ("Value" in tag):
                tags_dict[tag["Key"]] = tag["Value"]
        return tags_dict

    def expose_subnets_metrics(self):
        """
        Get subnets infos from AWS and return a list with, for each subnet:
        - SubnetId
        - VpcId
        - AvailableIpAddressCount
        - TotalIpAddressCount (computed from CidrBlock)
        """
        ec2 = boto3.client("ec2", region_name=self.region)

        subnets = ec2.describe_subnets()

        for subnet in subnets["Subnets"]:
            # Ex: CidrBlock = "123.123.123.123/45" --> we want the "45" as int()
            cidr_network_prefix = int(re.sub(r"^.*\/", "", subnet["CidrBlock"]))
            total_ip_address_count = 2 ** (32 - cidr_network_prefix)

            # Get subnet name from Tags (if exists) or default to SubnetId
            name = subnet["SubnetId"]
            if "Tags" in subnet:
                tags = AwsExporter.aws_tags_to_dict(subnet["Tags"])
                if "Name" in tags:
                    name = tags["Name"]

            # Set Prometheus metrics with labels
            self.available_ip_addresses.labels(
                vpc=subnet["VpcId"], name=name, subnet=subnet["SubnetId"]
            ).set(subnet["AvailableIpAddressCount"])
            self.total_ip_addresses.labels(
                vpc=subnet["VpcId"], name=name, subnet=subnet["SubnetId"]
            ).set(total_ip_address_count)

        logger.info("%s Gathered metrics from AWS", datetime.now())


def main():
    exporter_port = int(os.getenv("EXPORTER_PORT", "9877"))
    app_metrics = AwsExporter()

    # Run it periodically every X seconds
    app_metrics.get_metrics_periodically()

    app = make_wsgi_app()
    httpd = make_server("0.0.0.0", exporter_port, app)
    httpd.serve_forever()


if __name__ == "__main__":
    main()
