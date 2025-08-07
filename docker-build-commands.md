# Docker Compose ビルドコマンド集

## 🚀 基本的なビルドオプション

### 1. 通常のビルド付き起動
```bash
COMPOSE_DOCKER_CLI_BUILD=1 docker compose -f docker-compose.dev.yml up -d --build
```

### 2. キャッシュを使わない完全ビルド
```bash
COMPOSE_DOCKER_CLI_BUILD=1 docker compose -f docker-compose.dev.yml build --no-cache
COMPOSE_DOCKER_CLI_BUILD=1 docker compose -f docker-compose.dev.yml up -d
```

### 3. 特定のサービスのみビルド
```bash
COMPOSE_DOCKER_CLI_BUILD=1 docker compose -f docker-compose.dev.yml build --no-cache app
COMPOSE_DOCKER_CLI_BUILD=1 docker compose -f docker-compose.dev.yml up -d app
```

## 🧹 トラブルシューティング用完全クリーンアップ

### ステップ1: 既存環境のクリーンアップ
```bash
# コンテナ停止・削除
docker compose -f docker-compose.dev.yml down

# 不要なコンテナ・イメージ・ネットワーク削除
docker system prune -af

# ボリュームも削除する場合（注意：データが消失します）
docker system prune -af --volumes
```

### ステップ2: 完全ビルド
```bash
# BuildKitを有効にして完全ビルド
export COMPOSE_DOCKER_CLI_BUILD=1
export DOCKER_BUILDKIT=1

docker compose -f docker-compose.dev.yml build --no-cache --parallel
```

### ステップ3: サービス起動
```bash
docker compose -f docker-compose.dev.yml up -d
```

## 🔄 開発時に便利なコマンド

### アプリケーションコンテナのみ再ビルド
```bash
COMPOSE_DOCKER_CLI_BUILD=1 docker compose -f docker-compose.dev.yml build --no-cache app worker
COMPOSE_DOCKER_CLI_BUILD=1 docker compose -f docker-compose.dev.yml up -d app worker
```

### データベースはそのままでアプリのみ再起動
```bash
COMPOSE_DOCKER_CLI_BUILD=1 docker compose -f docker-compose.dev.yml up -d --build --no-deps app worker
```

## 📋 よく使うオプションの説明

| オプション | 説明 |
|-----------|------|
| `--build` | イメージを強制的にビルドしてから起動 |
| `--no-cache` | DockerイメージビルドでキャッシュLayersを使用しない |
| `--force-recreate` | 設定が変更されていなくてもコンテナを再作成 |
| `--no-deps` | リンクされたサービスを起動しない |
| `--parallel` | 並列でビルドを実行（高速化） |
| `--pull` | ベースイメージを最新版に更新してからビルド |

## 🎯 マルチステージビルド特有の注意点

### BuildKitを確実に有効化
```bash
# 環境変数で設定
export COMPOSE_DOCKER_CLI_BUILD=1
export DOCKER_BUILDKIT=1

# または、コマンドの前に直接指定
COMPOSE_DOCKER_CLI_BUILD=1 DOCKER_BUILDKIT=1 docker compose -f docker-compose.dev.yml up -d --build
```

### ターゲットステージの指定（必要に応じて）
Docker Compose ファイルでbuildセクションに以下を追加：
```yaml
services:
  app:
    build:
      context: .
      dockerfile: ./Dockerfile.app.1.0
      target: dev_app  # マルチステージの特定ステージを指定
```

## ⚡ パフォーマンス向上のコツ

### 1. 並列ビルドを活用
```bash
COMPOSE_DOCKER_CLI_BUILD=1 docker compose -f docker-compose.dev.yml build --parallel
```

### 2. .dockerignoreでビルドコンテキストを最適化
```bash
# .dockerignore に不要なファイルを追加
node_modules
.git
*.log
```

### 3. マルチステージビルドでのキャッシュ最適化
Dockerfileで`RUN --mount=type=cache`を活用 