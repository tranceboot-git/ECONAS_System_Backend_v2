#!/bin/bash

# -----------------------------------------------------------------------------
#
# AWS ECS Fargate 本番環境用
# 設定ファイル準備スクリプト
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




log "🤖🤖🤖 設定ファイルの準備を開始します..."


# 現在のユーザーIDとグループIDを表示
log "🧍🏻‍♂️ Current user ID: $(id -u)"
log "🧍🏻‍♂️ Current group ID: $(id -g)"
log "🧍🏻‍♂️ Current user: $(whoami)"
log "🧍🏻‍♂️ Current groups: $(groups)"




# -----------------------------------------------------------------------------
# 環境変数が空ではないかバリデーションする
#


# 環境変数の確認
log "➡️ 環境変数を検証します..."


# 必須の環境変数リスト
required_vars=(
    "EFS_APPLICATION_MOUNT_PATH"
    "EPHEMERAL_STORAGE_TMP_PATH"
    "USER_ID"
    "GROUP_ID"
)

# 環境変数のチェック
for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        error "❌ 必要な環境変数 $var が設定されていません。"
        exit 1
    fi
done


log "✅ 環境変数の検証が完了しました。"




# -----------------------------------------------------------------------------
# エフェメラルストレージ (tmp) を初期化する
#


log "➡️ エフェメラルストレージ (tmp) を初期化します..."


#
# マウントポイントを確認する
#


log "➡️ エフェメラルストレージ (tmp) のマウントポイントを確認します..."


if [ ! -d "${EPHEMERAL_STORAGE_TMP_PATH}" ]; then
    error "❌ ディレクトリ ${EPHEMERAL_STORAGE_TMP_PATH} が見つかりません。"
    exit 1
fi
log "✅ ディレクトリ ${EPHEMERAL_STORAGE_TMP_PATH} が見つかりました。"


#
# 設定ファイルをコピーする
#


log "➡️ 設定ファイルをコピーします..."


# httpd.conf
if [ -f "${EPHEMERAL_STORAGE_TMP_PATH}/init_setting_files/httpd/conf/httpd.prod.conf" ]; then
    if ! cp -f ${EPHEMERAL_STORAGE_TMP_PATH}/init_setting_files/httpd/conf/httpd.prod.conf ${EPHEMERAL_STORAGE_TMP_PATH}/httpd/conf/httpd.conf; then
        error "❌ ${EPHEMERAL_STORAGE_TMP_PATH}/httpd/conf/httpd.conf ファイルのコピーに失敗しました。"
        exit 1
    fi
    log "✅ ${EPHEMERAL_STORAGE_TMP_PATH}/httpd/conf/httpd.conf ファイルをコピーしました。"
else
    error "❌ ${EPHEMERAL_STORAGE_TMP_PATH}/init_setting_files/httpd/conf/httpd.prod.conf ファイルが見つかりません。"
    exit 1
fi


# app.conf
if [ -f "${EPHEMERAL_STORAGE_TMP_PATH}/init_setting_files/httpd/conf.d/app.prod.conf" ]; then
    if ! cp -f ${EPHEMERAL_STORAGE_TMP_PATH}/init_setting_files/httpd/conf.d/app.prod.conf ${EPHEMERAL_STORAGE_TMP_PATH}/httpd/conf.d/app.conf; then
        error "❌ ${EPHEMERAL_STORAGE_TMP_PATH}/httpd/conf.d/app.conf ファイルのコピーに失敗しました。"
        exit 1
    fi
    log "✅ ${EPHEMERAL_STORAGE_TMP_PATH}/httpd/conf.d/app.conf ファイルをコピーしました。"
else
    error "❌ ${EPHEMERAL_STORAGE_TMP_PATH}/init_setting_files/httpd/conf.d/app.prod.conf ファイルが見つかりません。"
    exit 1
fi


