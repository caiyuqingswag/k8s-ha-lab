ansible-playbook -i inventory.ini site.yml --tags velero --ask-vault-pass


Velero 部署完后，备份分两类：

1. 手动备份：你主动执行一次
2. 定时备份：按计划自动备份

你现在如果用的是：

velero_enable_volume_snapshots: false
velero_deploy_node_agent: true

那意思是：

K8s 资源：备份到 MinIO
PVC 数据：通过 node-agent 文件级备份到 MinIO
云盘快照：不使用
1. 先检查 Velero 是否正常
   kubectl -n velero get pods -o wide
   kubectl -n velero get backupstoragelocation
   kubectl -n velero describe backupstoragelocation default

正常 BackupStorageLocation 应该是：

Phase: Available

如果不是 Available，通常是 MinIO 地址、bucket、AK/SK、证书、网络有问题。

2. 手动备份整个集群资源

这个只备份 Kubernetes 资源，不一定备份 PVC 数据：

cat > /tmp/backup-cluster.yaml <<'EOF'
apiVersion: velero.io/v1
kind: Backup
metadata:
name: cluster-backup-001
namespace: velero
spec:
ttl: 168h0m0s
defaultVolumesToFsBackup: true
EOF

kubectl apply -f /tmp/backup-cluster.yaml

查看：

kubectl -n velero get backup
kubectl -n velero describe backup cluster-backup-001
3. 备份指定 namespace

比如备份 devops：

cat > /tmp/backup-devops.yaml <<'EOF'
apiVersion: velero.io/v1
kind: Backup
metadata:
name: devops-backup-001
namespace: velero
spec:
includedNamespaces:
- devops
ttl: 168h0m0s
defaultVolumesToFsBackup: true
EOF

kubectl apply -f /tmp/backup-devops.yaml

查看：

kubectl -n velero get backup
kubectl -n velero describe backup devops-backup-001
4. 备份多个 namespace

例如备份平台组件：

cat > /tmp/backup-platform.yaml <<'EOF'
apiVersion: velero.io/v1
kind: Backup
metadata:
name: platform-backup-001
namespace: velero
spec:
includedNamespaces:
- devops
- argocd
- monitoring
- logging
- cert-manager
- longhorn-system
ttl: 168h0m0s
defaultVolumesToFsBackup: true
EOF

kubectl apply -f /tmp/backup-platform.yaml
5. 定时备份

比如每天凌晨 3 点备份平台组件：

cat > /tmp/schedule-platform-daily.yaml <<'EOF'
apiVersion: velero.io/v1
kind: Schedule
metadata:
name: platform-daily
namespace: velero
spec:
schedule: "0 3 * * *"
template:
includedNamespaces:
- devops
- argocd
- monitoring
- logging
- cert-manager
- longhorn-system
ttl: 168h0m0s
defaultVolumesToFsBackup: true
EOF

kubectl apply -f /tmp/schedule-platform-daily.yaml

查看：

kubectl -n velero get schedule
kubectl -n velero describe schedule platform-daily
6. 推荐你的定时备份策略

你现在可以先这样：

平台组件：每天备份一次，保留 7 天
业务 namespace：每天备份一次，保留 7~30 天
关键 namespace：每 6 小时备份一次

例如：

platform-daily
prod-daily
prod-critical-6h
7. 还原备份

比如还原 devops-backup-001：

cat > /tmp/restore-devops.yaml <<'EOF'
apiVersion: velero.io/v1
kind: Restore
metadata:
name: restore-devops-001
namespace: velero
spec:
backupName: devops-backup-001
EOF

kubectl apply -f /tmp/restore-devops.yaml

查看：

kubectl -n velero get restore
kubectl -n velero describe restore restore-devops-001
8. 看 MinIO 里有没有备份文件

备份成功后，你的 bucket 里一般会有类似目录：

backups/
restores/
metadata/

例如：

backups/devops-backup-001/
backups/platform-backup-001/
9. 重要提醒

Velero 备份 Longhorn PVC 时，建议给需要备份数据的 Pod/PVC 加：

backup.velero.io/backup-volumes: data

不过你现在用了：

defaultVolumesToFsBackup: true

它会默认尝试备份 Pod 关联的卷，比较省事。

你现在建议先做这个测试：

kubectl -n velero get backupstoragelocation

确认 Available 后，直接创建一个：

kubectl apply -f /tmp/backup-platform.yaml

然后去 MinIO bucket 看 backups/platform-backup-001/ 是否生成。