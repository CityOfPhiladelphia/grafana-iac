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
