#!/bin/bash

# -----------------------------------------------------------------------------
#
# AWS ECS Fargate 本番環境用 log-router
# エントリーポイントスクリプト
#
# -----------------------------------------------------------------------------


set -euxo pipefail


# ログ出力関数
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] $1"
}

error() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [ERROR] $1" >&2
}


# 現在のユーザーIDとグループIDを表示
log "🧍🏻‍♂️ Current user ID: $(id -u)"
log "🧍🏻‍♂️ Current group ID: $(id -g)"
log "🧍🏻‍♂️ Current user: $(whoami)"
log "🧍🏻‍♂️ Current groups: $(groups)"


echo "Starting Fluent Bit container initialization..."

# 必須環境変数のチェック
required_vars=(
    "EFS_APPLICATION_MOUNT_PATH"
    "USER_ID"
    "GROUP_ID"
    "FLUENT_BIT_LOG_LEVEL"
    "REGION"
    "CLOUDWATCH_LOG_GROUP_ID"
    "FIREHOSE_HTTPD_STREAM_ID"
    "FIREHOSE_APP_STREAM_ID"
)

for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        echo "Error: Required environment variable $var is not set"
        exit 1
    fi
done

# ディレクトリの存在確認
directories=(
    "/fluent-bit/log"
    "${EFS_APPLICATION_MOUNT_PATH}"
)

for dir in "${directories[@]}"; do
    if [ ! -d "$dir" ]; then
        echo "Error: Required directory $dir does not exist"
        exit 1
    fi

    if [ ! -w "$dir" ]; then
        echo "Error: Directory $dir is not writable by fluent user"
        exit 1
    fi
done

# 設定ファイルの存在確認
config_files=(
    "/fluent-bit/etc/custom_parsers.conf"
    "/fluent-bit/etc/extra.conf"
    "/fluent-bit/conf/script.lua"
)

for file in "${config_files[@]}"; do
    if [ ! -f "$file" ]; then
        echo "Error: Required configuration file $file does not exist"
        exit 1
    fi

    if [ ! -r "$file" ]; then
        echo "Error: Configuration file $file is not readable by fluent user"
        exit 1
    fi
done

# 設定ファイルの検証
echo "Validating Fluent Bit configuration..."
if ! /fluent-bit/bin/fluent-bit -c /fluent-bit/etc/extra.conf --dry-run; then
    echo "Error: Invalid Fluent Bit configuration"
    exit 1
fi

echo "Starting Fluent Bit..."
exec /fluent-bit/bin/fluent-bit \
    -c /fluent-bit/etc/extra.conf \
    -l "${FLUENT_BIT_LOG_LEVEL:-info}" \
    -v

# exec sleep infinity