# supervisord.conf
if [ -f "${EPHEMERAL_STORAGE_TMP_PATH}/init_setting_files/supervisord/supervisord.conf" ]; then
    if ! cp -f ${EPHEMERAL_STORAGE_TMP_PATH}/init_setting_files/supervisord/supervisord.conf ${EPHEMERAL_STORAGE_TMP_PATH}/supervisord/supervisord.conf; then
        error "❌ ${EPHEMERAL_STORAGE_TMP_PATH}/supervisord/supervisord.conf ファイルのコピーに失敗しました。"
        exit 1
    fi
    log "✅ ${EPHEMERAL_STORAGE_TMP_PATH}/supervisord/supervisord.conf ファイルをコピーしました。"
else
    error "❌ ${EPHEMERAL_STORAGE_TMP_PATH}/init_setting_files/supervisord/supervisord.conf ファイルが見つかりません。"
    exit 1
fi


# laravel-worker.ini
if [ -f "${EPHEMERAL_STORAGE_TMP_PATH}/init_setting_files/supervisord/supervisord.d/laravel-worker.ini" ]; then
    if ! cp -f ${EPHEMERAL_STORAGE_TMP_PATH}/init_setting_files/supervisord/supervisord.d/laravel-worker.ini ${EPHEMERAL_STORAGE_TMP_PATH}/supervisord/supervisord.d/laravel-worker.ini; then
        error "❌ ${EPHEMERAL_STORAGE_TMP_PATH}/supervisord/supervisord.d/laravel-worker.ini ファイルのコピーに失敗しました。"
        exit 1
    fi
    log "✅ ${EPHEMERAL_STORAGE_TMP_PATH}/supervisord/supervisord.d/laravel-worker.ini ファイルをコピーしました。"
else
    error "❌ ${EPHEMERAL_STORAGE_TMP_PATH}/init_setting_files/supervisord/supervisord.d/laravel-worker.ini ファイルが見つかりません。"
    exit 1
fi


log "✅ 設定ファイルのコピーが完了しました。"


#
# 設定ファイルを変更する
#


log "➡️ 設定ファイルを変更します..."


# -httpd.conf


log "➡️ httpd.conf ファイルを変更します..."


if [ -f "${EPHEMERAL_STORAGE_TMP_PATH}/httpd/conf/httpd.conf" ]; then
    # コンテナのユーザで実行するため、User/Group設定をコメントアウト
    # 既にコメントアウトされていない場合のみ置換
    sed -i '/^[[:space:]]*#/!s/^[[:space:]]*User apache/# User apache/' ${EPHEMERAL_STORAGE_TMP_PATH}/httpd/conf/httpd.conf
    sed -i '/^[[:space:]]*#/!s/^[[:space:]]*Group apache/# Group apache/' ${EPHEMERAL_STORAGE_TMP_PATH}/httpd/conf/httpd.conf

    if ! sed -i "s|ErrorLog \"logs/error_log\"|ErrorLog \"${EFS_APPLICATION_MOUNT_PATH}/logs/httpd/error_log\"|" ${EPHEMERAL_STORAGE_TMP_PATH}/httpd/conf/httpd.conf; then
        error "❌ httpd.conf の ErrorLog の置換に失敗しました。"
        exit 1
    fi
    if ! sed -i "s|CustomLog \"logs/access_log\" combined|CustomLog \"${EFS_APPLICATION_MOUNT_PATH}/logs/httpd/access_log\" combined|" ${EPHEMERAL_STORAGE_TMP_PATH}/httpd/conf/httpd.conf; then
        error "❌ httpd.conf の CustomLog の置換に失敗しました。"
        exit 1
    fi
    if ! sed -i "s|IncludeOptional conf.d/\*.conf|IncludeOptional ${EPHEMERAL_STORAGE_TMP_PATH}/httpd/conf.d/*.conf|" ${EPHEMERAL_STORAGE_TMP_PATH}/httpd/conf/httpd.conf; then
        error "❌ httpd.conf の IncludeOptional の置換に失敗しました。"
        exit 1
    fi
    log "✅ httpd.conf ファイルの変更に成功しました。"
else
    error "❌ httpd.conf ファイルが見つかりません。"
    exit 1
fi


# -app.conf


log "➡️ app.conf ファイルを変更します..."


