#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: healthchecks (healthchecks)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/healthchecks/healthchecks

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
  git
msg_ok "Installed Dependencies"

msg_info "Installing Python"
$STD apt-get install -y python3-pip
rm -rf /usr/lib/python3.*/EXTERNALLY-MANAGED
msg_ok "Installed Python"

msg_info "Setting up healthchecks"
$STD adduser healthchecks --disabled-password --gecos ""
mkdir /opt/healthchecks
RELEASE=$(curl -fsSL https://api.github.com/repos/healthchecks/healthchecks/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4)}')
curl -fsSL "https://github.com/healthchecks/healthchecks/archive/refs/tags/v$RELEASE.tar.gz" -o "v$RELEASE.tar.gz"
$STD ls -la
tar xzf v$RELEASE.tar.gz
$STD ls -la
mv healthchecks-$RELEASE/* /opt/healthchecks
$STD ls -la /opt/healthchecks
cd /opt/healthchecks
cat <<EOF >/opt/healthchecks/.env
ALLOWED_HOSTS=*
SITE_ROOT=http://0.0.0.0:8000
EOF

$STD pip install -r requirements.txt
$STD python3 manage.py migrate
$STD python3 manage.py createsuperuser
echo "${RELEASE}" >/opt/healthchecks_version.txt
msg_ok "Finished setting up healthchecks"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/healthchecks.service
[Unit]
Description=healthchecks Service
After=network.target

[Service]
Type=simple
User=healthchecks
WorkingDirectory=/opt/healthchecks
EnvironmentFile=/opt/healthchecks/.env
ExecStart=python3 manage.py runserver 0.0.0.0:8000
Restart=always

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now healthchecks
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"

motd_ssh
customize
