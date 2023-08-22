# AWS Prometheus exporter

This repo is meant to be a complementary Prometheus exporter for the metrics that are not published to CloudWatch.

Current exposed metrics:

- `aws_vpc_subnet_available_ip_address_count`
- `aws_vpc_subnet_total_ip_address_count`

## Usage

### Authentication

Under-the-hood it uses [`boto3` authentication mechanisms](https://boto3.amazonaws.com/v1/documentation/api/latest/guide/credentials.html). For local development we recommend setting environment variables as mentioned in the `./docker-run-local.sh`.

Required AWS IAM permissions:

- `ec2:DescribeSubnets`

## Development

After a normal docker build, set AWS credentials as environment variables so that you can run the `./docker-run-local.sh` script to start the app locally.
