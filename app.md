# ECONAS System Backend <br> アプリケーションイメージ


<br><br>


## 引数
ビルド時にのみ指定できる変数

|引数               |説明                               |型     |デフォルト値         |ビルド時必須 |メモ                                   |
|:------------------|:----------------------------------|:------|:--------------------|:-----------:|:--------------------------------------|
|EFS_MOUNT_PATH     |EFSボリュームマウント先            |文字列 |/efs                 |必須         |                                       |
|APP_DIRECTORY_PATH |アプリケーションのディレクトリパス |文字列 |/var/www/html        |必須         |                                       |


<br><br>


## 環境変数
コンテナでは次の環境変数が使えます。

|引数               |説明                               |型     |デフォルト値  |必須 |メモ                                          |
|:------------------|:----------------------------------|:------|:-------------|:----|:---------------------------------------------|
|SSL_ENABLED        |https を強制する                   |ブール |true          |     |httpを使いたい時は false を指定する           |
|EFS_MOUNT_PATH     |EFSボリュームマウント先            |文字列 |              |  -  |イメージのビルドで使用しているため指定不可    |
|DOMAIN_NAME        |ドメイン名                         |文字列 |              |必須 |FQDN（Fullualified Domain Name）で記述        |
|ADMIN_EMAIL        |管理者のメールアドレス             |文字列 |              |必須 |                                              |
|DOCUMENT_ROOT_PATH |ドキュメントルートのパス           |文字列 |/var/www/html |     |                                              |
|HTTPD_LOG_LEVEL    |Httpdのログレベル                  |文字列 |info          |     |Httpdのログレベルを設定する<br>(debug, info, notice, warn, wrror, crit, alert, emerg) |
|APP_DIRECTORY_PATH |アプリケーションのディレクトリパス |文字列 |              |  -  |イメージのビルドで使用しているため指定不可    |
|APP_NAME           |アプリケーション名                 |文字列 |              |必須 |                                              |
|APP_URL            |アプリケーションURL                |文字列 |              |必須 |                                              |
|APP_KEY            |ランダムな文字列                   |文字列 |              |     |指定しない場合はキーを新規生成する            |
|APP_DEBUG          |デバッグフラグ                     |ブール |false         |     |Laravelのデバッグモードを設定する             |
|APP_ENV            |アプリケーションを実行している環境 |文字列 |production    |     |Laravelの env を設定する                      |
|APP_LOG_LEVEL      |アプリケーションのログレベル       |文字列 |info          |     |Laravelのログレベルを設定する<br>(debug, info, notice, warning, error, critical, alert, emergency) |
|DB_CONNECTION      |データベースの種類                 |文字列 |mysql         |     |                                              |
|DB_HOST            |データベースサーバのホスト名       |文字列 |              |必須 |                                              |
|DB_PORT            |ポート番号                         |文字列 |3306          |     |                                              |
|DB_DATABASE        |データベース名                     |文字列 |              |必須 |                                              |
|DB_USERNAME        |ユーザ名                           |文字列 |              |必須 |                                              |
|DB_PASSWORD        |ユーザパスワード                   |文字列 |              |必須 |                                              |
|MAIL_MAILER        |メール送信ドライバー               |文字列 |              |必須 |                                              |
|MAIL_HOST          |メールサーバのホスト名             |文字列 |              |必須 |                                              |
|MAIL_PORT          |ポート番号                         |文字列 |              |必須 |                                              |
|MAIL_USERNAME      |ユーザ名                           |文字列 |              |必須 |                                              |
|MAIL_PASSWORD      |ユーザパスワード                   |文字列 |              |必須 |                                              |
|MAIL_ENCRYPTION    |メール送信時の暗号化方式           |文字列 |              |必須 |                                              |
|MAIL_FROM_ADDRESS  |メール送信時の送信元アドレス       |文字列 |              |必須 |                                              |
|MAIL_FROM_NAME     |メールの送信者の名前               |文字列 |              |必須 |                                              |


<br><br>


## イメージのビルド