if [ -f "${EPHEMERAL_STORAGE_TMP_PATH}/httpd/conf.d/app.conf" ]; then
    # 環境変数を置換
    if ! sed -i "s|<SSL_ENABLED>|$SSL_ENABLED|" ${EPHEMERAL_STORAGE_TMP_PATH}/httpd/conf.d/app.conf; then
        error "❌ app.prod.conf の SSL_ENABLED 置換に失敗しました。"
        exit 1
    fi
    if ! sed -i "s|<DOMAIN_NAME>|$DOMAIN_NAME|" ${EPHEMERAL_STORAGE_TMP_PATH}/httpd/conf.d/app.conf; then
        error "❌ app.prod.conf の DOMAIN_NAME 置換に失敗しました。"
        exit 1
    fi
    if ! sed -i "s|<ADMIN_EMAIL>|$ADMIN_EMAIL|" ${EPHEMERAL_STORAGE_TMP_PATH}/httpd/conf.d/app.conf; then
        error "❌ app.prod.conf の ADMIN_EMAIL 置換に失敗しました。"
        exit 1
    fi
    if ! sed -i "s|<DOCUMENT_ROOT_PATH>|$DOCUMENT_ROOT_PATH|" ${EPHEMERAL_STORAGE_TMP_PATH}/httpd/conf.d/app.conf; then
        error "❌ app.prod.conf の DOCUMENT_ROOT_PATH 置換に失敗しました。"
        exit 1
    fi
    if ! sed -i "s|<APP_DIRECTORY_PATH>|$APP_DIRECTORY_PATH|" ${EPHEMERAL_STORAGE_TMP_PATH}/httpd/conf.d/app.conf; then
        error "❌ app.prod.conf の APP_DIRECTORY_PATH 置換に失敗しました。"
        exit 1
    fi
    if ! sed -i "s|<HTTPD_LOG_LEVEL>|$HTTPD_LOG_LEVEL|" ${EPHEMERAL_STORAGE_TMP_PATH}/httpd/conf.d/app.conf; then
        error "❌ app.prod.conf の HTTPD_LOG_LEVEL 置換に失敗しました。"
        exit 1
    fi
    if ! sed -i "s|<EFS_APPLICATION_MOUNT_PATH>|$EFS_APPLICATION_MOUNT_PATH|" ${EPHEMERAL_STORAGE_TMP_PATH}/httpd/conf.d/app.conf; then
        error "❌ app.prod.conf の EFS_APPLICATION_MOUNT_PATH 置換に失敗しました。"
        exit 1
    fi
    log "✅ app.prod.conf ファイルを更新しました。"
else
    error "❌ app.prod.conf ファイルが見つかりません。"
    exit 1
fi


# - supervisord


log "➡️ laravel-worker.ini ファイルを変更します..."


if [ -f "${EPHEMERAL_STORAGE_TMP_PATH}/supervisord/supervisord.d/laravel-worker.ini" ]; then
    # 環境変数を置換

    if ! sed -i "s|user = apache|user = ${USER_ID}|" ${EPHEMERAL_STORAGE_TMP_PATH}/supervisord/supervisord.d/laravel-worker.ini; then
        error "❌ laravel-worker.ini ファイルの user 置換に失敗しました。"
        exit 1
    fi
    if ! sed -i "s|group = apache|group = ${GROUP_ID}|" ${EPHEMERAL_STORAGE_TMP_PATH}/supervisord/supervisord.d/laravel-worker.ini; then
        error "❌ laravel-worker.ini ファイルの group 置換に失敗しました。"
        exit 1
    fi
    if ! sed -i 's|<APP_DIRECTORY_PATH>|'"${APP_DIRECTORY_PATH}"'|' ${EPHEMERAL_STORAGE_TMP_PATH}/supervisord/supervisord.d/laravel-worker.ini; then
        error "❌ laravel-worker.ini ファイルの APP_DIRECTORY_PATH 置換に失敗しました。"
        exit 1
    fi
    log "✅ laravel-worker.ini ファイルをコピーしました。"
else
    error "❌ laravel-worker.ini ファイルが見つかりません。"
    exit 1
fi


#
# 設定ファイルのパーミッションを設定する
#


log "➡️ 設定ファイルのパーミッションを設定します..."


