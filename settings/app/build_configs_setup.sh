#!/bin/bash

# -----------------------------------------------------------------------------
#
# 初期化コンテナ
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




log "🤖🤖🤖 初期化を開始します..."


# 現在のユーザーIDとグループIDを表示
log "🧍🏻‍♂️ Current user ID: $(id -u)"
log "🧍🏻‍♂️ Current group ID: $(id -g)"
log "🧍🏻‍♂️ Current user: $(whoami)"
log "🧍🏻‍♂️ Current groups: $(groups)"




# -----------------------------------------------------------------------------
# 環境変数が空ではないかバリデーションする
#


log "➡️ 環境変数を検証します..."


# 必須の環境変数リスト
required_vars=(
    "EFS_APPLICATION_MOUNT_PATH"
    "EPHEMERAL_STORAGE_TMP_PATH"
    "INIT_SETTINGS_PATH"
    "DOCUMENT_ROOT_PATH"
    "APP_DIRECTORY_PATH"
    "DOMAIN_NAME"
    "ADMIN_EMAIL"
    "HTTPD_LOG_LEVEL"
)

# 環境変数のチェック
for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        error "❌ 必要な環境変数 $var が設定されていません。"
        exit 1
    fi
done


log "✅ 環境検証が正常に完了しました。"




# -----------------------------------------------------------------------------
# エフェメラルストレージの初期化
#
# 実行コンテナは非権限ユーザなので、事前にエフェメラルストレージを初期化しておく


log "➡️ エフェメラルストレージを初期化します..."


#
# エフェメラルストレージのマウントポイントの確認
#


log "➡️ エフェメラルストレージのマウントポイントを確認します..."


if [ ! -d "${EPHEMERAL_STORAGE_TMP_PATH}" ]; then
    error "❌ ディレクトリ ${EPHEMERAL_STORAGE_TMP_PATH} が見つかりません。"
    exit 1
fi
log "✅ ディレクトリ ${EPHEMERAL_STORAGE_TMP_PATH} が見つかりました。"


#
# 初期設定ファイルをコピーする
#
# このディレクトリに配置するファイルは、運用環境ごとの設定ファイルです。
# 実行コンテナ起動時に、運用環境に合わせた設定ファイルを、設定ディレクトリにコピーします。


log "➡️ 初期設定ファイルのディレクトリを作成します..."


if ! mkdir -p ${EPHEMERAL_STORAGE_TMP_PATH}/init_setting_files; then
    error "❌ ${EPHEMERAL_STORAGE_TMP_PATH}/init_setting_files ディレクトリの作成に失敗しました。"
    exit 1
fi
log "✅ ${EPHEMERAL_STORAGE_TMP_PATH}/init_setting_files ディレクトリを作成しました。"


if ! mkdir -p ${EPHEMERAL_STORAGE_TMP_PATH}/init_setting_files/httpd/conf; then
    error "❌ ${EPHEMERAL_STORAGE_TMP_PATH}/init_setting_files/httpd/conf ディレクトリの作成に失敗しました。"
    exit 1
fi
log "✅ ${EPHEMERAL_STORAGE_TMP_PATH}/init_setting_files/httpd/conf ディレクトリを作成しました。"


if ! mkdir -p ${EPHEMERAL_STORAGE_TMP_PATH}/init_setting_files/httpd/conf.d; then
    error "❌ ${EPHEMERAL_STORAGE_TMP_PATH}/init_setting_files/httpd/conf.d ディレクトリの作成に失敗しました。"
    exit 1
fi
log "✅ ${EPHEMERAL_STORAGE_TMP_PATH}/init_setting_files/httpd/conf.d ディレクトリを作成しました。"


if ! mkdir -p ${EPHEMERAL_STORAGE_TMP_PATH}/init_setting_files/supervisord; then
    error "❌ ${EPHEMERAL_STORAGE_TMP_PATH}/init_setting_files/supervisord ディレクトリの作成に失敗しました。"
    exit 1
fi
log "✅ ${EPHEMERAL_STORAGE_TMP_PATH}/init_setting_files/supervisord ディレクトリを作成しました。"


if ! mkdir -p ${EPHEMERAL_STORAGE_TMP_PATH}/init_setting_files/supervisord/supervisord.d; then
    error "❌ ${EPHEMERAL_STORAGE_TMP_PATH}/init_setting_files/supervisord/supervisord.d ディレクトリの作成に失敗しました。"
    exit 1
