# Common Commands

## Pods
Get all pods in the namespace:
```bash
kubectl get pods -n tidb-fts
```

Filter key TiCI components:
```bash
kubectl get pods -n tidb-fts | egrep "tiflash-cn|tici-meta|tici-worker"
```

## Logs
Show logs for a pod:
```bash
kubectl logs -n tidb-fts <pod>
```

Follow logs (tail -f):
```bash
kubectl logs -n tidb-fts <pod> -f
```

Show previous crash logs:
```bash
kubectl logs -n tidb-fts <pod> --previous
```

Show recent logs only:
```bash
kubectl logs -n tidb-fts <pod> --since=10m
```

Follow TiCI reader logs (tiflash container):
```bash
kubectl logs -n tidb-fts tiflash-cn-0 -c tiflash -f
```

Follow TiCI reader logs (ticilog container, if present):
```bash
kubectl logs -n tidb-fts tiflash-cn-0 -c ticilog -f
```

List container names in a pod:
```bash
kubectl get pod -n tidb-fts tiflash-cn-0 -o jsonpath='{.spec.containers[*].name}{"\n"}'
```

## Config
List configmaps:
```bash
kubectl get cm -n tidb-fts | egrep "tici-meta|tici-worker|tiflash-cn"
```

Show tici-meta config:
```bash
kubectl get cm -n tidb-fts tici-meta-config -o yaml
```

Show tici-worker config:
```bash
kubectl get cm -n tidb-fts tici-worker-config -o yaml
```

Show tiflash-cn config:
```bash
kubectl get cm -n tidb-fts tiflash-cn-config -o yaml
```

Describe a pod:
```bash
kubectl describe pod -n tidb-fts <pod>
```

Read config file inside a pod:
```bash
kubectl exec -n tidb-fts <pod> -- cat /etc/tici-meta/config.toml
```

## MySQL
Open an interactive MySQL session:
```bash
kubectl exec -n tidb-fts -it mysql-client-0 -- sh -c "mysql -h tidb-tidb.tidb-fts.svc -P 4000 -u root"
```

Run a one-off query:
```bash
kubectl exec -n tidb-fts mysql-client-0 -- sh -c "mysql -h tidb-tidb.tidb-fts.svc -P 4000 -u root -e 'SHOW DATABASES;'"
```

## Events
Show recent events:
```bash
kubectl get events -n tidb-fts --sort-by=.lastTimestamp | tail -n 30
```
