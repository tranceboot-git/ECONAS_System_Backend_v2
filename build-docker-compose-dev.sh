#!/bin/bash

# ------------------------------------------------------------------------------------------------
#
# ECONAS Development Build Script
# BuildKitを無効化してビルドを実行
#
# ------------------------------------------------------------------------------------------------


echo "🚀 Starting ECONAS development build..."


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




# ------------------------------------------------------------------------------------------------
# ビルド実行

echo "👤 User: $DOCKER_HOST_USER_NAME (ID: $DOCKER_HOST_USER_ID, Group: $DOCKER_HOST_GROUP_ID)"

# ビルド実行
echo "🔨 Building containers..."

docker compose -f docker-compose.dev.yml build "$@"

build_result=$?
if [ $build_result -eq 0 ]; then
    echo "✅ Build completed successfully!"
    echo "🎯 You can now run: docker compose -f docker-compose.dev.yml up -d"
else
    echo "❌ Build failed with exit code: $build_result"
    exit $build_result
fi