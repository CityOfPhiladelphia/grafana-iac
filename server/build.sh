# This script is to be run as ec2-user, not as root
# Install docker
sudo dnf install -y docker
# Add ec2-user to docker groyup
sudo usermod -a -G docker ec2-user
# Start docker
sudo systemctl start docker
sudo systemctl enable docker
# Install docker compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
# Run all these commands as ec2-user (required because it establishes new docker group)
# TODO: Put these all in SSM parameter store
# TODO: How do we get the loki-config.yaml file updated?
sudo -u ec2-user -i <<'EOF'
# -i logs us in as shell so our pwd gets reset
cd ~/grafana-iac/server
# DB
export GF_DATABASE_HOST=`aws ssm get-parameter --name /grafana/prd/rds_host --query "Parameter.Value" --output text`
export GF_DATABASE_NAME=`aws ssm get-parameter --name /grafana/prd/rds_db_name --query "Parameter.Value" --output text`
export GF_DATABASE_USER=`aws ssm get-parameter --name /grafana/prd/rds_user --with-decryption --query "Parameter.Value" --output text`
export GF_DATABASE_PASSWORD=`aws ssm get-parameter --name /grafana/prd/rds_pw --with-decryption --query "Parameter.Value" --output text`
# Entra ID
export GF_AUTH_AZUREAD_CLIENT_ID=a
export GF_AUTH_AZUREAD_CLIENT_SECRET=a
export GF_AUTH_AZUREAD_AUTH_URL=a
export GF_AUTH_AZUREAD_TOKEN_URL=a
# Update loki-config.yaml with correct s3 bucket name
export LOKI_S3_BUCKET=`aws ssm get-parameter --name /grafana/prd/grafana_s3_name --query "Parameter.Value" --output text`
envsubst < docker/loki/loki-config-template.yaml > docker/loki/loki-config.yaml
# Now, docker compose
docker-compose -f docker/docker-compose.yaml up -d
EOF