fi
log "✅ ${EPHEMERAL_STORAGE_TMP_PATH}/init_setting_files/supervisord/supervisord.d ディレクトリを作成しました。"


log "✅ 初期設定ファイルのディレクトリの作成が完了しました。"


#
#
# 初期設定ファイルをコピーする
#


log "➡️ 初期設定ファイルをコピーします..."


# - httpd


if [ -f "${INIT_SETTINGS_PATH}/httpd/conf/httpd.prod.conf" ]; then
    if ! cp -f ${INIT_SETTINGS_PATH}/httpd/conf/httpd.prod.conf ${EPHEMERAL_STORAGE_TMP_PATH}/init_setting_files/httpd/conf/httpd.prod.conf; then
        error "❌ ${EPHEMERAL_STORAGE_TMP_PATH}/init_setting_files/httpd/conf/httpd.prod.conf ファイルのコピーに失敗しました。"
        exit 1
    fi
    log "✅ ${EPHEMERAL_STORAGE_TMP_PATH}/init_setting_files/httpd/conf/httpd.prod.conf ファイルをコピーしました。"
else
    error "❌ ${INIT_SETTINGS_PATH}/httpd/conf/httpd.prod.conf ファイルが見つかりません。"
    exit 1
fi


if [ -f "${INIT_SETTINGS_PATH}/httpd/conf/httpd.dev.conf" ]; then
    if ! cp -f ${INIT_SETTINGS_PATH}/httpd/conf/httpd.dev.conf ${EPHEMERAL_STORAGE_TMP_PATH}/init_setting_files/httpd/conf/httpd.dev.conf; then
        error "❌ ${EPHEMERAL_STORAGE_TMP_PATH}/init_setting_files/httpd/conf/httpd.dev.conf ファイルのコピーに失敗しました。"
        exit 1
    fi
    log "✅ ${EPHEMERAL_STORAGE_TMP_PATH}/init_setting_files/httpd/conf/httpd.dev.conf ファイルをコピーしました。"
else
    error "❌ ${INIT_SETTINGS_PATH}/httpd/conf/httpd.dev.conf ファイルが見つかりません。"
    exit 1
fi


if [ -f "${INIT_SETTINGS_PATH}/httpd/conf/httpd.xserver_vps.conf" ]; then
    if ! cp -f ${INIT_SETTINGS_PATH}/httpd/conf/httpd.xserver_vps.conf ${EPHEMERAL_STORAGE_TMP_PATH}/init_setting_files/httpd/conf/httpd.xserver_vps.conf; then
        error "❌ ${EPHEMERAL_STORAGE_TMP_PATH}/init_setting_files/httpd/conf/httpd.xserver_vps.conf ファイルのコピーに失敗しました。"
        exit 1
    fi
    log "✅ ${EPHEMERAL_STORAGE_TMP_PATH}/init_setting_files/httpd/conf/httpd.xserver_vps.conf ファイルをコピーしました。"
else
    error "❌ ${INIT_SETTINGS_PATH}/httpd/conf/httpd.xserver_vps.conf ファイルが見つかりません。"
    exit 1
fi


if [ -f "${INIT_SETTINGS_PATH}/httpd/conf.d/app.prod.conf" ]; then
    if ! cp -f ${INIT_SETTINGS_PATH}/httpd/conf.d/app.prod.conf ${EPHEMERAL_STORAGE_TMP_PATH}/init_setting_files/httpd/conf.d/app.prod.conf; then
        error "❌ ${EPHEMERAL_STORAGE_TMP_PATH}/init_setting_files/httpd/conf.d/app.prod.conf ファイルのコピーに失敗しました。"
        exit 1
    fi
    log "✅ ${EPHEMERAL_STORAGE_TMP_PATH}/init_setting_files/httpd/conf.d/app.prod.conf ファイルをコピーしました。"
else
    error "❌ ${INIT_SETTINGS_PATH}/httpd/conf.d/app.prod.conf ファイルが見つかりません。"
    exit 1
fi


if [ -f "${INIT_SETTINGS_PATH}/httpd/conf.d/app.dev.conf" ]; then
    if ! cp -f ${INIT_SETTINGS_PATH}/httpd/conf.d/app.dev.conf ${EPHEMERAL_STORAGE_TMP_PATH}/init_setting_files/httpd/conf.d/app.dev.conf; then
        error "❌ ${EPHEMERAL_STORAGE_TMP_PATH}/init_setting_files/httpd/conf.d/app.dev.conf ファイルのコピーに失敗しました。"
        exit 1
    fi
    log "✅ ${EPHEMERAL_STORAGE_TMP_PATH}/init_setting_files/httpd/conf.d/app.dev.conf ファイルをコピーしました。"
