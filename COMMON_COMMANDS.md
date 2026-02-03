# 常用命令

## Pod
```bash
kubectl get pods -n tidb-fts
kubectl get pods -n tidb-fts | egrep "tiflash-cn|tici-meta|tici-worker"
```

## 日志
```bash
kubectl logs -n tidb-fts <pod>
kubectl logs -n tidb-fts <pod> -f
kubectl logs -n tidb-fts <pod> --previous
kubectl logs -n tidb-fts <pod> --since=10m
```

## 配置
```bash
kubectl get cm -n tidb-fts | egrep "tici-meta|tici-worker|tiflash-cn"
kubectl get cm -n tidb-fts tici-meta-config -o yaml
kubectl get cm -n tidb-fts tici-worker-config -o yaml
kubectl get cm -n tidb-fts tiflash-cn-config -o yaml
kubectl describe pod -n tidb-fts <pod>
kubectl exec -n tidb-fts <pod> -- cat /etc/tici-meta/config.toml
```

## MySQL 连接与查询
```bash
kubectl exec -n tidb-fts -it mysql-client-0 -- sh -c "mysql -h tidb-tidb.tidb-fts.svc -P 4000 -u root"
kubectl exec -n tidb-fts mysql-client-0 -- sh -c "mysql -h tidb-tidb.tidb-fts.svc -P 4000 -u root -e 'SHOW DATABASES;'"
```

## 事件
```bash
kubectl get events -n tidb-fts --sort-by=.lastTimestamp | tail -n 30
```
