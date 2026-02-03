# TiCI on GKE Autopilot

## Main Commands
Copy and edit config:
```bash
cp config.env.example config.env
```

Change replicas per service (edit `config.env`, then redeploy):
- `PD_REPLICAS`, `TIDB_REPLICAS`, `TIDB_WORKER_REPLICAS`, `TIKV_REPLICAS`, `TIKV_WORKER_REPLICAS`
- `TIFLASH_CN_REPLICAS`, `TICDC_REPLICAS`, `TICI_META_REPLICAS`, `TICI_WORKER_REPLICAS`, `MINIO_REPLICAS`

Install tools (optional):
```bash
./scripts/00-install-tools.sh
```

Create GKE + GCS (Terraform):
```bash
./scripts/10-terraform-apply.sh
```

Deploy TiDB + TiCI components:
```bash
./scripts/20-deploy.sh
```

Create TiCDC changefeed:
```bash
./scripts/25-create-changefeed.sh
```

Run sample SQL:
```bash
./scripts/30-sample-sql.sh
```

Destroy resources (Terraform):
```bash
./scripts/40-destroy.sh
```

Full cleanup (GKE/GCS/SA/HMAC):
```bash
CONFIRM_DESTROY=yes ./scripts/45-shutdown-all.sh
```

Common troubleshooting commands are in `COMMON_COMMANDS.md`.
