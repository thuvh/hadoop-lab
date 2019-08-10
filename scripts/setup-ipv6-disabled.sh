#!/bin/bash

ROOT_DIR=`pwd`
NAME=99-ipv6-thuvh.conf
SYSCTL_D_HOME=/etc/sysctl.d

if [ -f "$ROOT_DIR/$NAME" ]; then
    sudo mv $ROOT/$NAME $SYSCTL_D_HOME
    sudo chown root:root $SYSCTL_D_HOME/$NAME
    sudo chmod 644 $SYSCTL_D_HOME/$NAME
fi