### Appleシリコン（ARM64）環境で、x86_64アーキテクチャのDockerイメージを作成する
Appleシリコンを搭載するMacを使用している場合、Docker buildで生成されるイメージはARM64アーキテクチャ用に作成されます。
AWS ECS にデプロイするイメージを作成する場合は、buildxを使用してx86_64アーキテクチャのイメージを作成します。

> 注意点  
> Builders で docker buildx を Use にしたままにすると、ARM64アーキテクチャのビルドに失敗することがあります。  
> よくあるケースは、VS Code の devcontainer で 開発用のDockerimageに入ろうとして何らかのエラーが発生することがあります。  
> その場合は、docker-desktop設定のBuildersから、Selected builderを「default」に変更してします。

1. ビルダーインスタンスを有効にする
    docker-desktopの設定 - Buildersから、Selected builderをビルダーインスタンスに変更します。
    ビルダーインスタンスがない場合、以下のコマンドで作成します。

    ```bash
    docker buildx create --name mybuildx --use
    ```

2. x86_64アーキテクチャでイメージをビルドする

    ```bash
    docker buildx build --no-cache --platform linux/amd64 --load --build-arg {ARG}={VALUE} -t {IMAGE_NAME}:{TAG} -f {DOCKER_FILE} .
    ```

    |入力値      |説明                     |
    |------------|-------------------------|
    |ARG         |ビルド時に指定する引数名 |
    |VALUE       |ビルド時に指定する値     |
    |IMAGE_NAME  |確認するDockerfile名     |
    |TAG         |タグ                     |
    |DOCKER_FILE |ビルドするDockerファイル |

    ```bash
    # コマンド例
    docker buildx build --no-cache --platform linux/amd64 --load --build-arg EFS_MOUNT_PATH=/efs --build-arg APP_DIRECTORY_PATH=/var/www/html -t local/econas/x86_64/econas-app:1.0 -f Dockerfile.1.0 .
    ```


<br><br>


## ECRリポジトリにイメージをプッシュする

1. ビルドしたイメージに、プッシュ先のECRリポジトリに合わせてタグを付ける

    ECRリポジトリへのプッシュするために、イメージにタグを付けます。

    ```bash
    # 書式
    docker tag {IMAGE_NAME}:{TAG} {ACCOUNT_ID}.dkr.ecr.ap-northeast-1.amazonaws.com/{REPOSITORY_NAME}:{TAG}
    ```

    |プレースホルダ  |説明                                   |
    |----------------|---------------------------------------|
    |IMAGE_NAME      |タグを付ける対象のDockerイメージの名前 |
    |TAG             |タグをつける対象のDockerイメージのタグ |
    |ACCOUNT_ID      |AWSのアカウントID                      |
    |REPOSITORY_NAME |ECRリポジトリ名                        |

    例
    ```bash
    docker tag local/econas/x86_64/econas-app:1.0 099935470236.dkr.ecr.ap-northeast-1.amazonaws.com/econas-app-repo:1.0
    ```
    <br>

2. AWS ECR へログインする

    AWSの資格情報を使用して、Docker CLIを ECR に認証させるためのコマンドを取得します。

    ```bash
    aws ecr get-login-password --region ap-northeast-1 --profile {PROFILE_NAME} | docker login --username AWS --password-stdin {ACCOUNT_ID}.dkr.ecr.ap-northeast-1.amazonaws.com
    ```

    |プレースホルダ |説明                                                          |
    |---------------|--------------------------------------------------------------|
    |PROFILE_NAME   |AWS-CLIのconfigファイルに設定しているプロファイル名を入力する |
    |ACCOUNT_ID     |AWSのアカウントID                                             |
    <br>

3. ビルドしたイメージを ECR にプッシュする

    ```bash
    # 書式
    docker push {ACCOUNT_ID}.dkr.ecr.ap-northeast-1.amazonaws.com/{REPOSITORY_NAME}:{TAG}
    ```

    |プレースホルダ  |説明                                   |
    |----------------|---------------------------------------|
    |ACCOUNT_ID      |AWSのアカウントID                      |
    |REPOSITORY_NAME |ECRリポジトリ名                        |
    |TAG             |タグをつける対象のDockerイメージのタグ |

    例
    ```bash
    docker push 099935470236.dkr.ecr.ap-northeast-1.amazonaws.com/econas-app-repo:1.0
    ```