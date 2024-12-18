#!/bin/bash

set -x

LOG_FILE="/tmp/user_data_script.log"

touch $LOG_FILE

exec > $LOG_FILE 2>&1

echo "Starting User Data Script v1"

echo "Creating .env file"
sudo -u csye6225 bash <<'EOL'

echo "Secret name: ${secret_name} "
echo "AWS Region: ${aws_region}"
MYSQL_PASSWORD=$(aws secretsmanager get-secret-value --secret-id ${secret_name} --region ${aws_region} | jq -r '.SecretString')
echo "AWS MYSQL_PASSWORD: $MYSQL_PASSWORD" 


cd /opt/csye6225/webapp



touch .env
echo "PORT=${application_port}" >> .env
echo "MYSQL_USER=${RDS_username}" >> .env
echo "MYSQL_PASSWORD=$MYSQL_PASSWORD" >> .env
echo "MYSQL_HOST=${db_host}" >> .env
echo "MYSQL_PORT=${db_port}" >> .env
echo "MYSQL_DATABASE_TEST=test_db" >> .env
echo "MYSQL_DATABASE_PROD=${RDS_db_name}" >> .env
echo "STATSD_CLIENT=127.0.0.1" >> .env
echo "STATSD_PORT=8125" >> .env
echo "BUCKET_NAME=${bucket_name}" >> .env
echo "AWS_REGION=${aws_region}" >> .env
echo "LOG_LEVEL=info" >> .env
echo "BASE_URL=${base_url}" >> .env
echo "SNS_TOPIC_ARN=${sns_topic}" >> .env

EOL


echo "Reloading systemd and restarting webapp service"
sudo systemctl daemon-reload
sudo systemctl restart webapp
echo "Webapp service restarted"

echo "Fetching CloudWatch Agent config"
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/opt/csye6225/webapp/cloudwatch-config.json -s
echo "CloudWatch Agent config fetched"

echo "Restarting CloudWatch agent"
sudo systemctl restart amazon-cloudwatch-agent
echo "CloudWatch agent restarted"

echo "User Data Script Completed"