else
    error "❌ ${INIT_SETTINGS_PATH}/httpd/conf.d/app.dev.conf ファイルが見つかりません。"
    exit 1
fi


if [ -f "${INIT_SETTINGS_PATH}/httpd/conf.d/app.xserver_vps.conf" ]; then
    if ! cp -f ${INIT_SETTINGS_PATH}/httpd/conf.d/app.xserver_vps.conf ${EPHEMERAL_STORAGE_TMP_PATH}/init_setting_files/httpd/conf.d/app.xserver_vps.conf; then
        error "❌ ${EPHEMERAL_STORAGE_TMP_PATH}/init_setting_files/httpd/conf.d/app.xserver_vps.conf ファイルのコピーに失敗しました。"
        exit 1
    fi
    log "✅ ${EPHEMERAL_STORAGE_TMP_PATH}/init_setting_files/httpd/conf.d/app.xserver_vps.conf ファイルをコピーしました。"
else
    error "❌ ${INIT_SETTINGS_PATH}/httpd/conf.d/app.xserver_vps.conf ファイルが見つかりません。"
    exit 1
fi


# - supervisord


if [ -f "${INIT_SETTINGS_PATH}/supervisord/supervisord.conf" ]; then
    if ! cp -f ${INIT_SETTINGS_PATH}/supervisord/supervisord.conf ${EPHEMERAL_STORAGE_TMP_PATH}/init_setting_files/supervisord/supervisord.conf; then
        error "❌ ${EPHEMERAL_STORAGE_TMP_PATH}/init_setting_files/supervisord/supervisord.conf ファイルのコピーに失敗しました。"
        exit 1
    fi
    log "✅ ${EPHEMERAL_STORAGE_TMP_PATH}/init_setting_files/supervisord/supervisord.conf ファイルをコピーしました。"
else
    error "❌ ${INIT_SETTINGS_PATH}/supervisord/supervisord.conf ファイルが見つかりません。"
    exit 1
fi


if [ -f "${INIT_SETTINGS_PATH}/supervisord/supervisord.d/laravel-worker.ini" ]; then
    if ! cp -f ${INIT_SETTINGS_PATH}/supervisord/supervisord.d/laravel-worker.ini ${EPHEMERAL_STORAGE_TMP_PATH}/init_setting_files/supervisord/supervisord.d/laravel-worker.ini; then
        error "❌ ${EPHEMERAL_STORAGE_TMP_PATH}/init_setting_files/supervisord/supervisord.d/laravel-worker.ini ファイルのコピーに失敗しました。"
        exit 1
    fi
    log "✅ ${EPHEMERAL_STORAGE_TMP_PATH}/init_setting_files/supervisord/supervisord.d/laravel-worker.ini ファイルをコピーしました。"
else
    error "❌ ${INIT_SETTINGS_PATH}/supervisord/supervisord.d/laravel-worker.ini ファイルが見つかりません。"
    exit 1
fi


log "✅ 初期設定ファイルのコピーが完了しました。"


#
# 設定ファイルを配置するディレクトリを作成する
#
# 実行コンテナ起動時に、運用環境に合わせた設定ファイルを初期設定ファイルのディレクトリから、このディレクトリへコピーします。


log "➡️ 設定ファイルのディレクトリを作成します ..."


#
# 設定ファイルを配置するディレクトリを作成する
#


if ! mkdir -p ${EPHEMERAL_STORAGE_TMP_PATH}/httpd/conf; then
    error "❌ ${EPHEMERAL_STORAGE_TMP_PATH}/httpd/conf ディレクトリの作成に失敗しました。"
    exit 1
fi
log "✅ ${EPHEMERAL_STORAGE_TMP_PATH}/httpd/conf ディレクトリを作成しました。"


if ! mkdir -p ${EPHEMERAL_STORAGE_TMP_PATH}/httpd/conf.d; then
    error "❌ ${EPHEMERAL_STORAGE_TMP_PATH}/httpd/conf.d ディレクトリの作成に失敗しました。"
    exit 1
