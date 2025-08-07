#!/bin/bash

# -----------------------------------------------------------------------------
#
# AWS ECS Fargate 本番環境用
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


# -----------------------------------------------------------------------------
# 環境変数が空ではないかバリデーションする
#


log "環境変数を検証します..."


# 必須の環境変数リスト
required_vars=(
    "EFS_APPLICATION_MOUNT_PATH"
    "EPHEMERAL_STORAGE_TMP_PATH"
    "DOMAIN_NAME"
    "ADMIN_EMAIL"
    "DOCUMENT_ROOT_PATH"
    "HTTPD_LOG_LEVEL"
    "APP_DIRECTORY_PATH"
    "APP_ENV_PATH"
    "APP_NAME"
    "APP_URL"
    "APP_DEBUG"
    "APP_ENV"
    "APP_LOG_LEVEL"
    "DB_CONNECTION"
    "DB_HOST"
    "DB_PORT"
    "DB_DATABASE"
    "DB_USERNAME"
    "DB_PASSWORD"
    "MAIL_MAILER"
    "MAIL_HOST"
    "MAIL_PORT"
    "MAIL_USERNAME"
    "MAIL_PASSWORD"
    "MAIL_ENCRYPTION"
    "MAIL_FROM_ADDRESS"
    "MAIL_FROM_NAME"
    "AWS_ACCESS_KEY_ID"
    "AWS_SECRET_ACCESS_KEY"
    "AWS_DEFAULT_REGION"
    "SQS_DEFAULT_QUEUE"
    "SQS_EMAIL_QUEUE"
    "SQS_NOTIFICATION_QUEUE"
    "SQS_REPORT_QUEUE"
    "SQS_FILE_PROCESSING_QUEUE"
    "SQS_BATCH_QUEUE"
)


# 環境変数のチェック
for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        error "必要な環境変数 $var が設定されていません"
        exit 1
    fi
done


log "環境変数の検証が正常に完了しました。"


# -----------------------------------------------------------------------------
# Laravelの.envファイルの作成
#


echo "Laravelの .env ファイルを作成します。"

# ディレクトリの存在確認とアクセス確認
if [ ! -d "${APP_DIRECTORY_PATH}" ]; then
    error "${APP_DIRECTORY_PATH} ディレクトリが見つかりません。"
    exit 1
fi

if [ ! -d "${APP_ENV_PATH}" ]; then
    error "${APP_ENV_PATH} ディレクトリが見つかりません。"
    exit 1
fi

if [ ! -w "${APP_ENV_PATH}" ]; then
    error "${APP_ENV_PATH} ディレクトリに書き込み権限がありません。"
    exit 1
fi

cd ${APP_ENV_PATH}

# 既存の .env ファイルが存在する場合は削除する
if [ -f ".env" ]; then
    log "既存の .env ファイルを削除しています..."
    rm -f .env
fi

# .env.example から .env を作成する
if [ ! -f "${APP_DIRECTORY_PATH}/_.env.example" ]; then
    error "${APP_DIRECTORY_PATH}/_.env.example が見つかりません。"
    exit 1
else
    cp ${APP_DIRECTORY_PATH}/_.env.example ${APP_ENV_PATH}/.env
    log "${APP_ENV_PATH}/.env ファイルを作成しました。"
fi