if ! chmod 644 ${EPHEMERAL_STORAGE_TMP_PATH}/httpd/conf/httpd.conf; then
    error "❌ ${EPHEMERAL_STORAGE_TMP_PATH}/httpd/conf/httpd.conf ファイルのパーミッション設定に失敗しました。"
    exit 1
fi
log "✅ ${EPHEMERAL_STORAGE_TMP_PATH}/httpd/conf/httpd.conf ファイルのパーミッション設定に成功しました。"


if ! chmod 644 ${EPHEMERAL_STORAGE_TMP_PATH}/httpd/conf.d/app.conf; then
    error "❌ ${EPHEMERAL_STORAGE_TMP_PATH}/httpd/conf.d/app.conf ファイルのパーミッション設定に失敗しました。"
    exit 1
fi
log "✅ ${EPHEMERAL_STORAGE_TMP_PATH}/httpd/conf.d/app.conf ファイルのパーミッション設定に成功しました。"


if ! chmod 644 ${EPHEMERAL_STORAGE_TMP_PATH}/supervisord/supervisord.conf; then
    error "❌ ${EPHEMERAL_STORAGE_TMP_PATH}/supervisord/supervisord.conf ファイルのパーミッション設定に失敗しました。"
    exit 1
fi
log "✅ ${EPHEMERAL_STORAGE_TMP_PATH}/supervisord/supervisord.conf ファイルのパーミッション設定に成功しました。"


if ! chmod 644 ${EPHEMERAL_STORAGE_TMP_PATH}/supervisord/supervisord.d/laravel-worker.ini; then
    error "❌ ${EPHEMERAL_STORAGE_TMP_PATH}/supervisord/supervisord.d/laravel-worker.ini ファイルのパーミッション設定に失敗しました。"
    exit 1
fi
log "✅ ${EPHEMERAL_STORAGE_TMP_PATH}/supervisord/supervisord.d/laravel-worker.ini ファイルのパーミッション設定に成功しました。"


log "✅ 設定ファイルのパーミッション設定が完了しました。"


log "✅ エフェメラルストレージ (tmp) を初期化を完了しました。"




# -----------------------------------------------------------------------------
# アプリケーションデータを配置する EFS ストレージを初期化
#


#
# マウントポイントを確認する
#


log "➡️ アプリケーションデータを配置するEFSストレージのマウントポイントを確認します..."


if [ ! -d "${EFS_APPLICATION_MOUNT_PATH}" ]; then
    error "❌ ディレクトリ ${EFS_APPLICATION_MOUNT_PATH} が見つかりません。"
    exit 1
fi
log "✅ ディレクトリ ${EFS_APPLICATION_MOUNT_PATH} が見つかりました。"


#
# ディレクトリを確認する
#


log "➡️ ディレクトリを確認しています..."


# app Lib firmware ディレクトリの作成
if [ -d "${EFS_APPLICATION_MOUNT_PATH}/app/Lib/firmware" ]; then
    log "✅ ${EFS_APPLICATION_MOUNT_PATH}/app/Lib/firmware ディレクトリを確認しました。"
else
    mkdir -p ${EFS_APPLICATION_MOUNT_PATH}/app/Lib/firmware
    log "❗️ ${EFS_APPLICATION_MOUNT_PATH}/app/Lib/firmware ディレクトリを作成しました。"
fi


# app Lib setting ディレクトリの作成
if [ -d "${EFS_APPLICATION_MOUNT_PATH}/app/Lib/setting" ]; then
    log "✅ ${EFS_APPLICATION_MOUNT_PATH}/app/Lib/setting ディレクトリを確認しました。"
else
    mkdir -p ${EFS_APPLICATION_MOUNT_PATH}/app/Lib/setting
    log "❗️ ${EFS_APPLICATION_MOUNT_PATH}/app/Lib/setting ディレクトリを作成しました。"
fi


# app ログディレクトリの作成
if [ -d "${EFS_APPLICATION_MOUNT_PATH}/logs/app" ]; then
    log "✅ ${EFS_APPLICATION_MOUNT_PATH}/logs/app ディレクトリを確認しました。"
