#!/bin/bash
set -euxo pipefail


# -----------------------------------------------------------------------------
# EFS 設定ファイルをコピーする
#


echo "Starting configs initialization..."


# 現在のユーザーIDとグループIDを表示
echo "Current user ID: $(id -u)"
echo "Current group ID: $(id -g)"
echo "Current user: $(whoami)"
echo "Current groups: $(groups)"


# httpd.conf
if [ -f "${EFS_SETTINGS_MOUNT_PATH}/httpd/conf/httpd.xserver_vps.conf" ]; then
    cp -f ${EFS_SETTINGS_MOUNT_PATH}/httpd/conf/httpd.xserver_vps.conf ${SETTINGS_PATH}/httpd/conf/httpd.conf

    sed -i "s|User apache|User $USER_NAME|" ${SETTINGS_PATH}/httpd/conf/httpd.conf
    sed -i "s|ServerAdmin root@localhost|ServerAdmin $ADMIN_EMAIL|" ${SETTINGS_PATH}/httpd/conf/httpd.conf
    sed -i "s|DocumentRoot \"/var/www/html\"|DocumentRoot \"$DOCUMENT_ROOT_PATH\"|" ${SETTINGS_PATH}/httpd/conf/httpd.conf
    sed -i "s|ErrorLog \"logs/error_log\"|ErrorLog \"$EFS_APPLICATION_MOUNT_PATH/logs/httpd/error_log\"|" ${SETTINGS_PATH}/httpd/conf/httpd.conf
    sed -i "s|CustomLog \"logs/access_log\" combined|CustomLog \"$EFS_APPLICATION_MOUNT_PATH/logs/httpd/access_log\" combined|" ${SETTINGS_PATH}/httpd/conf/httpd.conf
    sed -i "s|IncludeOptional conf.d/\*.conf|IncludeOptional ${SETTINGS_PATH}/httpd/conf.d/\*.conf|" ${SETTINGS_PATH}/httpd/conf/httpd.conf

    chmod 644 ${SETTINGS_PATH}/httpd/conf/httpd.conf

    echo "httpd.conf file copy completed successfully."
else
    echo "httpd.conf file not found."
fi


# app.conf
if [ -f "${EFS_SETTINGS_MOUNT_PATH}/httpd/conf.d/app.xserver_vps.conf" ]; then
    cp -f ${EFS_SETTINGS_MOUNT_PATH}/httpd/conf.d/app.xserver_vps.conf ${SETTINGS_PATH}/httpd/conf.d/app.conf
    chmod 644 ${SETTINGS_PATH}/httpd/conf.d/app.conf

    echo "prod.app.conf file copy completed successfully."
else
    echo "prod.app.conf file not found."
fi


# supervisord.conf
if [ -f "${EFS_SETTINGS_MOUNT_PATH}/supervisord/supervisord.conf" ]; then
    cp -f ${EFS_SETTINGS_MOUNT_PATH}/supervisord/supervisord.conf ${SETTINGS_PATH}/supervisord/supervisord.conf
    chmod 644 ${SETTINGS_PATH}/supervisord/supervisord.conf

    echo "supervisord.conf file copy completed successfully."
else
    echo "supervisord.conf file not found."
fi


# laravel-worker.ini
if [ -f "${EFS_SETTINGS_MOUNT_PATH}/supervisord/supervisord.d/laravel-worker.ini" ]; then
    cp -f ${EFS_SETTINGS_MOUNT_PATH}/supervisord/supervisord.d/laravel-worker.ini ${SETTINGS_PATH}/supervisord/supervisord.d/laravel-worker.ini
    chmod 644 ${SETTINGS_PATH}/supervisord/supervisord.d/laravel-worker.ini

    echo "laravel-worker.ini file copy completed successfully."
else
    echo "laravel-worker.ini file not found."
fi


# -----------------------------------------------------------------------------
# EFS ディレクトリのチェック
#


echo "Checking EFS directories..."


# app Lib firmware ディレクトリの作成
if [ ! -d "${EFS_APPLICATION_MOUNT_PATH}/app/Lib/firmware" ]; then
    mkdir -p ${EFS_APPLICATION_MOUNT_PATH}/app/Lib/firmware
    echo "${EFS_APPLICATION_MOUNT_PATH}/app/Lib/firmware directory created successfully."
fi


# app Lib setting ディレクトリの作成
if [ ! -d "${EFS_APPLICATION_MOUNT_PATH}/app/Lib/setting" ]; then
    mkdir -p ${EFS_APPLICATION_MOUNT_PATH}/app/Lib/setting
    echo "${EFS_APPLICATION_MOUNT_PATH}/app/Lib/setting directory created successfully."
fi


# app ログディレクトリの作成
if [ ! -d "${EFS_APPLICATION_MOUNT_PATH}/logs/app" ]; then
    mkdir -p ${EFS_APPLICATION_MOUNT_PATH}/logs/app
    echo "${EFS_APPLICATION_MOUNT_PATH}/logs/app directory created successfully."
fi


# httpdログディレクトリの作成
if [ ! -d "${EFS_APPLICATION_MOUNT_PATH}/logs/httpd" ]; then
    mkdir -p ${EFS_APPLICATION_MOUNT_PATH}/logs/httpd
    echo "${EFS_APPLICATION_MOUNT_PATH}/logs/httpd directory created successfully."
fi


# system ログディレクトリの作成
if [ ! -d "${EFS_APPLICATION_MOUNT_PATH}/logs/system" ]; then
    mkdir -p ${EFS_APPLICATION_MOUNT_PATH}/logs/system
    echo "${EFS_APPLICATION_MOUNT_PATH}/logs/system directory created successfully."
fi


# supervisor ログディレクトリの作成
if [ ! -d "${EFS_APPLICATION_MOUNT_PATH}/logs/supervisor" ]; then
    mkdir -p ${EFS_APPLICATION_MOUNT_PATH}/logs/supervisor
    echo "${EFS_APPLICATION_MOUNT_PATH}/logs/supervisor directory created successfully."
fi


echo "EFS directories check completed successfully."


# -----------------------------------------------------------------------------
# EFS ファイルのチェック
#


echo "Checking EFS files..."


# httpd エラーログファイルの作成
if [ ! -f "${EFS_APPLICATION_MOUNT_PATH}/logs/httpd/error_log" ]; then
    touch ${EFS_APPLICATION_MOUNT_PATH}/logs/httpd/error_log
    echo "${EFS_APPLICATION_MOUNT_PATH}/logs/httpd/error_log file created successfully."
fi


# httpd アクセスログファイルの作成
if [ ! -f "${EFS_APPLICATION_MOUNT_PATH}/logs/httpd/access_log" ]; then
    touch ${EFS_APPLICATION_MOUNT_PATH}/logs/httpd/access_log
    echo "${EFS_APPLICATION_MOUNT_PATH}/logs/httpd/access_log file created successfully."
fi


echo "EFS files check completed successfully."
