# TiDB + TiCI on GKE Autopilot (GCP)

本仓库基于 `TiCI on GKE.pdf` 的 YAML，改造成可在 **GCP Autopilot GKE** 上一键部署的版本，并支持 **GCS / MinIO** 两种对象存储模式与镜像可配置。

## 功能概览
- Terraform 创建 **Autopilot GKE** + **GCS Bucket** + **Service Account + HMAC key**
- 一键渲染并部署 TiDB Operator + TiDB/TiKV/TiFlash CN/TiCDC/TiCI Meta/Worker
- 可切换对象存储（GCS 或 MinIO）
- 示例 SQL 独立脚本

## 前置条件
- 已有 GCP 项目，具备创建 GKE/GCS/IAM 权限
- 本机已登录 `gcloud auth login`

## 快速开始

### 1) 配置
复制并修改配置：

```bash
cp config.env.example config.env
```

`REGION` 请填写 GCP 区域。香港对应 `asia-east2`。

### 2) 安装工具（可选）
```bash
./scripts/00-install-tools.sh
```

### 3) 创建 GKE + GCS
```bash
./scripts/10-terraform-apply.sh
```

### 4) 部署集群
```bash
./scripts/20-deploy.sh
```

### 5) 创建 TiCDC changefeed
```bash
./scripts/25-create-changefeed.sh
```

### 6) 执行示例 SQL
```bash
./scripts/30-sample-sql.sh
```

## 存储模式
默认使用 **GCS**，通过 Terraform 创建 bucket + HMAC key，并走 **GCS S3 兼容接口**：
- Endpoint: `https://storage.googleapis.com`
- Access/Secret：自动生成，写入 `.secrets.env`

如需 **MinIO**：
- 在 `config.env` 中设置 `STORAGE_MODE=minio`
- 可指定 `S3_ACCESS_KEY/S3_SECRET_KEY/S3_BUCKET`，不指定会自动生成

## 镜像与版本
默认使用当前 YAML 中的镜像与版本（`gcr.io/pingcap-public/...`）。如需切换镜像源，请在 `config.env` 中覆盖：
- `TIDB_BASE_IMAGE` / `TIDB_VERSION`
- `TIKV_BASE_IMAGE` / `TIKV_VERSION`
- `PD_BASE_IMAGE` / `PD_VERSION`
- `TIKV_WORKER_IMAGE`
- `TIFLASH_IMAGE`
- `TICDC_IMAGE`
- `TICI_IMAGE`
- `TIDB_OPERATOR_IMAGE` / `TIDB_DISCOVERY_IMAGE`

若使用私有镜像仓库，请自行创建 `imagePullSecret` 并按需 patch 到相关 workload。

## 清理资源
```bash
./scripts/40-destroy.sh
```

## 文件说明
- `terraform/`: GKE Autopilot + GCS + SA/HMAC
- `manifests/templates/`: 模板化 YAML
- `manifests/rendered/`: 渲染输出（已 gitignore）
- `scripts/`: 一键脚本
- `docs/`: 原始 PDF 参考