else
    mkdir -p ${EFS_APPLICATION_MOUNT_PATH}/logs/app
    log "❗️ ${EFS_APPLICATION_MOUNT_PATH}/logs/app ディレクトリを作成しました。"
fi


# httpdログディレクトリの作成
if [ -d "${EFS_APPLICATION_MOUNT_PATH}/logs/httpd" ]; then
    log "✅ ${EFS_APPLICATION_MOUNT_PATH}/logs/httpd ディレクトリを確認しました。"
else
    mkdir -p ${EFS_APPLICATION_MOUNT_PATH}/logs/httpd
    log "❗️ ${EFS_APPLICATION_MOUNT_PATH}/logs/httpd ディレクトリを作成しました。"
fi


# system ログディレクトリの作成
if [ -d "${EFS_APPLICATION_MOUNT_PATH}/logs/system" ]; then
    log "✅ ${EFS_APPLICATION_MOUNT_PATH}/logs/system ディレクトリを確認しました。"
else
    mkdir -p ${EFS_APPLICATION_MOUNT_PATH}/logs/system
    log "❗️ ${EFS_APPLICATION_MOUNT_PATH}/logs/system ディレクトリを作成しました。"
fi


# supervisor ログディレクトリの作成
if [ -d "${EFS_APPLICATION_MOUNT_PATH}/logs/supervisor" ]; then
    log "✅ ${EFS_APPLICATION_MOUNT_PATH}/logs/supervisor ディレクトリを確認しました。"
else
    mkdir -p ${EFS_APPLICATION_MOUNT_PATH}/logs/supervisor
    log "❗️ ${EFS_APPLICATION_MOUNT_PATH}/logs/supervisor ディレクトリを作成しました。"
fi


# php-fpm ログディレクトリの作成
if [ -d "${EFS_APPLICATION_MOUNT_PATH}/logs/php-fpm" ]; then
    log "✅ ${EFS_APPLICATION_MOUNT_PATH}/logs/php-fpm ディレクトリを確認しました。"
else
    mkdir -p ${EFS_APPLICATION_MOUNT_PATH}/logs/php-fpm
    log "❗️ ${EFS_APPLICATION_MOUNT_PATH}/logs/php-fpm ディレクトリを作成しました。"
fi


log "✅ ディレクトリの確認が完了しました。"


#
# EFS ファイルの作成
#


log "➡️ ディレクトリ内のファイルをチェックしています..."


# httpd エラーログファイルの作成
if [ -f "${EFS_APPLICATION_MOUNT_PATH}/logs/httpd/error_log" ]; then
    log "✅ ${EFS_APPLICATION_MOUNT_PATH}/logs/httpd/error_log ファイルを確認しました。"
else
    touch ${EFS_APPLICATION_MOUNT_PATH}/logs/httpd/error_log
    log "❗️ ${EFS_APPLICATION_MOUNT_PATH}/logs/httpd/error_log ファイルを作成しました。"
fi


# httpd アクセスログファイルの作成
if [ -f "${EFS_APPLICATION_MOUNT_PATH}/logs/httpd/access_log" ]; then
    log "✅ ${EFS_APPLICATION_MOUNT_PATH}/logs/httpd/access_log ファイルを確認しました。"
else
    touch ${EFS_APPLICATION_MOUNT_PATH}/logs/httpd/access_log
    log "❗️ ${EFS_APPLICATION_MOUNT_PATH}/logs/httpd/access_log ファイルを作成しました。"
fi


# php-fpm ログファイルの作成
if [ -f "${EFS_APPLICATION_MOUNT_PATH}/logs/php-fpm/error.log" ]; then
    log "✅ ${EFS_APPLICATION_MOUNT_PATH}/logs/php-fpm/error.log ファイルを確認しました。"
else
    touch ${EFS_APPLICATION_MOUNT_PATH}/logs/php-fpm/error.log
    log "❗️ ${EFS_APPLICATION_MOUNT_PATH}/logs/php-fpm/error.log ファイルを作成しました。"
fi


log "✅ ファイルのチェックが完了しました。"


log "🎉🎉🎉 設定ファイルの準備が完了しました。"
