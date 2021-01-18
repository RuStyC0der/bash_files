#!/bin/bash
ROOT_SWAP_DIR='/swap/'
SWAP_FILE_NAME='swap.img'
SWAP_STATUS=`free -m | grep -i swap | awk '{print $2}'`

if [[ $SWAP_STATUS != '0' ]]; then
echo "SWAP EXIST. USAGE - "$SWAP_STATUS
exit 1
fi

if [[ $SWAP_STATUS = '0' ]]; then
echo "SWAP NOT EXIST. USAGE - "$SWAP_STATUS" ADD SWAP ? YES/NO"
read USER_ANSWER
fi

if [[ $USER_ANSWER = 'NO' ]]; then
echo "Nothing to do."
elif [[ $USER_ANSWER = 'YES' ]]; then
DO_STATUS='YES'
FREE_DISK=`df -m /|awk '{print $4}'|grep -v 'Avail'`
echo "Input filesize of swapfile in MB (example - 1Gb type 1024)"
read USER_ANSWER_SWAP_FILESIZE
else
echo "Type only YES or NO"
fi

if (echo "$USER_ANSWER_SWAP_FILESIZE" | grep -E -q "^?[0-9]+$"); then
USER_ANSWER_SWAP_FILESIZE_STATUS='NUMBER'
else
USER_ANSWER_SWAP_FILESIZE_STATUS='NOT_NUMBER'
fi

if [[ $USER_ANSWER_SWAP_FILESIZE_STATUS = 'NOT_NUMBER' ]]; then
echo "SWAP is int. Not string. Can't create SWAP with your choice "$USER_ANSWER_SWAP_FILESIZE
exit 1
fi

if [[ $USER_ANSWER_SWAP_FILESIZE -ge $FREE_DISK ]]; then
echo "The filesize of SWAP is too big. Not enough disk spase"
fi

if [[ $DO_STATUS = 'YES' ]]; then
FREE_SPASE_LEFT=$((FREE_DISK-USER_ANSWER_SWAP_FILESIZE))
echo "Free disk space will be "$FREE_SPASE_LEFT" MB"
echo "Continue ? YES/NO"
read USER_ANSWER_FREE_LEFT
fi

if [[ $USER_ANSWER_FREE_LEFT = 'NO' ]]; then
echo "Nothing to do."
elif [[ $USER_ANSWER_FREE_LEFT = 'YES' ]]; then
STATUS_CREATE_SWAP='NEED_TO_CREATE'
else
echo "Type only YES or NO"
fi

if [[ $STATUS_CREATE_SWAP = 'NEED_TO_CREATE' ]]; then
mkdir $ROOT_SWAP_DIR
`fallocate -l $USER_ANSWER_SWAP_FILESIZE"MB" $ROOT_SWAP_DIR$SWAP_FILE_NAME`
chmod 0600 $ROOT_SWAP_DIR$SWAP_FILE_NAME
mkswap $ROOT_SWAP_DIR$SWAP_FILE_NAME
swapon $ROOT_SWAP_DIR$SWAP_FILE_NAME
echo "$ROOT_SWAP_DIR$SWAP_FILE_NAME swap swap sw 0 0" >> /etc/fstab
echo "[CREATING FILE] - "$ROOT_SWAP_DIR$SWAP_FILE_NAME" [FILESIZE] = "$USER_ANSWER_SWAP_FILESIZE"MB"
echo "DONE"
free -m
fi
