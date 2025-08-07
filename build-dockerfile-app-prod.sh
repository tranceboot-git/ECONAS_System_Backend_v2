#!/bin/bash

# ------------------------------------------------------------------------------------------------
#
# ECONAS Appコンテナ
# Productionイメージ Build Script
#
# ------------------------------------------------------------------------------------------------


echo "🚀 Starting ECONAS app production build..."


# ------------------------------------------------------------------------------------------------
# .envファイルの読み込み

echo "🔍 Checking required environment file..."

ENV_FILE=".env"
ENV_EXAMPLE_FILE="_.env.example"

if [ -f "$ENV_FILE" ]; then
    echo "📄 Loading environment variables from $ENV_FILE"
    # .envファイルを読み込み（コメント行と空行を除外）
    set -a  # 自動的にexportを有効化
    source "$ENV_FILE"
    set +a  # 自動exportを無効化
    echo "✅ Environment variables loaded from $ENV_FILE"
elif [ -f "$ENV_EXAMPLE_FILE" ]; then
    echo "⚠️  $ENV_FILE not found, but $ENV_EXAMPLE_FILE exists"
    echo "💡 You can copy $ENV_EXAMPLE_FILE to $ENV_FILE and customize it"
    echo "📄 Loading default values from $ENV_EXAMPLE_FILE"
    set -a
    source "$ENV_EXAMPLE_FILE"
    set +a
else
    echo "⚠️  Neither $ENV_FILE nor $ENV_EXAMPLE_FILE found"
    echo "💡 Using hardcoded default values"
fi


#
# .envファイル内の必須パラメータが存在するかチェックする
#
echo "🔍 Checking required environment parameters..."

REQUIRED_VARS=(
    "AWS_ACCOUNT_ID"
)

MISSING_VARS=()

for var in "${REQUIRED_VARS[@]}"; do
    if [ -z "${!var}" ]; then
        MISSING_VARS+=("$var")
        echo "❌ Missing required variable: $var"
    else
        echo "✅ Found: $var"
    fi
done

if [ ${#MISSING_VARS[@]} -gt 0 ]; then
    echo ""
    echo "🚫 Error: The following required environment variables are missing:"
    for var in "${MISSING_VARS[@]}"; do
        echo "   - $var"
    done
    echo ""
    echo "💡 Please set these variables in your $ENV_FILE file"
    echo "📝 You can copy $ENV_EXAMPLE_FILE to $ENV_FILE as a template"
    exit 1
fi

echo "✅ All required environment variables are set"




# ------------------------------------------------------------------------------------------------
# 設定

# Docker BuildKitの有効化 (0 . desable / 1 . enable)
export DOCKER_BUILDKIT=1

# Dockerfile
APP_DOCKERFILE_NAME="Dockerfile.app.1.1"

# バージョン情報
APP_INIT_IMAGE_VERSION="1.1"
APP_IMAGE_VERSION="1.1"

# ECRリポジトリのURL (AWSアカウントIDは.envファイルから取得)
APP_INIT_REPOSITORY_URL="${AWS_ACCOUNT_ID}.dkr.ecr.ap-northeast-1.amazonaws.com/econas-prod2-app-init-repo:${APP_INIT_IMAGE_VERSION}"
APP_REPOSITORY_URL="${AWS_ACCOUNT_ID}.dkr.ecr.ap-northeast-1.amazonaws.com/econas-prod2-app-repo:${APP_IMAGE_VERSION}"

# AWS Profile
AWS_PROFILE="dcs_ntt"





# ------------------------------------------------------------------------------------------------
# ビルド実行

echo "👤 User: $DOCKER_HOST_USER_NAME (ID: $DOCKER_HOST_USER_ID, Group: $DOCKER_HOST_GROUP_ID)"


# ビルド実行
echo "🔨 Building app image..."


docker buildx build \
    --load \
    --no-cache \
    --platform linux/amd64 \
    --target init_container \
    --build-arg USER_NAME=root \
    --build-arg USER_ID=0 \
    --build-arg GROUP_ID=0 \
    --build-arg DOCUMENT_ROOT_PATH=/var/app/source/public \
    --build-arg APP_DIRECTORY_PATH=/var/app/source \
    --build-arg APP_ENV_PATH=/tmp/app \
    --build-arg EFS_SETTINGS_MOUNT_PATH=/efs_settings \
    --build-arg EFS_APPLICATION_MOUNT_PATH=/efs \
    --build-arg EPHEMERAL_STORAGE_TMP_PATH=/tmp \
    -t econas-app-init:${APP_INIT_IMAGE_VERSION}-x86_64 \
    -f ${APP_DOCKERFILE_NAME} \
    .


docker buildx build \
    --load \
    --no-cache \
    --platform linux/amd64 \
    --target prod_app \
    --build-arg USER_NAME=app_user \
    --build-arg USER_ID=1000 \
    --build-arg GROUP_ID=1000 \
    --build-arg DOCUMENT_ROOT_PATH=/var/app/source/public \
    --build-arg APP_DIRECTORY_PATH=/var/app/source \
    --build-arg APP_ENV_PATH=/tmp/app \
    --build-arg EFS_SETTINGS_MOUNT_PATH=/efs_settings \
    --build-arg EFS_APPLICATION_MOUNT_PATH=/efs \
    --build-arg EPHEMERAL_STORAGE_TMP_PATH=/tmp \
    -t econas-app:${APP_IMAGE_VERSION}-x86_64 \
    -f ${APP_DOCKERFILE_NAME} \
    .


build_result=$?
if [ $build_result -eq 0 ]; then
    echo "✅ Build completed successfully!"

    docker tag econas-app-init:${APP_INIT_IMAGE_VERSION}-x86_64 ${APP_INIT_REPOSITORY_URL}
    docker tag econas-app:${APP_IMAGE_VERSION}-x86_64 ${APP_REPOSITORY_URL}

    echo "AWS Login..."
    echo "aws ecr get-login-password --region ap-northeast-1 --profile ${AWS_PROFILE} | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.ap-northeast-1.amazonaws.com"
    echo ""
    echo "🔄 Pushing image to ECR..."
    echo ""
    echo "docker push ${APP_INIT_REPOSITORY_URL}"
    echo ""
    echo "docker push ${APP_REPOSITORY_URL}"
    echo ""
else
    echo "❌ Build failed with exit code: $build_result"
    exit $build_result
fi
