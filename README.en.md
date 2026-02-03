# TiCI on GKE Autopilot

## Main Commands
```bash
cp config.env.example config.env
./scripts/00-install-tools.sh
./scripts/10-terraform-apply.sh
./scripts/20-deploy.sh
./scripts/25-create-changefeed.sh
./scripts/30-sample-sql.sh
./scripts/40-destroy.sh
CONFIRM_DESTROY=yes ./scripts/45-shutdown-all.sh
```

Common troubleshooting commands are in `COMMON_COMMANDS.md`.