if [ -f "${APP_ENV_PATH}/.env" ]; then
    # Httpd設定
    sed -i "s|DOMAIN_NAME=|DOMAIN_NAME=$DOMAIN_NAME|" ${APP_ENV_PATH}/.env
    sed -i "s|ADMIN_EMAIL=|ADMIN_EMAIL=$ADMIN_EMAIL|" ${APP_ENV_PATH}/.env
    sed -i "s|DOCUMENT_ROOT_PATH=|DOCUMENT_ROOT_PATH=$DOCUMENT_ROOT_PATH|" ${APP_ENV_PATH}/.env
    sed -i "s|HTTPD_LOG_LEVEL=|HTTPD_LOG_LEVEL=$HTTPD_LOG_LEVEL|" ${APP_ENV_PATH}/.env

    # EFS設定
    sed -i "s|EFS_APPLICATION_MOUNT_PATH=|EFS_APPLICATION_MOUNT_PATH=$EFS_APPLICATION_MOUNT_PATH|" ${APP_ENV_PATH}/.env

    # アプリケーション設定
    sed -i "s|APP_NAME=|APP_NAME=$APP_NAME|" ${APP_ENV_PATH}/.env
    sed -i "s|APP_URL=|APP_URL=$APP_URL|" ${APP_ENV_PATH}/.env
    sed -i "s|APP_DIRECTORY_PATH=|APP_DIRECTORY_PATH=$APP_DIRECTORY_PATH|" ${APP_ENV_PATH}/.env
    sed -i "s|APP_DEBUG=|APP_DEBUG=$APP_DEBUG|" ${APP_ENV_PATH}/.env
    sed -i "s|APP_ENV=|APP_ENV=$APP_ENV|" ${APP_ENV_PATH}/.env
    # sed -i "s|APP_LOG_CHANNEL=|APP_LOG_CHANNEL=$APP_LOG_CHANNEL|" ${APP_ENV_PATH}/.env
    sed -i "s|APP_LOG_LEVEL=|APP_LOG_LEVEL=$APP_LOG_LEVEL|" ${APP_ENV_PATH}/.env

    # データベース設定
    sed -i "s|DB_CONNECTION=|DB_CONNECTION=$DB_CONNECTION|" ${APP_ENV_PATH}/.env
    sed -i "s|DB_HOST=|DB_HOST=$DB_HOST|" ${APP_ENV_PATH}/.env
    sed -i "s|DB_PORT=|DB_PORT=$DB_PORT|" ${APP_ENV_PATH}/.env
    sed -i "s|DB_DATABASE=|DB_DATABASE=$DB_DATABASE|" ${APP_ENV_PATH}/.env
    sed -i "s|DB_USERNAME=|DB_USERNAME=$DB_USERNAME|" ${APP_ENV_PATH}/.env
    sed -i "s|DB_PASSWORD=|DB_PASSWORD=$DB_PASSWORD|" ${APP_ENV_PATH}/.env

    # メール設定
    sed -i "s|MAIL_MAILER=|MAIL_MAILER=$MAIL_MAILER|" ${APP_ENV_PATH}/.env
    sed -i "s|MAIL_HOST=|MAIL_HOST=$MAIL_HOST|" ${APP_ENV_PATH}/.env
    sed -i "s|MAIL_PORT=|MAIL_PORT=$MAIL_PORT|" ${APP_ENV_PATH}/.env
    sed -i "s|MAIL_USERNAME=|MAIL_USERNAME=$MAIL_USERNAME|" ${APP_ENV_PATH}/.env
    sed -i "s|MAIL_PASSWORD=|MAIL_PASSWORD=$MAIL_PASSWORD|" ${APP_ENV_PATH}/.env
    sed -i "s|MAIL_ENCRYPTION=|MAIL_ENCRYPTION=$MAIL_ENCRYPTION|" ${APP_ENV_PATH}/.env
    sed -i "s|MAIL_FROM_ADDRESS=|MAIL_FROM_ADDRESS=$MAIL_FROM_ADDRESS|" ${APP_ENV_PATH}/.env
    sed -i "s|MAIL_FROM_NAME=|MAIL_FROM_NAME=$MAIL_FROM_NAME|" ${APP_ENV_PATH}/.env

    # AWS設定
    sed -i "s|AWS_ACCESS_KEY_ID=|AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID|" ${APP_ENV_PATH}/.env
    sed -i "s|AWS_SECRET_ACCESS_KEY=|AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY|" ${APP_ENV_PATH}/.env
    sed -i "s|AWS_DEFAULT_REGION=|AWS_DEFAULT_REGION=$AWS_DEFAULT_REGION|" ${APP_ENV_PATH}/.env

    # Amazon SQS 設定
    sed -i "s|SQS_DEFAULT_QUEUE=|SQS_DEFAULT_QUEUE=$SQS_DEFAULT_QUEUE|" ${APP_ENV_PATH}/.env
    sed -i "s|SQS_EMAIL_QUEUE=|SQS_EMAIL_QUEUE=$SQS_EMAIL_QUEUE|" ${APP_ENV_PATH}/.env
    sed -i "s|SQS_NOTIFICATION_QUEUE=|SQS_NOTIFICATION_QUEUE=$SQS_NOTIFICATION_QUEUE|" ${APP_ENV_PATH}/.env
    sed -i "s|SQS_REPORT_QUEUE=|SQS_REPORT_QUEUE=$SQS_REPORT_QUEUE|" ${APP_ENV_PATH}/.env
    sed -i "s|SQS_FILE_PROCESSING_QUEUE=|SQS_FILE_PROCESSING_QUEUE=$SQS_FILE_PROCESSING_QUEUE|" ${APP_ENV_PATH}/.env
    sed -i "s|SQS_BATCH_QUEUE=|SQS_BATCH_QUEUE=$SQS_BATCH_QUEUE|" ${APP_ENV_PATH}/.env

    # Laravel APP_KEY の設定
    if [ -z "${LARAVEL_APP_KEY}" ]; then
        # 指定がない場合は新規生成
        log "Secrets Manager に APP_KEY が見つからないため、新しいキーを生成しています..."
        if ! php artisan key:generate --force; then
            error "アプリケーションキーの生成に失敗しました。"
            exit 1
        fi
        log "新しいアプリケーションキーが正常に生成されました。"
    else
        sed -i "s|APP_KEY=|APP_KEY=$LARAVEL_APP_KEY|" ${APP_ENV_PATH}/.env
    fi

    log "Laravel .env ファイルの作成が正常に完了しました。"