fi
log "✅ ${EPHEMERAL_STORAGE_TMP_PATH}/httpd/conf.d ディレクトリを作成しました。"


if ! mkdir -p ${EPHEMERAL_STORAGE_TMP_PATH}/httpd/extra; then
    error "❌ ${EPHEMERAL_STORAGE_TMP_PATH}/httpd/extra ディレクトリの作成に失敗しました。"
    exit 1
fi
log "✅ ${EPHEMERAL_STORAGE_TMP_PATH}/httpd/extra ディレクトリを作成しました。"


if ! mkdir -p ${EPHEMERAL_STORAGE_TMP_PATH}/run/httpd; then
    error "❌ ${EPHEMERAL_STORAGE_TMP_PATH}/run/httpd ディレクトリの作成に失敗しました。"
    exit 1
fi
log "✅ ${EPHEMERAL_STORAGE_TMP_PATH}/run/httpd ディレクトリを作成しました。"


if ! mkdir -p ${EPHEMERAL_STORAGE_TMP_PATH}/run/php-fpm; then
    error "❌ ${EPHEMERAL_STORAGE_TMP_PATH}/run/php-fpm ディレクトリの作成に失敗しました。"
    exit 1
fi
log "✅ ${EPHEMERAL_STORAGE_TMP_PATH}/run/php-fpm ディレクトリを作成しました。"


if ! mkdir -p ${EPHEMERAL_STORAGE_TMP_PATH}/lib/php/session; then
    error "❌ ${EPHEMERAL_STORAGE_TMP_PATH}/lib/php/session ディレクトリの作成に失敗しました。"
    exit 1
fi
log "✅ ${EPHEMERAL_STORAGE_TMP_PATH}/lib/php/session ディレクトリを作成しました。"


if ! mkdir -p ${EPHEMERAL_STORAGE_TMP_PATH}/supervisord/supervisord.d; then
    error "❌ ${EPHEMERAL_STORAGE_TMP_PATH}/supervisord/supervisord.d ディレクトリの作成に失敗しました。"
    exit 1
fi
log "✅ ${EPHEMERAL_STORAGE_TMP_PATH}/supervisord/supervisord.d ディレクトリを作成しました。"


if ! mkdir -p ${EPHEMERAL_STORAGE_TMP_PATH}/run/supervisor; then
    error "❌ ${EPHEMERAL_STORAGE_TMP_PATH}/run/supervisor ディレクトリの作成に失敗しました。"
    exit 1
fi
log "✅ ${EPHEMERAL_STORAGE_TMP_PATH}/run/supervisor ディレクトリを作成しました。"


#
# アプリケーション用のディレクトリを作成する
#


if ! mkdir -p ${EPHEMERAL_STORAGE_TMP_PATH}/app/storage/logs; then
    error "❌ ${EPHEMERAL_STORAGE_TMP_PATH}/app/storage/logs ディレクトリの作成に失敗しました。"
    exit 1
fi
log "✅ ${EPHEMERAL_STORAGE_TMP_PATH}/app/storage/logs ディレクトリを作成しました。"


if ! mkdir -p ${EPHEMERAL_STORAGE_TMP_PATH}/app/storage/framework/cache; then
    error "❌ ${EPHEMERAL_STORAGE_TMP_PATH}/app/storage/framework/cache ディレクトリの作成に失敗しました。"
    exit 1
fi
log "✅ ${EPHEMERAL_STORAGE_TMP_PATH}/app/storage/framework/cache ディレクトリを作成しました。"


if ! mkdir -p ${EPHEMERAL_STORAGE_TMP_PATH}/app/storage/framework/sessions; then
    error "❌ ${EPHEMERAL_STORAGE_TMP_PATH}/app/storage/framework/sessions ディレクトリの作成に失敗しました。"
    exit 1
fi
log "✅ ${EPHEMERAL_STORAGE_TMP_PATH}/app/storage/framework/sessions ディレクトリを作成しました。"


if ! mkdir -p ${EPHEMERAL_STORAGE_TMP_PATH}/app/storage/framework/views; then
    error "❌ ${EPHEMERAL_STORAGE_TMP_PATH}/app/storage/framework/views ディレクトリの作成に失敗しました。"
    exit 1
fi
log "✅ ${EPHEMERAL_STORAGE_TMP_PATH}/app/storage/framework/views ディレクトリを作成しました。"


