#!/bin/bash
  sudo -u csye6225 bash <<'EOL'
  cd /opt/csye6225/webapp
  touch .env
  echo "PORT=${application_port}" >> .env
  echo "MYSQL_USER=${RDS_username}" >> .env
  echo "MYSQL_PASSWORD=${RDS_password}" >> .env
  echo "MYSQL_HOST=${db_host}" >> .env
  echo "MYSQL_PORT=${db_port}" >> .env
  echo "MYSQL_DATABASE_TEST=test_db" >> .env
  echo "MYSQL_DATABASE_PROD=${RDS_db_name}" >> .env
  echo "STATSD_CLIENT=127.0.0.1" >> .env
  echo "STATSD_PORT=8125" >> .env
  echo "BUCKET_NAME=${bucket_name}" >> .env
  echo "BUCKET_REGION=${aws_region}" >> .env
  EOL
  sudo systemctl daemon-reload
  sudo systemctl restart webapp
  echo "B"

  sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -c file:/opt/csye6225/webapp/cloudwatch-config.json \
  -s
  sudo systemctl restart amazon-cloudwatch-agent