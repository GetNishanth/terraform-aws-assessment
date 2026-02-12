#!/bin/bash
# EC2 User Data Script
# Runs on instance launch to configure the environment

set -e

# Update system packages
dnf update -y

# Install AWS CLI v2 (if not already installed)
if ! command -v aws &> /dev/null; then
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    ./aws/install
    rm -rf aws awscliv2.zip
fi

# Install CloudWatch agent
dnf install -y amazon-cloudwatch-agent

# Create application directory
mkdir -p /opt/app/logs

# Configure log rotation
cat > /etc/logrotate.d/app-logs <<EOF
/opt/app/logs/*.log {
    daily
    rotate 7
    compress
    missingok
    notifempty
    create 0644 ec2-user ec2-user
}
EOF

# Create a simple application startup script
cat > /opt/app/startup.sh <<'EOF'
#!/bin/bash
echo "Application starting at $(date)" >> /opt/app/logs/app.log
echo "Environment: ${environment}" >> /opt/app/logs/app.log
echo "Instance: ${instance_index}" >> /opt/app/logs/app.log
echo "Log Bucket: ${log_bucket}" >> /opt/app/logs/app.log

# Upload initial log to S3
aws s3 cp /opt/app/logs/app.log s3://${log_bucket}/instance-${instance_index}/app-$(date +%Y%m%d-%H%M%S).log
EOF

chmod +x /opt/app/startup.sh

# Run startup script
/opt/app/startup.sh

# Create systemd service for application
cat > /etc/systemd/system/app.service <<EOF
[Unit]
Description=Application Service
After=network.target

[Service]
Type=simple
User=ec2-user
WorkingDirectory=/opt/app
ExecStart=/opt/app/startup.sh
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# Enable and start the service
systemctl daemon-reload
systemctl enable app.service

# Install additional monitoring tools
dnf install -y htop nano vim

# Signal completion
echo "User data script completed successfully at $(date)" >> /var/log/user-data.log
