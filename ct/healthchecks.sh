#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/florianbussmann/ProxmoxVE/healthchecks/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: healthchecks (healthchecks)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/healthchecks/healthchecks

APP="healthchecks"
var_tags="${var_tags:-management;fitness}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-1024}"
var_disk="${var_disk:-6}"
var_os="${var_os:-debian}"
var_version="${var_version:-12}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -d /opt/$APP ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  RELEASE=$(curl -fsSL https://api.github.com/repos/healthchecks/healthchecks/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4)}')
  if [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]] || [[ ! -f /opt/${APP}_version.txt ]]; then
    msg_info "Stopping $APP"
    systemctl stop $APP
    msg_ok "Stopped $APP"

    msg_info "Updating $APP to v${RELEASE}"
    temp_file=$(mktemp)
    curl -fsSL "https://github.com/healthchecks/healthchecks/archive/refs/tags/v$RELEASE.tar.gz" -o "$temp_file"
    tar xzf "$temp_file"
    cp -rf "$APP"-"$RELEASE"/* /opt/"${APP}"/
    chown -R healthchecks:healthchecks /opt/"${APP}"/
    cd /opt/"${APP}"/
    python3 manage.py migrate &>/dev/null
    echo "${RELEASE}" >/opt/${APP}_version.txt
    msg_ok "Updated $APP to v${RELEASE}"

    msg_info "Starting $APP"
    systemctl start $APP
    msg_ok "Started $APP"

    msg_info "Cleaning Up"
    rm -rf "$temp_file"
    msg_ok "Cleanup Completed"

    msg_ok "Update Successful"
  else
    msg_ok "No update required. ${APP} is already at v${RELEASE}"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8000${CL}"
