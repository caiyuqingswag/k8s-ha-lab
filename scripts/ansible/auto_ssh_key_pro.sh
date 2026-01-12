#!/bin/bash

USER=root
PASSWORD_FILE=./password.txt
HOST_FILE=./hosts.txt
MAX_PARALLEL=20
RETRY=2
LOG_FILE=./ssh_push.log
FAIL_FILE=./failed_hosts.txt

PASSWORD=$(cat $PASSWORD_FILE)

touch $LOG_FILE
> $FAIL_FILE

# 生成 SSH key（如果不存在）
if [ ! -f ~/.ssh/id_rsa ]; then
    echo "[INFO] 生成 SSH key..."
    ssh-keygen -t rsa -b 4096 -N "" -f ~/.ssh/id_rsa
fi

function push_key() {
    host=$1
    for ((i=1;i<=RETRY;i++)); do
        echo "[INFO] [$host] 尝试 $i/$RETRY" | tee -a $LOG_FILE

        sshpass -p "$PASSWORD" ssh-copy-id \
            -o StrictHostKeyChecking=no \
            -o ConnectTimeout=5 \
            ${USER}@${host} >> $LOG_FILE 2>&1

        if ssh -o BatchMode=yes -o ConnectTimeout=5 ${USER}@${host} "echo ok" &>/dev/null; then
            echo "[SUCCESS] $host" | tee -a $LOG_FILE
            return 0
        fi
    done

    echo "[FAILED] $host" | tee -a $LOG_FILE
    echo "$host" >> $FAIL_FILE
}

export -f push_key
export USER PASSWORD RETRY LOG_FILE

cat $HOST_FILE | xargs -n 1 -P $MAX_PARALLEL -I {} bash -c 'push_key "$@"' _ {}

echo "======================="
echo "完成"
echo "失败主机列表：$FAIL_FILE"
echo "日志文件：$LOG_FILE"
echo "======================="
