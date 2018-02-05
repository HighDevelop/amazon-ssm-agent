#!/bin/bash +x
set -eo pipefail

export BIN_ROOT_DIR=/opt/ssm
export BIN_DIR=${BIN_ROOT_DIR}/bin
export CONFIG_DIR=/etc/amazon/ssm

mkdir -p ${BIN_ROOT_DIR}

mkdir -p ${CONFIG_DIR}

pushd ${BIN_ROOT_DIR}

/usr/bin/curl --silent -L https://github.com/DailyHotel/amazon-ssm-agent/releases/download/v2.0.805.1/ssm.linux-amd64.tar.gz | tar zx

chown -R root:root ssm
mv -f ssm/amazon-ssm-agent.json $CONFIG_DIR/amazon-ssm-agent.json
mv -f ssm/seelog_unix.xml $CONFIG_DIR/seelog.xml
mv -f ssm bin
popd