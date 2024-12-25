# Cloud RunのCI/CDをGithub Actionsで実装するサンプル
 - Cloud Runプロジェクト用のCI/CD構築
 - Github ActionsでCI/CDワークフロー管理
 - Terraformでデプロイ管理
 - フロントエンドはNextjs、バックエンドはGo

# 動作環境
## ローカル環境
- PC: MacBook Pro 14inch 2021 / M1 Pro / 32GB
- OS: macOS Sequoia 15.1.1
- Docker: 4.36.0
- Terraform: v1.9.4
- GNU Make: 3.81
- VS Code: 1.96
## プロジェクト
- Go: 1.23
- Node.js: 22
- Next.js: 15
## Google Cloud
- Aritfact Registry
- Cloud Run
- Cloud Storage

# ローカル環境（dev stage）
docker composeを利用してdev stageでの動作確認方法を示します。
## 初期設定
### 環境変数設定
1. `.env_sample`ファイルを複製して`.env`にリネーム
1. 各変数を設定。※ローカル環境で利用する情報です。
    |変数名|説明|例|
    |----|----|----|
    |BACKEND_PORT|バックエンドポート（任意）|8081|
    |FRONTEND_PORT|フロントエンドポート（任意）|3000|

### Goプロジェクト作成
#### 新規作成
1. backend/srcフォルダを作成
```sh
mkdir backend/src
```  
1. go mod initを実行  

docker compose -f compose-init.yaml run --rm backend sh -c "go mod init <プロジェクト名>"
```  
例  
```sh
docker compose -f compose-init.yaml run --rm backend sh -c "go mod init github.com/nicky-tree55/cloud-run-nextjs-go-cicd-sample/backend"
```  

#### 編集
1. goのコードを作成する
1. go mod tidy（モジュールの追加や削除を行ったときに実行）
```sh
make go-mod-tidy
```  

### Next.jsプロジェクト作成
#### 新規作成
1. frontend.srcフォルダ作成  
```sh
mkdir frontend/src
```
1. Next.jsプロジェクトを新規作成
```sh
docker compose -f compose-init.yaml run --rm frontend sh -c "npx create-next-app@latest . --use-npm --typescript"
```  
1. standaloneモードを有効にする
`frontend/src/next.config/ts`ファイルに`output: standalone`を追記
```ts
const nextConfig: NextConfig = {
  output: 'standalone',
};
```

#### 編集
1. Next.jsのプロジェクトを編集する
1. npm installでモジュールをインストール（make コマンド）
```sh
make npm-install
```

## サービス起動&停止
1. makeコマンドで起動
```sh
make up
```
1. makeコマンドで停止
```sh
make down
```

### 起動方法
1. makeコマンド`make start`で起動する
1. [http://localhost:<ポート番号>](http://localhost:<ポート番号>)にアクセス　※デフォルトは[http://localhost:3000](http://localhost:3000)

## ローカル環境（runner stage）
Dockerfileをビルドしてrunner stageでの動作確認方法を示します。
### ビルド方法
1. makeコマンド`prod-init`でビルド&ネットワーク作成
1. makeコマンド`prod-start`で起動する。
1. [http://localhost:<ポート番号>](http://localhost:<ポート番号>)にアクセス

# 🚀本番環境🚀　Google Cloud, Cloud Run
## デプロイ方法
1. Google Cloudのロジェクトを新規作成する。※Google Cloudのコンソールで操作
1. Google Cloudのリソース作成 ※ローカルPCのコマンドラインから操作
    1. `terraform/init/terraform.tfvars_sample`を複製して`terraform/init/terraform.tfvars`にリネーム
    1. 各種変数を設定する 
        |変数名|説明|
        |----|----|
        |project_id|Google CloudのプロジェクトID|
        |location|サービスをデプロイするlocation|
        |operation_sa_id|サービス運用アカウントID|
        |operation_sa_display_name |サービス運用アカウント表示名|
        |build_sa_id|ビルドアカウントID|
        |build_sa_display_name|ビルドアカウント表示名|
        |artifact_registry_repository_id|Artifact RegistryのリポジトリID|
        |github_repo_owner|githubのリポジトリオーナ名|
        |github_repo_name|githubのリポジトリ名|
        |workload_identity_pool_id|Worklaod Identity Pool ID|
        |workload_identity_provider_id|Worklaod Identity Provider ID|
    1. cd コマンドで`terraform/init`に移動 
    1. デプロイする 
        ```zsh
        terraform fmt
        terraform init
        terraform validate
        terraform plan
        terraform apply
        ```
1. application用terraform.tfstate保存用バケットを作成
    1. `terraform/bucket/terraform.tfvars_sample`を複製して`terraform/bucket/terraform.tfvars`にリネーム
    1. `terraform.tfvars`のproject_idを設定する。
    1. cd コマンドで`terraform/bucket`に移動 
    1. デプロイする 
        ```zsh
        terraform fmt
        terraform init
        terraform validate
        terraform plan
        terraform apply
        ```
1. Githubにシークレットを設定
    1. Githubのリポジトリにアクセスし、Setting>Secrets and Variables>Actionsで下表の変数を設定する。※Github Actionsで利用する変数
        |変数名|説明|
        |----|----|
        |GCP_PROJECT_ID|プロジェクトID|
        |GCP_REGION|リージョン（loaction）|
        |ARTIFACT_REPO|Artifact Registoryのリポジトリ名|
        |BUILD_ACCOUNT|ビルドアカウントのID|
        |OPERATION_ACCOUNT|運用アカウントのID|
        |WORKLOAD_IDENTITY_PROVIDER|WORKLOAD_IDENTITY_PROVIDERのID|

1. Github Actionsを走らせてCloud Runにデプロイする。
    1. 適当なブランチを作成してプッシュ
    1. Githubでmainブランチへのプルリクエストを出す
    1. Actionsが実行されてArtifact RegistoryにDockerイメージがデプロイされ、terraform planが終わるまで待機
    1. terraform planの結果を見てデプロイして問題ないか確認
    1. プルリクエストをマージ
    1. Actionsが実行されてCloud Runにデプロイされる

## 💀Google Cloudリソース削除方法💀
### 手順1. Cloud Runを削除する　※Github Actionsから操作
1. GithubのActionsタブにある`terraform-destroy`workflowを押してRun workflowを実行
1. Actionsが実行されてCloud Runリソースが削除されたことを確認
### 手順2. バケットを削除 ※ローカルPCのターミナルで操作
1. cdコマンドで`terraform/init`に移動
1. `terraform plan --lock=false -destroy`を実行してapply内容を確認
1. `terraform apply -destroy`を実行して削除されたことを確認
### 手順3. バケットを削除 ※Google Cloudのコンソールから操作
1. Google Cloudのコンソールにアクセス
1. Cloud Storageのバケットタブに移動
1. 対象のバケットを選択して削除
### 手順4. プロジェクトを削除 ※Google Cloudのコンソールから操作
1. Google Cloudのコンソールにアクセス
1. 右上の︙を押して「プロジェクトの設定」に移動
1. シャットダウンを押す
1. ダイアログにプロジェクトIDを入力して「このままシャットダウン」を押す