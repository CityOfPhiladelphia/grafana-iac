export APP_NAME=$1
export ENV_NAME=$2
# Set hostname to `app-env-{old hostname}`
sudo hostnamectl hostname "${APP_NAME}-${ENV_NAME}-$(hostnamectl hostname)"
# Make sure we are in the "server" folder
cd ~/grafana-iac/server
# This script is to be run as ec2-user, not as root
# Install docker and httpd-tools (to create basic auth file)
sudo dnf install -y docker httpd-tools
# Add ec2-user to docker group
sudo usermod -a -G docker ec2-user
# Start docker
sudo systemctl start docker
sudo systemctl enable docker
# Install docker compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
#
sudo chmod +x /usr/local/bin/docker-compose
# Create .htpasswd file for loki and prometheus
export LOKI_USER=$(aws ssm get-parameter --name "/$APP_NAME/$ENV_NAME/loki_user" --with-decryption --query "Parameter.Value" --output text)
export LOKI_PASSWORD=$(aws ssm get-parameter --name "/$APP_NAME/$ENV_NAME/loki_pw" --with-decryption --query "Parameter.Value" --output text)
export PROMETHEUS_USER=$(aws ssm get-parameter --name "/$APP_NAME/$ENV_NAME/prometheus_user" --with-decryption --query "Parameter.Value" --output text)
export PROMETHEUS_PASSWORD=$(aws ssm get-parameter --name "/$APP_NAME/$ENV_NAME/prometheus_pw" --with-decryption --query "Parameter.Value" --output text)
htpasswd -cBb ./docker/nginx/.htpasswd.loki $LOKI_USER $LOKI_PASSWORD
htpasswd -cBb ./docker/nginx/.htpasswd.prometheus $PROMETHEUS_USER $PROMETHEUS_PASSWORD
# Run all these commands as ec2-user (required because it establishes new docker group)
sudo -u ec2-user --preserve-env=APP_NAME,ENV_NAME -i <<'EOF'
# -i logs us in as shell so our pwd gets reset
cd ~/grafana-iac/server
# DB
export GF_DATABASE_HOST=`aws ssm get-parameter --name "/$APP_NAME/$ENV_NAME/rds_host" --query "Parameter.Value" --output text`
export GF_DATABASE_NAME=`aws ssm get-parameter --name "/$APP_NAME/$ENV_NAME/rds_db_name" --query "Parameter.Value" --output text`
export GF_DATABASE_USER=`aws ssm get-parameter --name "/$APP_NAME/$ENV_NAME/rds_user" --with-decryption --query "Parameter.Value" --output text`
export GF_DATABASE_PASSWORD=`aws ssm get-parameter --name "/$APP_NAME/$ENV_NAME/rds_pw" --with-decryption --query "Parameter.Value" --output text`
# DNS
export GF_SERVER_DOMAIN=`aws ssm get-parameter --name "/$APP_NAME/$ENV_NAME/domain_name" --query "Parameter.Value" --output text`
export GF_SERVER_ROOT_URL="https://$GF_SERVER_DOMAIN/"
# Update loki-config.yaml with correct s3 bucket name
export LOKI_S3_BUCKET=`aws ssm get-parameter --name "/$APP_NAME/$ENV_NAME/grafana_s3_name" --query "Parameter.Value" --output text`
envsubst < docker/loki/loki-config-template.yaml > docker/loki/loki-config.yaml
# Now, docker compose
docker-compose -f docker/docker-compose.yaml up -d
EOF

# Good! Loki, Grafana, and Prometheus are now up and running. Time to install alloy for local monitoring
# Alloy cannot be installed until its gpg key is imported
wget -q -O gpg.key https://rpm.grafana.com/gpg.key
sudo rpm --import gpg.key
echo -e '[grafana]\nname=grafana\nbaseurl=https://rpm.grafana.com\nrepo_gpgcheck=1\nenabled=1\ngpgcheck=1\ngpgkey=https://rpm.grafana.com/gpg.key\nsslverify=1\nsslcacert=/etc/pki/tls/certs/ca-bundle.crt' | sudo tee /etc/yum.repos.d/grafana.repo
# Install alloy
sudo yum update -y
sudo dnf install -y alloy
# Copy our config into the right file
sudo cp alloy/config.alloy.hcl /etc/alloy/config.alloy
# Start alloy!
sudo systemctl start alloy
sudo systemctl enable alloy.service
