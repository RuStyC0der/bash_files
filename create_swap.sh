#!/bin/bash
ROOT_SWAP_DIR='/swap/'
SWAP_FILE_NAME='swap.img'
SWAP_STATUS=`free -m | grep -i swap | awk '{print $2}'`

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit 0
fi

if [[ $SWAP_STATUS != '0' ]]; then
echo "SWAP exist. [Usage SWAP] - "$SWAP_STATUS
exit 1
fi

while [ 1 ]
do
    if [[ $SWAP_STATUS = '0' ]]; then
        echo "SWAP not exist. [Usage SWAP] - "$SWAP_STATUS" Add SWAP ? YES/NO"
        read USER_ANSWER
    fi

    if [[ $USER_ANSWER = 'NO' ]]; then
        echo "Nothing to do."
        exit 0
    elif [[ $USER_ANSWER = 'YES' ]]; then
        DO_STATUS='YES'
        break
    else
        echo "Type only YES or NO"
    fi
done

while [ 1 ]
do
if [[ $DO_STATUS = 'YES' ]]; then

    FREE_DISK=`df -m /|awk '{print $4}'|grep -v 'Avail'`
    echo "[$FREE_DISK MB is free on server]" 
    echo "Input filesize of swapfile in MB [Example][1Gb - 1204Mb] If need add 1Gb of SWAP - type 1024, 2Gb - type 2048"
    read USER_ANSWER_SWAP_FILESIZE

    if (echo "$USER_ANSWER_SWAP_FILESIZE" | grep -E -q "^?[0-9]+$"); then
        USER_ANSWER_SWAP_FILESIZE_STATUS='NUMBER'
        break
    else
        echo "SWAP is int. Not string. Can't create SWAP with your choice "$USER_ANSWER_SWAP_FILESIZE
        continue
    fi

fi
done

    if [[ $USER_ANSWER_SWAP_FILESIZE -ge $FREE_DISK ]]; then
        echo "The filesize of SWAP is too big. Not enough disk spase"
        exit 1
    fi

while [ 1 ]
do

    if [[ $DO_STATUS = 'YES' ]]; then
        FREE_SPASE_LEFT=$((FREE_DISK-USER_ANSWER_SWAP_FILESIZE))
        echo "Free disk space will be "$FREE_SPASE_LEFT" MB"
        echo "Continue ? YES/NO"
        read USER_ANSWER_FREE_LEFT
    fi

    if [[ $USER_ANSWER_FREE_LEFT = 'NO' ]]; then
        echo "Nothing to do."
        exit 0
    elif [[ $USER_ANSWER_FREE_LEFT = 'YES' ]]; then
        STATUS_CREATE_SWAP='NEED_TO_CREATE'
        break
    else
        echo "Type only YES or NO"
    fi

done

if [[ $STATUS_CREATE_SWAP = 'NEED_TO_CREATE' ]]; then
    echo "[CREATING FILE] - "$ROOT_SWAP_DIR$SWAP_FILE_NAME" [FILESIZE] = "$USER_ANSWER_SWAP_FILESIZE"MB"
    mkdir $ROOT_SWAP_DIR
    `fallocate -l $USER_ANSWER_SWAP_FILESIZE"MB" $ROOT_SWAP_DIR$SWAP_FILE_NAME`
    chmod 0600 $ROOT_SWAP_DIR$SWAP_FILE_NAME
    mkswap $ROOT_SWAP_DIR$SWAP_FILE_NAME
    swapon $ROOT_SWAP_DIR$SWAP_FILE_NAME
    timestamp=$(date +%s)
    cp -rp /etc/fstab /etc/fstab_$timestamp
    echo "$ROOT_SWAP_DIR$SWAP_FILE_NAME swap swap sw 0 0" >> /etc/fstab
    cp -rp /etc/sysctl.conf /etc/sysctl.conf_$timestamp
    echo 'vm.swappiness=5' >> /etc/sysctl.conf
    sysctl -p
    echo "[DONE]"
    free -m
fi
