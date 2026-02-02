#!/bin/bash
set -e

# Update system
apt update -y

# Install basic tools

apt install -y git wget curl vim

# Install Node.js (for backend apps)
curl -fsSL https://rpm.nodesource.com/setup_20.x | bash -
apt install -y nodejs

# Install Python and pip
apt install -y python3 python3-pip

# Install Docker (optional)
apt install -y docker.io
systemctl enable docker
systemctl start docker
usermod -aG docker ec2-user

# Install CloudWatch Agent
wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.deb
dpkg -i -E ./amazon-cloudwatch-agent.deb
rm -f ./amazon-cloudwatch-agent.deb

# Configure CloudWatch Agent
cat > /opt/aws/amazon-cloudwatch-agent/etc/config.json <<'EOFCW'
{
  "metrics": {
    "namespace": "${project_name}",
    "metrics_collected": {
      "cpu": {
        "measurement": [
          {"name": "cpu_usage_idle", "rename": "CPU_IDLE", "unit": "Percent"},
          {"name": "cpu_usage_iowait", "rename": "CPU_IOWAIT", "unit": "Percent"}
        ],
        "metrics_collection_interval": 60,
        "totalcpu": false
      },
      "disk": {
        "measurement": [
          {"name": "used_percent", "rename": "DISK_USED", "unit": "Percent"}
        ],
        "metrics_collection_interval": 60,
        "resources": ["*"]
      },
      "mem": {
        "measurement": [
          {"name": "mem_used_percent", "rename": "MEM_USED", "unit": "Percent"}
        ],
        "metrics_collection_interval": 60
      }
    }
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/app/application.log",
            "log_group_name": "/${project_name}/backend/application",
            "log_stream_name": "{instance_id}"
          }
        ]
      }
    }
  }
}
EOFCW

# Start CloudWatch Agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -a fetch-config \
    -m ec2 \
    -s \
    -c file:/opt/aws/amazon-cloudwatch-agent/etc/config.json

# Create application directory
mkdir -p /var/www/app
mkdir -p /var/log/app
chown -R ec2-user:ec2-user /var/www/app
chown -R ec2-user:ec2-user /var/log/app

# Create a simple Node.js backend application
cat > /var/www/app/server.js <<'EOFJS'
const http = require('http');
const os = require('os');

const PORT = process.env.PORT || 80;

const server = http.createServer((req, res) => {
    const timestamp = new Date().toISOString();
    console.log(timestamp + ' - ' + req.method + ' ' + req.url);
    
    if (req.url === '/health') {
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ status: 'healthy', hostname: os.hostname() }));
    } else if (req.url === '/') {
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({
            message: 'Backend API is running',
            hostname: os.hostname(),
            timestamp: new Date().toISOString()
        }));
    } else {
        res.writeHead(404, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ error: 'Not found' }));
    }
});

server.listen(PORT, '0.0.0.0', () => {
    console.log('Server running on port ' + PORT);
});
EOFJS

# Create systemd service for the backend app
cat > /etc/systemd/system/backend-app.service <<EOFSVC
[Unit]
Description=Backend Application
After=network.target

[Service]
Type=simple
User=ec2-user
WorkingDirectory=/var/www/app
ExecStart=/usr/bin/node /var/www/app/server.js
Restart=on-failure
RestartSec=10
StandardOutput=append:/var/log/app/application.log
StandardError=append:/var/log/app/application.log

[Install]
WantedBy=multi-user.target
EOFSVC

# Enable and start the backend service
systemctl daemon-reload
systemctl enable backend-app
systemctl start backend-app

# Setup automatic security updates
apt install -y unattended-upgrades
systemctl enable --now unattended-upgrades.timer

echo "Backend instance setup complete!"