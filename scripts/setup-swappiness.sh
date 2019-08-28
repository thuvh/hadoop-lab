#!/bin/bash

ROOT_DIR=`pwd`
NAME=99-swappiness.conf
SYSCTL_D_HOME=/etc/sysctl.d

if [ -f "$ROOT_DIR/$NAME" ]; then
    sudo mv $ROOT_DIR/$NAME $SYSCTL_D_HOME
    if [ -f "$SYSCTL_D_HOME/$NAME" ]; then
    	sudo chown root:root $SYSCTL_D_HOME/$NAME
    	sudo chmod 644 $SYSCTL_D_HOME/$NAME
    fi
fi