if ! mkdir -p ${EPHEMERAL_STORAGE_TMP_PATH}/app/storage/framework/views; then
    error "❌ ${EPHEMERAL_STORAGE_TMP_PATH}/app/storage/framework/views ディレクトリの作成に失敗しました。"
    exit 1
fi
log "✅ ${EPHEMERAL_STORAGE_TMP_PATH}/app/storage/framework/views ディレクトリを作成しました。"


if ! mkdir -p ${EPHEMERAL_STORAGE_TMP_PATH}/app/storage/app/public; then
    error "❌ ${EPHEMERAL_STORAGE_TMP_PATH}/app/storage/app/public ディレクトリの作成に失敗しました。"
    exit 1
fi
log "✅ ${EPHEMERAL_STORAGE_TMP_PATH}/app/storage/app/public ディレクトリを作成しました。"


if ! mkdir -p ${EPHEMERAL_STORAGE_TMP_PATH}/app/bootstrap/cache; then
    error "❌ ${EPHEMERAL_STORAGE_TMP_PATH}/app/bootstrap/cache ディレクトリの作成に失敗しました。"
    exit 1
fi
log "✅ ${EPHEMERAL_STORAGE_TMP_PATH}/app/bootstrap/cache ディレクトリを作成しました。"


log "✅ 設定ファイルのディレクトリの作成が完了しました。"


#
# Workerコンテナ用 pyenv ディレクトリの作成とファイルのコピーを行う
#


# ディレクトリの作成
if ! mkdir -p ${EPHEMERAL_STORAGE_TMP_PATH}/pyenv/shims; then
    error "❌ ${EPHEMERAL_STORAGE_TMP_PATH}/pyenv/shims ディレクトリの作成に失敗しました。"
    exit 1
fi
log "✅ ${EPHEMERAL_STORAGE_TMP_PATH}/pyenv/shims ディレクトリを作成しました。"

if ! mkdir -p ${EPHEMERAL_STORAGE_TMP_PATH}/pyenv/versions; then
    error "❌ ${EPHEMERAL_STORAGE_TMP_PATH}/pyenv/versions ディレクトリの作成に失敗しました。"
    exit 1
fi
log "✅ ${EPHEMERAL_STORAGE_TMP_PATH}/pyenv/versions ディレクトリを作成しました。"


# ファイルのコピー
if [ -d "/opt/pyenv/shims" ]; then
    if ! cp -rf /opt/pyenv/shims/* ${EPHEMERAL_STORAGE_TMP_PATH}/pyenv/shims; then
        error "❌ ${EPHEMERAL_STORAGE_TMP_PATH}/pyenv/shims ディレクトリのコピーに失敗しました。"
        exit 1
    fi
    log "✅ ${EPHEMERAL_STORAGE_TMP_PATH}/pyenv/shims ディレクトリをコピーしました。"
else
    log "❗️ /opt/pyenv/shims ディレクトリが見つかりません。スキップします。"
fi

if [ -d "/opt/pyenv/versions" ]; then
    if ! cp -rf /opt/pyenv/versions/* ${EPHEMERAL_STORAGE_TMP_PATH}/pyenv/versions; then
        error "❌ ${EPHEMERAL_STORAGE_TMP_PATH}/pyenv/versions ディレクトリのコピーに失敗しました。"
        exit 1
    fi
    log "✅ ${EPHEMERAL_STORAGE_TMP_PATH}/pyenv/versions ディレクトリをコピーしました。"
else
    log "❗️ /opt/pyenv/versions ディレクトリが見つかりません。スキップします。"
fi


#
# ディレクトリの所有者とパーミッションを設定する
#


if ! chown -R 1000:1000 ${EPHEMERAL_STORAGE_TMP_PATH}; then
    error "❌ ${EPHEMERAL_STORAGE_TMP_PATH} ディレクトリの chown に失敗しました。"
    exit 1
fi
log "✅ ${EPHEMERAL_STORAGE_TMP_PATH} ディレクトリの chown に成功しました。"


if ! chmod -R 775 ${EPHEMERAL_STORAGE_TMP_PATH}; then
    error "❌ ${EPHEMERAL_STORAGE_TMP_PATH} ディレクトリの chmod に失敗しました。"
    exit 1
fi
log "✅ ${EPHEMERAL_STORAGE_TMP_PATH} ディレクトリの chmod に成功しました。"


log "✅ エフェメラルストレージの初期化が完了しました。"


log "🎉🎉🎉 初期化が完了しました。"
