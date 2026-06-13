# MySQL HA

MySQL 不建议用普通 StatefulSet 加 `replicas: 3` 来伪装高可用。复制、故障转移、备份、主从切换都需要数据库层控制。

本目录提供 MySQL Operator 的 `InnoDBCluster` CR 示例。使用前需要先安装 MySQL Operator，并确认 CRD `innodbclusters.mysql.oracle.com` 已存在。

当前 MySQL Server 版本固定为 `8.0.37`，通过 `spec.version` 指定。

## 部署

```bash
kubectl get crd innodbclusters.mysql.oracle.com
kubectl apply -f middleware/distributed-architecture/prod/mysql/mysql-innodbcluster.yaml
```

## 验证

```bash
kubectl -n prod-distributed get innodbcluster
kubectl -n prod-distributed get pod -l mysql.oracle.com/cluster=mysql
```
