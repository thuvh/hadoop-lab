#!/bin/bash

USERNAME=thuvh
USERNAME_HOME=/home/$USERNAME
USERNAME_HOME_SSH=$USERNAME_HOME/.ssh
USERNAME_HOME_SSH_PRIVATE_KEY=$USERNAME_HOME_SSH/id_rsa
USERNAME_HOME_SSH_PUBLIC_KEY=$USERNAME_HOME_SSH/id_rsa.pub
USERNAME_HOME_SSH_AUTHORIZED_KEYS=$USERNAME_HOME_SSH/authorized_keys

ROOT_HOME=/root
ROOT_HOME_SSH=$ROOT_HOME/.ssh
ROOT_HOME_SSH_PRIVATE_KEY=$ROOT_HOME_SSH/id_rsa
ROOT_HOME_SSH_PUBLIC_KEY=$ROOT_HOME_SSH/id_rsa.pub
ROOT_HOME_SSH_AUTHORIZED_KEYS=$ROOT_HOME/authorized_keys

sudo adduser --disabled-password --gecos "" $USERNAME
sudo usermod -aG sudo $USERNAME
echo "$USERNAME:p@&&vv0rd" | sudo chpasswd

ROOT_DIR=`pwd`
SSH_AUTHORIZED_KEYS=$ROOT_DIR/.ssh/authorized_keys
SSH_AUTHORIZED_KEYS_TEMP=$ROOT_DIR/authorized_keys_1
PASSWORDLESS_SRC_FILE=$ROOT_DIR/passwordless
PASSWORDLESS_DST_FILE=/etc/sudoers.d/passwordless

curl -O https://gitlab.com/thuvh.keys
cat $SSH_AUTHORIZED_KEYS $ROOT_DIR/.ssh/id_rsa.pub $ROOT_DIR/thuvh.keys > $SSH_AUTHORIZED_KEYS_TEMP
mv $SSH_AUTHORIZED_KEYS_TEMP $SSH_AUTHORIZED_KEYS
chmod 644 $SSH_AUTHORIZED_KEYS

# user keygst
if [ -d "$USERNAME_HOME" ]; then
    if [ -d "$USERNAME_HOME_SSH" ]; then
        sudo cp -r $ROOT_DIR/.ssh/* $USERNAME_HOME_SSH
    else
        sudo cp -r $ROOT_DIR/.ssh $USERNAME_HOME_SSH
    fi
    sudo chown -R $USERNAME:$USERNAME $USERNAME_HOME_SSH
    sudo chmod 700 $USERNAME_HOME_SSH
    if [ -f "$USERNAME_HOME_SSH_PRIVATE_KEY" ]; then
        chmod 600 $USERNAME_HOME_SSH_PRIVATE_KEY
    fi
    if [ -f "$USERNAME_HOME_SSH_PUBLIC_KEY" ]; then
        chmod 644 $USERNAME_HOME_SSH_PUBLIC_KEY
    fi
    if [ -f "$USERNAME_HOME_SSH_AUTHORIZED_KEYS" ]; then
        chmod 644 $USERNAME_HOME_SSH_AUTHORIZED_KEYS
    fi
fi

# root key
if [ -d "$ROOT_HOME_SSH" ]; then
    sudo cp -r $ROOT_DIR/.ssh/* $ROOT_HOME_SSH
else
    sudo cp -r $ROOT_DIR/.ssh $ROOT_HOME_SSH
fi
sudo chown -R root:root $ROOT_HOME_SSH
sudo chmod 700 $ROOT_HOME_SSH

if [ -f "$ROOT_HOME_SSH_PRIVATE_KEY" ]; then
    chmod 600 $ROOT_HOME_SSH_PRIVATE_KEY
fi
if [ -f "$ROOT_HOME_SSH_PUBLIC_KEY" ]; then
    chmod 644 $ROOT_HOME_SSH_PUBLIC_KEY
fi
if [ -f "$ROOT_HOME_SSH_AUTHORIZED_KEYS" ]; then
    chmod 644 $ROOT_HOME_SSH_AUTHORIZED_KEYS
fi

# password less
if [ -f "$PASSWORDLESS_SRC_FILE" ]; then
    sudo mv $PASSWORDLESS_SRC_FILE $PASSWORDLESS_DST_FILE
    if [ -f "$PASSWORDLESS_DST_FILE" ]; then
        sudo chown root:root $PASSWORDLESS_DST_FILE
        sudo chmod 440 $PASSWORDLESS_DST_FILE
    fi
fi