fi


# -----------------------------------------------------------------------------
# 起動
#


# crondの起動（権限エラー対応）
# manage_service_with_fallback "start" "/usr/sbin/crond" "crond"

if [ "${WORKER_MODE}" = "true" ]; then
    log "Worker を起動しています..."

    # pyenvのパスを通す
    if [ -f "/etc/profile.d/pyenv.sh" ]; then
        source /etc/profile.d/pyenv.sh
        log "✅ pyenv環境がロードされました。"
        log "🔍 Python のパス: $(which python3)"
        log "🔍 Supervisor のパス: $(which supervisord)"
    else
        log "⚠️ pyenv.sh が見つからないため、スキップします..."
    fi

    # 既存のsupervisordプロセスとファイルをクリーンアップ
    log "🧹 既存の Supervisord プロセスとファイルをクリーンアップしています..."
    pkill -f supervisord 2>/dev/null || true
    rm -f ${EPHEMERAL_STORAGE_TMP_PATH}/run/supervisor/supervisor*.sock ${EPHEMERAL_STORAGE_TMP_PATH}/run/supervisor/supervisord-*.pid 2>/dev/null || true
    sleep 1

    # supervisordの起動（権限エラー対応）
    log "🚀 supervisord を起動しています..."
    supervisord -c ${EPHEMERAL_STORAGE_TMP_PATH}/supervisord/supervisord.conf

    # コンテナを終了しないようにする
    log "✅ ワーカー モードが初期化され、コンテナーが稼働し続けています..."
    tail -f /dev/null
else
    # httpdの起動（権限エラー対応）
    log "🌐 Web サーバを開始しています... ${DOMAIN_NAME}"
    /usr/sbin/httpd -f ${EPHEMERAL_STORAGE_TMP_PATH}/httpd/conf/httpd.conf -D FOREGROUND
fi
