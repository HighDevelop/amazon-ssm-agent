# amazon-ssm-agent
AWS가 바이너리 배포를 안 해줘서 어쩔 수 없이 만든 저장소

## 미리 빌드한 바이너리로 CoreOS에 설치하기 

``` bash 
#!/bin/bash
set -eo pipefail

export BIN_ROOT_DIR=/opt/bin
export BIN_DIR=${BIN_ROOT_DIR}/ssm
export CONFIG_DIR=/etc/amazon/ssm

if [[ ! -f "${BIN_DIR}/amazon-ssm-agent" ]]; then
    pushd ${BIN_ROOT_DIR}

    /usr/bin/curl --silent -L https://github.com/DailyHotel/amazon-ssm-agent/releases/download/v2.0.805.1/ssm.linux-amd64.tar.gz | tar zx 

    chown -R root:root ssm
    mv -f ssm/amazon-ssm-agent.json $CONFIG_DIR/amazon-ssm-agent.json
    mv -f ssm/seelog_unix.xml $CONFIG_DIR/seelog.xml

    popd
fi

if [[ ! -f "etc/systemd/system/amazon-ssm-agent.service" ]]; then

    cat <<EOF > /etc/systemd/system/amazon-ssm-agent.service
[Unit]
Description=amazon-ssm-agent
[Service]
Type=simple 
WorkingDirectory=$BIN_DIR
ExecStart=$BIN_DIR/amazon-ssm-agent
KillMode=process
Restart=on-failure
RestartSec=15min
[Install]
WantedBy=network-online.target
EOF

fi

( systemctl is-active amazon-ssm-agent.service --quiet || ( systemctl enable amazon-ssm-agent.service && systemctl start amazon-ssm-agent.service ) )
```

## CoreOS 직접 빌드하고 설치하기

``` bash
#!/bin/bash
# vim: et sr sw=4 ts=4 smartindent:
#
# 00030-amazon-ssm-agent.sh
#
# — pulls golang:1.6 image
# — checks out latest tag
# — builds amazon-ssm-agent
# — moves binaries into ~core/bin/ssm/
set -eo pipefail

export WERK_DIR=/home/core/ssm
export BIN_DIR=/opt/bin/ssm
export CONFIG_DIR=/etc/amazon/ssm
export DOCKER_BUILD_BOX=ssm-build
export DOCKER_GOLANG_TAG=golang:1.8
export DOCKER_WERKSPACE=/workspace/src/github.com/aws/amazon-ssm-agent


if [[ ! -f "${BIN_DIR}/amazon-ssm-agent" ]]; then
    git clone https://github.com/aws/amazon-ssm-agent.git $WERK_DIR
    pushd $WERK_DIR
     # git checkout $(git describe — abbrev=0 — tags)
     git checkout master
     docker run --rm --name "$DOCKER_BUILD_BOX" \
     -v "$PWD":"$DOCKER_WERKSPACE" \
     -w "$DOCKER_WERKSPACE" \
     "$DOCKER_GOLANG_TAG" \
     make build-linux
    mkdir -p $BIN_DIR
     mv bin/linux_amd64/* $BIN_DIR/
    mkdir -p $CONFIG_DIR
     mv amazon-ssm-agent.json.template $CONFIG_DIR/amazon-ssm-agent.json
     mv seelog_unix.xml $CONFIG_DIR/seelog.xml
    popd
    ( docker rm -f "$DOCKER_BUILD_BOX" || true )
    ( docker rmi "$DOCKER_GOLANG_TAG" || true)
    rm -rf $WERK_DIR
fi

if [[ ! -f "etc/systemd/system/amazon-ssm-agent.service" ]]; then

    cat <<EOF > /etc/systemd/system/amazon-ssm-agent.service
[Unit]
Description=amazon-ssm-agent
[Service]
Type=simple 
WorkingDirectory=$BIN_DIR
ExecStart=$BIN_DIR/amazon-ssm-agent
KillMode=process
Restart=on-failure
RestartSec=15min
[Install]
WantedBy=network-online.target
EOF

fi

( systemctl is-active amazon-ssm-agent.service --quiet || ( systemctl enable amazon-ssm-agent.service && systemctl start amazon-ssm-agent.service ) )
```

## 참고 자료

* [How to work with AWS Simple System Manager on CoreOS](https://medium.com/levops/how-to-work-with-aws-simple-system-manager-on-coreos-4741853dfd50)